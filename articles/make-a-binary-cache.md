---
title: "バイナリキャッシュを作ろう"
emoji: "📦"
type: "tech"
topics: ["nix"]
published: true
---

:::message
この記事は [Nix Advent Calendar 2024](https://adventar.org/calendars/10086) の15日目の記事です。

@[card](https://adventar.org/calendars/10086)
:::

## バイナリキャッシュ

**バイナリキャッシュ**は Nix の目玉機能の1つです。Nix のビルドの冪等性を利用し、実際にビルドを実行することなく、登録した**バイナリキャッシュストア**からビルド成果物を直接取得することができます。

詳細は以下の資料をご覧ください。

https://speakerdeck.com/asa1984/nixru-men-paradaimubian

https://zenn.dev/asa1984/books/nix-introduction/viewer/07-binary-cache

### 公式のバイナリキャッシュ

Nixpkgs は [cache.nixos.org](cache.nixos.org) からバイナリキャッシュを提供しており、Nix はデフォルトでこのバイナリキャッシュストアを利用するように設定されています。Nixpkgs に登録されたパッケージは [Hydra](https://github.com/NixOS/hydra) という CI システムでビルドされた後、AWS S3 でホストされたバイナリキャッシュストアに保存されます。

世界最大のオープンソースパッケージリポジトリである Nixpkgs のバイナリキャッシュストアは当然ながら非常に巨大で、2022年時点でホストされているオブジェクトは**6億個超**（合計**425TiB**）に上り^[[NixOS Foundation's Financial Summary: A Transparent Look into 2022 - Meta / NixOS Foundation - NixOS Discourse](https://discourse.nixos.org/t/nixos-foundations-financial-summary-a-transparent-look-into-2022/28107/16)]、2023年の S3 の月間コストは**約14,500ドル**^[[NixOS Foundation Financial Summary : A Transparent Look into 2023 - Meta / NixOS Foundation - NixOS Discourse](https://discourse.nixos.org/t/nixos-foundation-financial-summary-a-transparent-look-into-2023/43640)]だったそうです。ヤバ…

https://cache.nixos.org/

### Cachix

[Cachix](https://www.cachix.org/) はバイナリキャッシュのホスティングサービスです。GitHub Actions や CircleCI など各種 CI システムをサポートしており、簡単にバイナリキャッシュを作ることができます。Nixpkgs 以外でバイナリキャッシュを提供している開発者はほとんどの場合 Cachix を利用しています。

https://www.cachix.org/

## バイナリキャッシュを作る

個人でバイナリキャッシュを提供する最も簡単な方法は Chacix を利用することですが、今回は自分で S3 バイナリキャッシュストアを作ってみましょう。実はバイナリキャッシュを作るのはそんなに難しいことではなく、Nix 本体と S3 互換のオブジェクトストレージがあれば簡単に作ることができます。

今回は、GitHub Actions と Cloudflare R2 を使ってバイナリキャッシュを作成する CI を構築します。完成物は以下のリポジトリにあります。

https://github.com/asa1984/binary-cache-example

### 必要なもの

- Nix 2.24
  - [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer) によるインストールを推奨
  - 使うコマンド
    - [nix key generate-secret](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-key-generate-secret)
    - [nix key convert-secret-to-public](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-key-convert-secret-to-public)
    - [nix copy](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-copy)
    - [nix store sign](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-store-sign)
    - [nix store verify](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-store-verify)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)
  - お財布に優しいので採用
  - その他の S3 互換オブジェクトストレージを使う場合は適宜読み替えてください

### 大まかな流れ

1. パッケージをビルド
2. 秘密鍵・公開鍵を生成
3. `nix sign` でビルド成果物に署名
4. `nix copy` でストアオブジェクトをバイナリキャッシュストア（Cloudflare R2）にコピー

## パッケージの準備

ビルドするパッケージがないと話が始まりません。今回は比較的コンパイル時間の長い Rust 製のパッケージを用意してみました。諸々のファイルは[完成物のリポジトリ](https://github.com/asa1984/binary-cache-example)から引っ張ってきてください。

こんな感じのファイル構造になっています。

```:ファイル構造
./
├── flake.lock
├── flake.nix
├── hello-server/
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── default.nix
│   ├── src/
│   │   └── main.rs
│   └── .gitignore
└── .gitignore
```

### hello-server

http://localhost:3000 で `Hello, World!` を返すシンプルな Web サーバーです。[tokio](https://docs.rs/tokio/latest/tokio/) と [axum](https://docs.rs/axum/latest/axum/) を依存に持つため、若干ビルドに時間がかかります。

```toml :hellor-server/Cargo.toml
[package]
name = "hello-server"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7.9"
tokio = { version = "1.42.0", features = ["full"] }
```

```rust :hello-server/src/main.rs
use axum::{routing::get, Router};

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(|| async { "Hello, World!" }));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    println!("Listen on http://localhost:3000");
    axum::serve(listener, app).await.unwrap();
}
```

### Nix 式

hello-server をビルドする Nix 式が以下です。[callPackage パターン](https://zenn.dev/asa1984/books/nix-hands-on/viewer/ch04-01-hello#5.1.-%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E5%88%86%E5%89%B2)に従って書いています。

```nix :hello-server/default.nix
{ rustPlatform, ... }:
rustPlatform.buildRustPackage {
  name = "hello-server";
  src = ./.;
  cargoLock = {
    lockFile = ./Cargo.lock;
  };
}
```

そしてこんな感じの `flake.nix` を用意します。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs:
    let
      allSystems = [
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-linux" # 64-bit x86 Linux
        "aarch64-darwin" # 64-bit ARM macOS
        "x86_64-darwin" # 64-bit x86 macOS
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs allSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        rec {
          default = hello-server;
          hello-server = pkgs.callPackage ./hello-server { };
        }
      );
    };
}
```

`nix run` でビルドできたら OK です。`git add` を忘れないように！^[Git リポジトリ内に作成された Flake は Git を介してファイルを追跡するため、ステージされていないファイルをビルド環境に持ち込めない。詳細は「[§3. Flakeを作る｜Nix入門: ハンズオン編](https://zenn.dev/asa1984/books/nix-hands-on/viewer/ch01-03-flakes)」参照。]

## CI を構築する

### 1. Cloudflare R2 のバケットの作成・トークンの発行

Cloudflare R2 のバケットを作成します。作成後、API トークンを発行して次の情報を控えておいてください。

- API エンドポイント
- ID
- トークン

ここら辺は公式ドキュメントを読みながらやってください。

https://developers.cloudflare.com/r2/

### 2. 署名用の鍵の作成

バイナリキャッシュストアにストアオブジェクトを保存するには、`nix store sign` を用いて対象のストアオブジェクトに署名する必要があります。署名用の鍵を作成しましょう。

まずは `nix key generate-secret` を使って秘密鍵を作ります。言うまでもないですが漏洩しないよう細心の注意を払って管理してください。
鍵の名前は慣例的に `cache.nixos.org-1` や `nix-community.cachix.org-1` のような `<バケットのドメイン>-<番号>` という名前をつけることが多いです。後ろの番号は万が一鍵を作り直すことになった際にインクリメントします。

```bash :秘密鍵の生成
nix key generate-secret --key-name <鍵の名前> > secret.key
```

生成した秘密鍵から対応する公開鍵を生成します。

```bash :公開鍵の生成
nix key convert-secret-to-public < ./secret.key > ./public.key
```

ユーザーはこの公開鍵を Nix に登録し、バイナリキャッシュストアからダウンロードしたオブジェクトが正当なものかどうか検証します。どうやって公開鍵を Nix に登録するかは次で説明します。

### 3. flake.nix に nixConfig を追加

`/etc/nix/nix.conf` または `~/.config/nix/nix.conf` には以下のような設定が記述されています。

```bash :/etc/nix/nix.conf
# 省略
substituters = https://cache.nixos.org/
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
# 省略
```

`substituters` はバイナリキャッシュストアのエンドポイント、`trusted-public-keys` は対応する公開鍵です。Nix はパッケージをビルドする際に `substituters` に登録された Nix ストアに照会をかけ、キャッシュが見つかった場合はそれをダウンロードします。

ユーザーは以下のように設定することで利用するバイナリキャッシュストアを追加できます。

```bash :nix.conf
substituters = <バイナリキャッシュストアA> <バイナリキャッシュストアB>
trusted-public-keys = <バイナリキャッシュストアAの公開鍵> <バイナリキャッシュストアBの公開鍵>
```

---

前述の方法でバイナリキャッシュストアを登録できますが、いちいち手動で設定を追加するのは面倒ですよね。実は `flake.nix` で `nix.conf` と同様の設定を行うことができます。

通常、Nix は `/etc/nix/nix.conf` または `~/.config/nix/nix.conf` に記述された設定を読み込みますが、`flake.nix` に `nixConfig` という attribute を設定することで Flake 専用の設定を記述することができます。

以下のような設定を追加してください。

```diff nix :flake.nix
{
+ nixConfig = {
+   extra-substituters = [ "<バケットのエンドポイント>" ];
+   extra-trusted-public-keys = [ "<署名の公開鍵>" ];
+ };

  # 省略
}
```

これでこの `flake.nix` を評価した時に自動的にバイナリキャッシュを利用するようになります。

:::message

**デフォルトの Nix は `flake.nix` に記述された設定を読み込みません**。

以下の方法で設定を利用できます。

- `nix run` や `nix build` などのコマンドのオプションに `--accept-flake-config` というオプションをつける
- `/etc/nix/nix.conf` または `~/.config/nix/nix.conf` に `accept-flake-config = true` という行を追加

:::

### 4. ワークフローの作成

先にワークフローの全体を載せておきます。

```yaml :.github/workflow/setup-binary-cache.yaml
env:
  AWS_PROFILE_NAME: builder
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  BINARY_CACHE_SECRET_KEY: ${{ secrets.BINARY_CACHE_SECRET_KEY }}
  S3_API_ENDPOINT: ${{ secrets.S3_API_ENDPOINT }}

jobs:
  copy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main

      - name: Build package
        run: nix build . --accept-flake-config

      - name: Sign package with secret key
        run: |
          echo $BINARY_CACHE_SECRET_KEY > ./secret.key
          nix store sign --recursive --key-file ./secret.key

      - name: Configure AWS credentials
        run: |
          nix shell nixpkgs#awscli --command aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $AWS_PROFILE_NAME
          nix shell nixpkgs#awscli --command aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $AWS_PROFILE_NAME

      - name: Copy package
        run: nix copy --to s3://nix-cache\?profile=$AWS_PROFILE_NAME\&endpoint=$S3_API_ENDPOINT\&compression=zstd
```

#### 環境変数

リポジトリの設定からシークレットを登録します。
いくつかの環境変数の名前に `AWS` という接頭辞がついていますが気にしないでください。 ~~筆者が面倒がって Cloudflare R2 用に書き直さなかっただけです。~~

| 環境変数名                 | 中身                                |
| -------------------------- | ----------------------------------- |
| `$AWS_PROFILE_NAME`        | 適当な名前                          |
| `$S3_API_ENDPOINT`         | Cloudflare R2 の API エンドポイント |
| `$AWS_ACCESS_KEY_ID`       | Cloudflare R2 のアクセス ID         |
| `$AWS_SECRET_ACCESS_KEY`   | Cloudflare R2 の API トークン       |
| `$BINARY_CACHE_SECRET_KEY` | 生成した署名用の秘密鍵              |

#### Nix のインストール

DeterminateSystems が提供している action を利用します。

```yaml
- uses: DeterminateSystems/nix-installer-action@main
```

https://github.com/DeterminateSystems/nix-installer-action

#### ビルド

`--accept-flake-config` オプションをつけると `flake.nix` に設定された `nixConfig` を利用できるようになります。デフォルトでこの挙動をしてほしい場合は、`/etc/nix/nix.conf` または `~/.config/nix/nix.conf` に `accept-flake-config = true` という行を追加してください。

```yaml
- name: Build package
  run: nix build . --accept-flake-config
```

後でバイナリキャッシュが効いているかどうか検証するためにつけておきます。

#### ストアオブジェクトに署名

`nix sign` でビルド成果物に署名します。

```yaml
- name: Sign package with secret key
  run: |
    echo $BINARY_CACHE_SECRET_KEY > ./secret.key
    nix store sign --recursive --key-file ./secret.key
```

`--recursive` オプションをつけることで、[clousures](https://zenn.dev/asa1984/books/nix-introduction/viewer/08-derivation#closures)（全ての実行時依存のストアオブジェクト）にも署名します。後で使う `nix copy` は、対象のストアオブジェクトをコピーする際にその実行時依存も全てコピーする^[故に、`nix copy` を使ってマシン A からマシン B のローカルストアにストアオブジェクトをコピーし、そのままマシン B で実行するという芸当ができる。]ので、このオプションが必要になります。

#### バケットアクセス用の credentials の設定

Nix は基本的に AWS S3 を利用することを想定しているので、`~/.aws/credentials` からバケットへアクセスするためのシークレット情報を読み取ります。ただのテキストファイルなので `echo` などを使って書いてもいいですが、せっかく Nix を使っているので、`nix shell` で `awscli` をインストールして設定します。

```yaml
- name: Configure AWS credentials
  run: |
    nix shell nixpkgs#awscli --command aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $AWS_PROFILE_NAME
    nix shell nixpkgs#awscli --command aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $AWS_PROFILE_NAME
```

#### バイナリキャッシュストアへコピー

最後にビルド成果物をバイナリキャッシュストアにコピーします。

```yaml
- name: Copy package
  run: nix copy --to s3://nix-cache\?profile=$AWS_PROFILE_NAME\&endpoint=$S3_API_ENDPOINT\&compression=zstd
```

`nix copy` では以下の特殊な形式の URL にクエリパラメーターを介していくつかのオプションを設定できます。

```bash
s3://nix-cache?profile=$AWS_PROFILE_NAME&endpoint=$S3_API_ENDPOINT&compression=zstd
```

- **profile**
  - 利用する credentials のプロファイル。今回は `awscli` で設定したもの。
- **endpoint**
  - コピー先のバケットのエンドポイント
- **compression**
  - バイナリキャッシュの圧縮方式
  - `xz`, `bzip2`, `gzip`, `zstd`, `none` を設定可能
    - 今回はより高速で圧縮できる `zstd` を採用

詳細なオプションは公式リファレンスを読んでください。

https://nix.dev/manual/nix/2.24/store/types/s3-binary-cache-store.html?highlight=compression#settings

## 結果

GitHub Actions のログを見てバイナリキャッシュの効果を検証してみましょう。以下、私が作成したリポジトリの GitHub Actions のログを載せます。

### 1回目のビルド

バイナリキャッシュが存在しない初回の実行時間は次のようになりました。

- 全体: 2分7秒
- ビルド: 1分17秒

https://github.com/asa1984/binary-cache-example/actions/runs/12337582115/attempts/1

### 2回目のビルド

ワークフローを手動で再実行してみます。`nix build` に `--accept-flake-config` オプションをつけているので、前回作成したバイナリキャッシュを利用してくれるはずです。

---

結果、ビルド時間が大幅に短縮されました。

- 全体: 1分8秒
- ビルド: **20秒**

https://github.com/asa1984/binary-cache-example/actions/runs/12337582115/attempts/3

ビルドログの最後の1行が `building` から `copying` に変化しています。

```:1回目のビルドログ
(中略)
building '/nix/store/d0dms08lf7l7y3c9wplv9dr2ch6ad1q3-hello-server.drv'...
```

```:2回目のビルドログ
(中略)
copying path '/nix/store/mnx7gwcszr2bbmi7nxhlppb3s15dibsa-hello-server' from 'https://cache.asa1984.dev'...
```

## まとめ

意外と簡単にバイナリキャッシュを作れることが分かったのではないでしょうか。速さこそ正義なのでどこでも活躍できると思います。個人利用もいいですが、大規模なデプロイにバイナリキャッシュを利用して展開時間を高速化できたらかなりアツいですね。インフラ周りをやっている人に使ってみてほしいです。

---

いいことづくめなバイナリキャッシュですが、いくつか注意点もあります。

1つ目は、**バイナリキャッシュのサイズ**です。まず前提として、全ての実行時依存を含めたストアオブジェクトが保存されるので、そこそこサイズが膨らみます。その上でソースコードの変更やコンパイラ・共有ライブラリの更新などを行うとストアパスが変化し、新しいバイナリキャッシュが保存されることになるので、無思慮にバイナリキャッシュを作成していると一気にバケットのサイズが増加します。

バケットのサイズの増加が気になる場合は、古いオブジェクトを削除するようなポリシーを作成するといいでしょう。

2つ目は、**ビルド環境のプラットフォーム**です。今回はワークフローの実行環境に `ubuntu-latest` (x86_64-linux) を使っているので、ARM CPU や macOS では私たちのバイナリキャッシュを利用できません。これは Nix のバイナリキャッシュに限った話ではありませんが、複数のプラットフォームに対応したい場合は、その分適切なビルド環境を用意しましょう。

今回、GitHub Actions の `macos-latest` runner を利用して aarch64-darwin にもバイナリキャッシュを提供することも考えましたが、`macos-latest` 環境が少ないためか、ワークフロー実行までの待機時間が長すぎて断念しました。

以上を踏まえて面倒だな〜と思った人は Cachix の利用を検討するといいかもしれません。

## 余談: バイナリキャッシュ関連の面白いプロジェクト

### magic-nix-cache

[magic-nix-cache](https://github.com/DeterminateSystems/magic-nix-cache) は、GitHub Actions 内でバイナリキャッシュを使えるようにする action です。GitHub Actions の cache API を利用して runner のローカルストアをキャッシュし、localhost でバイナリキャッシュサーバーを起動します。

https://github.com/DeterminateSystems/magic-nix-cache

外部公開はできないので GitHub Actions 内専用になります。筆者はこの action を利用して、CI 用の devShell の構築時間を短縮しています。

https://github.com/asa1984/asa1984.dev/blob/main/.github/actions/setup/action.yaml

### attic

[attic](https://github.com/zhaofengli/attic) は、Rust で実装されたバイナリキャッシュサーバーです。[FastCDC](https://docs.rs/fastcdc/latest/fastcdc/) を利用したチャンク分割やプライベートなバイナリキャッシュの作成など、機能が豊富です。

https://github.com/zhaofengli/attic

作者の [zhaofengli](https://github.com/zhaofengli) 氏は、attic のホストには [fly.io](https://fly.io/)、DB には [Neon](https://neon.tech/)、オブジェクトストレージには Cloudflare R2 を利用しているそうです。

https://discourse.nixos.org/t/introducing-attic-a-self-hostable-nix-binary-cache-server/24343

## 余談: Nix の論文

Nix の開発者である [Eelco Dolstra](https://github.com/edolstra) 氏の論文「[Nix: A Safe and Policy-Free System for Software Deployment](https://edolstra.github.io/pubs/nspfssd-lisa2004-final.pdf)」「[The Purely Functional Software Deployment Model](https://edolstra.github.io/pubs/phd-thesis.pdf)」では、バイナリキャッシュが重要なコンセプトとして述べられています。

そもそも Nix は「正しいデプロイ」の実現を目的として開発されました。ここでの「デプロイ」はソフトウェアを対象のマシンに配置して利用可能にすることを意味しており、要はソフトウェアのインストールのことを指しています。
その上で重要な二項対立として、**ソースコードデプロイ**と**バイナリデプロイ**が挙げられています。ソースコードデプロイはソースコードを対象のマシンに送信してデプロイ先でビルドすること、バイナリデプロイは送信元で事前にビルドを実行し、ビルド成果物を対象のマシンに送信することを指しています。

バイナリデプロイはデプロイの最適化、つまりデプロイ時間の短縮を目的として行われます。ただし、トレードオフとして整合性を損なう可能性があります。バイナリインストールしたら上手くいかなかったので、代わりに手元でビルドしてインストールしたという経験がある人なら身に染みていると思います。

Nix が画期的だったのは、[純粋関数的なビルドシステム](https://zenn.dev/asa1984/books/nix-introduction/viewer/05-pure-functional-build)がソースコードデプロイとバイナリデプロイを等価にした点です。ビルドが決定論的である以上、一からビルドしてもバイナリキャッシュから直接ビルド成果物をダウンロードしても結果が変わらなくなったのです^[一応補足しておくと Nix はビットレベルでの同一性を保証するわけではないため、「実用的なレベルで」という注釈が入る。]。

以上を踏まえると、Nix が安全性・完全性を目指した結果、副産物としてバイナリキャッシュが実現されたわけではなく、最初から前述の課題意識を持って厳密性・完全性を要求するビルドシステムが発明されていることが分かります。
