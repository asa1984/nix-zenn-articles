---
title: "NixOSで最強のLinuxデスクトップを作ろう"
emoji: "❄"
type: "tech"
topics: ["nixos", "nix", "linux", "入門", "dotfiles"]
published: true
---

Web・クロスプラットフォームアプリケーションの発達、[Proton](https://partner.steamgames.com/doc/steamdeck/proton?l=japanese)によるWindows向けゲームのLinux対応など、現在のLinuxデスクトップは機能面においてWindowsやMacと遜色ない水準に達しています。

しかし、その発展とは裏腹に未だシェアは非常に少なく、Linuxデスクトップに憧れはあるけど実際に使うのはあまり……という人が多数派でしょう。その理由はおおよそ以下の3つに集約されると思います。

1. 環境構築のために煩雑な手順を踏まなければならず辛い
2. どこにどんな設定がされているのか分からない
3. うっかり環境を破壊してしまいそうで怖い

実は、上記の課題を上手くクリアできる夢のようなLinuxディストリビューションが存在します。
その名は……

![NixOS](https://upload.wikimedia.org/wikipedia/commons/c/c4/NixOS_logo.svg)
_ロゴかっこいい_

今回はNixOSを使ってぼくがかんがえたさいきょうのLinuxデスクトップ環境を作っていきましょう。

## NixOSとは？

> NixOS: A Purely Functional Linux Distribution

NixOSは、純粋関数型パッケージマネージャである**Nix**をベースにしたLinuxディストリビューションです。NixOSではなんと環境構築を完全に宣言的に行うことができます。つまり、望む環境の状態をコードで記述してNixOSに処理させることで、自動的にパッケージのインストールやシステムの設定などを行ってくれるのです。

「え、自動インストールに自動設定？依存関係とか大丈夫？🤔」
と疑問に思った方へ、問題ありません。NixOSの環境構築はNixによるビルドという形で行われます。Nixは強力なビルドシステムを持っており、非常に高い再現性を誇ります^[NixOSのミニマルISOのビルド再現性は100%に達している。]。NixOSでは依存関係に関する問題がほとんど発生しません。

実際に私が過去に行った環境再構築RTAの記録が以下です^[~~当時、デスクトップ環境として[Hyprland](https://hyprland.org)を利用していましたが、現在はXorg + XMonadを使っています。~~ 2024年2月にXMonadからHyprlandに再移行しました。]。

@[tweet](https://twitter.com/asa_high_ost/status/1626605553123467264?s=20)

約20分となっていますが、そのほとんどはダウンロード・インストール処理の時間で、実際にコマンド操作を行った時間は5分もありません。

興味が湧いてきませんか？
NixOSを知るにはまずパッケージマネージャNixを知る必要があります。詳しく見ていきましょう。

## Nix

> Nix is a powerful package manager for Linux and other Unix systems that makes package management reliable and reproducible.

『_Nix_』はラテン語で『_雪の結晶_』を意味します。パッケージマネージャとしては以下のような特徴を持ちます。

- 高い再現性
- パッケージ数8万超の公式パッケージリポジトリ[nixpkgs](https://github.com/NixOS/nixpkgs)
  - 安定版ブランチ・ローリングリリースブランチが存在
- UNIX系システム（Linux全般、macOS）で利用可能

Nix自体はNixOSとは独立した汎用的なツールです。

Nixは単なるパッケージマネージャではなく、独自のビルドシステムやProfilesと呼ばれる環境構築機能などが合わさった複合的なソフトウェアです。NixOSの機能は、従来Nixが備える機能を拡張するような形で実現されています。本文では以下の3つについて重点的に説明します。

1. DerivationとNix store
2. Nix言語
3. Profiles
4. Flakes

順に見ていきましょう。

### DerivationとNix store

Nixのビルドシステムは、パッケージを関数型言語の値のように扱います。つまり、副作用のない参照透過な関数から生成され、生成物はイミュータブルに扱われることを意味します。

Nixでパッケージをビルドすると、`/nix/store`ディレクトリ下に、以下のようなハッシュ値を名前に含んだサブディレクトリが作成され、その下にビルド成果物が格納されます。

```shell:Gitバージョン2.41.0
                                          Package
                                            ┌┴┐
/nix/store/y0gvg44jdsbn8hnnr27ixjf102nk7a9x-git-2.41.0/
           └──────────────┬───────────────┘     └──┬──┘
                        Hash                    Version
```

Nixは、パッケージをビルドするために**Derivation**と呼ばれるものを使用します。
Derivationとは、簡単に言うとパッケージの非常に厳密なレシピです。Derivationはパッケージを同定する全ての要素（依存関係、ソースコード、ビルドスクリプト、環境変数、シェル、システムアーキテクチャなど）を**入力**として扱います。この入力をもとハッシュ計算を行い、パッケージの識別子としてディレクトリ名に付加しているのです。1bitでも入力が異なれば全く異なったハッシュ値になるため、パッケージは厳密に区別されます。

例として、`Hello, World!`をコンソールに表示するRustのプログラムのDerivationを記載しておきます。長いので折りたたんでいます。

:::details hello-rsのDerivation

実際のDerivationは`.drv`ファイルとしてNix storeに格納されており、以下は`nix derivation show`コマンドでJSON形式にPretty-printしたものです。

- `builder`: ビルドを実行するシェル
- `env`: 環境変数
- `inputDrvs`: 依存関係(Derivation)
- `inputsSrcs`: ソース
- `outputs`: ビルド成果物を配置するディレクトリ
- `system`: システムアーキテクチャ

依存関係として`inputDrvs`に`/nix/store/9pvlx7xb9h7xbvmfmkvp54i8sa34pa6f-rustc-1.70.0.drv`（RustコンパイラのDerivation）などが指定されています。

```json
{
  "/nix/store/1b6b4lh490crvsdypk1nnv1qa6w3hzm5-hello-rs.drv": {
    "args": [
      "-e",
      "/nix/store/6xg259477c90a229xwmb53pdfkn6ig3g-default-builder.sh"
    ],
    "builder": "/nix/store/51sszqz1d9kpx480scb1vllc00kxlx79-bash-5.2-p15/bin/bash",
    "env": {
      "PKG_CONFIG_ALLOW_CROSS": "0",
      "__structuredAttrs": "",
      "buildInputs": "",
      "builder": "/nix/store/51sszqz1d9kpx480scb1vllc00kxlx79-bash-5.2-p15/bin/bash",
      "cargoBuildFeatures": "",
      "cargoBuildNoDefaultFeatures": "",
      "cargoBuildType": "release",
      "cargoCheckFeatures": "",
      "cargoCheckNoDefaultFeatures": "",
      "cargoCheckType": "release",
      "cargoDeps": "/nix/store/w7grdh3xyk94ahc4q2jh0rjlgcpsj981-cargo-vendor-dir",
      "cmakeFlags": "",
      "configureFlags": "",
      "configurePhase": "runHook preConfigure\nrunHook postConfigure\n",
      "depsBuildBuild": "",
      "depsBuildBuildPropagated": "",
      "depsBuildTarget": "",
      "depsBuildTargetPropagated": "",
      "depsHostHost": "",
      "depsHostHostPropagated": "",
      "depsTargetTarget": "",
      "depsTargetTargetPropagated": "",
      "doCheck": "1",
      "doInstallCheck": "",
      "mesonFlags": "",
      "name": "hello-rs",
      "nativeBuildInputs": "/nix/store/mkplk6shr1lvy3w0n2hpmkvv4rvkqa70-auditable-cargo-1.70.0 /nix/store/xv57wrly4ixy2d7lzajixfhzhyx54cbx-cargo-build-hook.sh /nix/store/9cd8rx3xfbqzihqwzfncbsn3bzqzdz7r-cargo-check-hook.sh /nix/store/1nq92m0mn1k9a8lbx6jcj00dbdw48j01-cargo-install-hook.sh /nix/store/3fk9yaj769bn5g6557xj512m8qix0h14-cargo-setup-hook.sh /nix/store/rdxwgdyfj0sa7sz6p4c6fp3irlhnwixn-rustc-1.70.0",
      "out": "/nix/store/hgaxjl9qvcla891yg6ipzphnl6sgj0hw-hello-rs",
      "outputs": "out",
      "patchRegistryDeps": "/nix/store/nk6b2ckznjic5wj8ddw0wgdrn4mbz3lg-patch-registry-deps",
      "patches": "",
      "postUnpack": "eval \"$cargoDepsHook\"\n\nexport RUST_LOG=\n",
      "propagatedBuildInputs": "",
      "propagatedNativeBuildInputs": "",
      "src": "/nix/store/xzl1xr811d6s1n4dgnk0xw8vrvsm6j0b-12v8dj6mcqpmrlsskcfd283sgi99zqpf-source",
      "stdenv": "/nix/store/blpvf60m29q02c0lc5fyhim30ma4y1vv-stdenv-linux",
      "strictDeps": "1",
      "system": "x86_64-linux"
    },
    "inputDrvs": {
      "/nix/store/29yjg4ilzpdwh4m45lv6c4m5v2lppsn2-bash-5.2-p15.drv": ["out"],
      "/nix/store/5yzp580n67ikaz10fylp82x97z8g8rni-cargo-check-hook.sh.drv": [
        "out"
      ],
      "/nix/store/9pvlx7xb9h7xbvmfmkvp54i8sa34pa6f-rustc-1.70.0.drv": ["out"],
      "/nix/store/fgc4aafdrqczbdga0fp5kds7r01ka28x-stdenv-linux.drv": ["out"],
      "/nix/store/gq69b4678qsswsqhfs3yzxla1qfxp1m9-cargo-setup-hook.sh.drv": [
        "out"
      ],
      "/nix/store/l8h3lmhbxvhndjb88qf5b84wk01f2xdj-cargo-vendor-dir.drv": [
        "out"
      ],
      "/nix/store/vmkhqrbba05vvz8gr5sc93yggkhrd0fk-cargo-install-hook.sh.drv": [
        "out"
      ],
      "/nix/store/zpi7glnyk7dwcbjwrnf970xh5466lwi8-cargo-build-hook.sh.drv": [
        "out"
      ],
      "/nix/store/zzax3dvxcll8aq0qw23phjxlim727hhi-auditable-cargo-1.70.0.drv": [
        "out"
      ]
    },
    "inputSrcs": [
      "/nix/store/6xg259477c90a229xwmb53pdfkn6ig3g-default-builder.sh",
      "/nix/store/nk6b2ckznjic5wj8ddw0wgdrn4mbz3lg-patch-registry-deps",
      "/nix/store/xzl1xr811d6s1n4dgnk0xw8vrvsm6j0b-12v8dj6mcqpmrlsskcfd283sgi99zqpf-source"
    ],
    "name": "hello-rs",
    "outputs": {
      "out": {
        "path": "/nix/store/hgaxjl9qvcla891yg6ipzphnl6sgj0hw-hello-rs"
      }
    },
    "system": "x86_64-linux"
  }
}
```

:::

#### 複数バージョンの共存

所謂Dependency Hellとは、複数のソフトウェアがそれぞれ同じパッケージの異なるバージョンに依存することで発生します。依存先のバージョン間で破壊的な変更が入ると、依存していたソフトウェアのどちらかが機能しなくなる可能性があります。

Nixで異なるバージョンのパッケージをインストールするとDerivationの入力が変わるため、必然的に出力されるハッシュ値が変わり、別々のディレクトリに配置されます。

以下は私の環境のNix store内にあるopensslの一部です。複数のバージョンが共存していることがわかります。
バージョンが被っているものがありますが、Nixでは完全に入力が一致しない限りそのパッケージは別物扱いとなります。Nixにおいてパッケージのバージョンは人間向けのセマンティクスでしかありません。

```shell :openssl
h7zllwcidvkg8i5v6hkf49n3sd5lq290-openssl-3.0.5/
hggh523whplc4bk681c95r52bsjc2wb5-openssl-3.0.9/
ii5lq0igwk9xpq16s98yqswsgr1dbfi2-openssl-3.0.9/
ijk9j536zs30kha06rr966gplwxd7fbg-openssl-3.0.8/
ip9kk8kla5bff32mqjmwdn29sbhyd19c-openssl-3.0.8/
iw4cmla0978f1lgn23lmqmra3lrfwd4a-openssl-3.0.9/
```

#### 暗黙的依存の排除

Derivationにおいて重要なのが、**入力以外の要素はビルドに影響を与えることができない**ということです。NixはDerivationで指定されたシェルに、同じく指定された依存関係や環境変数を導入した**純粋な**環境を立ち上げます。そこでビルドスクリプトを実行することでビルドが完了します。

もし、とあるパッケージが開発環境にグローバルにインストールされているパッケージX依存していて、開発者が依存関係にパッケージXを指定し忘れたとしても、Nixの純粋なビルド環境にはパッケージXが導入されないためビルドが失敗します。つまり、全ての依存関係が陽の下に扱われ、暗黙的依存が排除されます。

#### バイナリキャッシュ

Nixはパッケージインストール時に必ずDerivationを評価するため、本来なら常にローカルでビルドが走って膨大な時間がかかるはずですが、実際のインストールは爆速です。
実はNixの公式パッケージリポジトリ[nixpkgs](https://github.com/NixOS/nixpkgs)では、[Hydra](https://github.com/NixOS/hydra)というCIシステムで常時パッケージのビルド結果をキャッシュしています。

1. パッケージリポジトリからNix式を取得（後述）
2. Derivationを生成
3. Derivationのハッシュ値をHydraのキャッシュに照会
4. キャッシュが存在する場合、ビルド済みバイナリを直接ダウンロード

Nixのビルドシステムによって、ハッシュが同一であればビルド結果も同一になることが保証されているので、再現性を損なわずインストールを高速化できます。

### Nix言語

Derivationは直接人が読み書きするものではなく、NixのDSLである**Nix言語**によって記述された**Nix式**を用いて生成します。以下は、前述の`hello-rs`パッケージをビルドするためのNix式です。

```nix :default.nix
{ pkgs ? import <nixpkgs> { }, ... }: {
  hello-rs = pkgs.rustPlatform.buildRustPackage {
    name = "hello-rs";
    src = ./.;
    cargoLock = { lockFile = ./Cargo.lock; };
  };
}
```

Nix言語では、1つのファイルが1つの関数式となっています。

```
{引数}: 出力
```

`pkgs ? import <nixpkgs> { }`は、`pkgs`が引数として与えられない時（なぜこんな回りくどいことをするのかは後述）、nixpkgsをインポートします。`<nixpkgs>`はローカルにダウンロードされたnixpkgsへのファイルパスを示します。nixpkgsの実体はNix式のセットです。

今回の出力は`key = vlue;`形式で列挙されており、このデータ構造を**Attribute Set**と呼びます。上記の出力のAttribute Setは、`hello-rs`というkeyに、パッケージのDerivationを入れています。
Derivationを作るために`pkgs.rustPlatform.buildRustPackage`というユーティリティ関数を使っています。このように`pkgs`（=nixpkgs）はNix言語のライブラリでもあります。

あくまでNix式は単なるデータを出力しているに過ぎないので、これ単体では何もできません。コマンドがNix式を評価して初めてパッケージがビルドされます。

```shell :ビルドコマンド
nix-build
```

実際にビルドしてみると`result`というシンボリックリンクが実行したディレクトリ配置されます。リンク先はNix store内のビルド成果物の実体です。

```shell
$ readlink ./result
/nix/store/hgaxjl9qvcla891yg6ipzphnl6sgj0hw-hello-rs
```

#### nix-shell

Nixでは、Derivationを用いて、パッケージ以外にも様々なものをビルドすることができます。

以下のNix式を用意します。先程のNix式からhello-rsのDerivationをインポートし、`let in`構文で`hello-rs`として宣言しています。

```nix :shell.nix
{ pkgs ? import <nixpkgs> { }, ... }:
let
  hello-rs = (import ./default.nix pkgs).hello-rs;
in
pkgs.mkShell {
  buildInputs = [
    hello-rs
  ];
}
```

`nix-shell`コマンドで`shell.nix`を評価します。

```
bash-5.1# nix-shell
# パッケージのビルドが走る

[nix-shell:~/hello-rs]# hello-rs
Hello, world!

[nix-shell:~/hello-rs]# exit
exit

bash-5.1# hello
bash: hello: command not found
```

一時的にパッケージのパスが通されたシェル環境が立ち上がります。開発環境を用意するのに非常に便利な機能です。

### Profiles

実際にパッケージを使用できるようにするためには、コマンドのPATHを通したり、適切な場所にファイルを配置したりといったインストール処理が必要になります。Nixはパッケージの実体ファイルを`/nix/store`で一元管理し、必要な位置にシンボリックリンクを配置することでこれを実現しています^[[pnpm](https://pnpm.io/ja/)みたいですね。念の為言っておくとNixの方が古いです。]。

:::message
以降のシェルコマンドの実行結果は、公式のDockerイメージ[nixos/nix](https://hub.docker.com/r/nixos/nix)上で実行したものです。このDockerイメージはNixOSではなく、あくまでNixが導入された環境です。
:::

Nixは`/usr/bin`などのグローバルなディレクトリを使わず、`~/.nix-profile`下にシンボリックリンクを配置します。中身は以下のようになっていて、よくみるディレクトリ構造になっています。

```shell
$ ls ~/.nix-profile
bin  etc  lib  libexec  manifest.nix  sbin  share
```

NixでインストールしたcurlのPATHをみてみると以下のようになっています。`~/.nix-pforile/bin`内のシンボリックリンクにPATHが通されています。

```shell
$ echo $PATH
/root/.nix-profile/bin:(中略)

$ which curl
/root/.nix-profile/bin/curl

$ readlink $(which curl)
/nix/store/52fbv6j49khca4cfvwm35fqd984w2520-curl-7.86.0-bin/bin/curl
```

また、`.nix-profile`自体もNixによってビルドされており、シンボリックリンクになっています。

```shell
$ readlink ~/.nix-profile
/nix/var/nix/profiles/default
```

`.nix-profile`の実体ファイルが配置されている場所には複数のProfileが配置されています。しかも全てシンボリックリンクになっており、`.nix-profile`の中身と同じ構造をしています。

```
$ readlink ~/.nix-profile
/nix/var/nix/profiles/default

$ ls -l /nix/var/nix/profiles/
default -> default-4-link
default-1-link -> /nix/store/d8c5588zaaylx31hax59j4pjj9pcik88-user-environment
default-2-link -> /nix/store/15nriql44lwh2dw9q5x8p22kaa882maz-profile
default-3-link -> /nix/store/hf0yc0syc71y9yryn9qqyhsq4i7kj0hi-profile
default-4-link -> /nix/store/15nriql44lwh2dw9q5x8p22kaa882maz-profile
per-user
```

Profilesの仕組みは以下のようになっています。Nixはパッケージに対する操作（インストール、アンインストール、アップデート）が実行される度に新しいProfileをビルドし、`default`にリンクします。

![画像](https://nixos.org/manual/nix/stable/figures/user-environments.png)
_引用: [Profiles - Nix Reference Manual](https://nixos.org/manual/nix/stable/package-management/profiles.html)_

#### グローバルを汚染しない

Nixで管理されるものは全て閉じた環境に隔離されるため、もし他のパッケージマネージャが存在したとしても既存の環境と競合しません。NixOS以外のシステムでも安全に導入することができます。

#### Profileのロールバック

Profileの操作は常に非破壊的なので、過去のProfileは上書きされずにそのまま残ります。これを利用して`default`のリンク先を任意の世代のProfileに切り替えることで、環境をロールバックすることができます。

#### Profilesにおけるインストール/アンインストール

Nixにおいて一般的な意味でのアンインストールコマンドは**存在しません**。実際それに相当するコマンドを実行すると、該当するシンボリックリンクが除かれたProfileが新しくビルドされるだけで、実体ファイルはNix storeに残り続けます。
そのままではストレージが枯渇してしまうので、Nixにはガベージコレクション機能が搭載されています。期間を設定すると自動的にProfileへリンクされていないNix store内のパッケージを削除します。コマンドでGCを手動実行することも可能です。

## Flakes

実は、Nix言語によるパッケージビルドはいくつかの問題を抱えています。

1. ローカルのパッケージセットに依存している
2. インターフェースが非統一

パッケージセットの種類・バージョンはマシンごとに異なる可能性があります。先程例に挙げたNix式では`pkgs`に`import <nixpkgs> {}`でローカルのパッケージセットをインポートしており、実行環境ごとにビルド結果が変わってしまいます。
また、`nix-build`や`nix-shell`など機能ごとにコマンドが分かれていますが、Nix言語のセマンティクスには反映されません。これでは用途ごとに複数のエントリポイントを持つことになり扱いにくいです。

これらを解決するのがNixのプロジェクト管理機能であるFlakesです。FlakesはGitとの併用を前提としており、Gitリポジトリのルートに`flake.nix`というファイルを配置することで利用できます。

:::details Nix channels
Flakesに対して、古いNixのパッケージリポジトリ管理機構は**Channels**と呼ばれます。Channelsは、パッケージリポジトリを購読し、ローカルのパッケージセットを自動更新します。コマンドからnixpkgs以外のパッケージリポジトリを登録・購読することも可能です。再現性を追求するために現在ではFlakesが主流です。
:::

### flake.nix

`flake.nix`の構造は単純で、依存する外部のFlake（`flake.nix`で管理されているGitリポジトリ）を指定する`inputs`と任意のNix式を定義できる`outputs`しかありません。

```nix :flake.nix
{
  inputs = {
    # 依存するFlakeを指定
  };
  outputs = inputs: {
    # 任意のNix式をここに定義
  };
}
```

### inputs

Flakesにデフォルトのパッケージリポジトリは存在しません。依存関係としてパッケージリポジトリを全て明示的に指定する必要があります。
nixpkgsを利用したいなら以下のように記述します。

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };
  outputs = inputs: {};
}
```

nixpkgs、正確にはnixpkgsのFlakeをインポートしています。GitHubリポジトリは`github:<オーナー>/<リポジトリ>/<ブランチ>`のフォーマットで指定できます。Flakesユーザーが自身のプロジェクトを公開したいときはGitHubにFlakeをアップするだけでいいのです。

また、Flakesは`flake.lock`ファイルによって**Gitのコミットハッシュでバージョンをロックします**。コマンドで`flake.nix`を評価するとその時点で最新の`inputs`のFlakeが取得され、`flake.lock`が生成されます。

:::details flake.lockの中身とコミットハッシュ

`flake.lock`の`nodes.nixpkgs.rev`とnixpkgsのリポジトリのコミットハッシュが同一なことが確認できます。
@[card](https://github.com/NixOS/nixpkgs/commit/d4d822f526f1f72a450da88bf35abe132181170f)

```diff json :flake.lock
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1688789517,
        "narHash": "sha256-2UpFTJ/bkWCs9Cs7ocko10U7b40VaI5+x57LDun52q4=",
        "owner": "nixos",
        "repo": "nixpkgs",
+       "rev": "d4d822f526f1f72a450da88bf35abe132181170f",
        "type": "github"
      },
      "original": {
        "owner": "nixos",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

:::

### outputs

`outputs`は`inputs`を引数にとる関数式です。出力にはパッケージ、開発用シェル、テンプレート、NixOS modueles(後述)など、色んなものを指定できます。指定可能なものは[Flakes - NixOS Wiki](https://nixos.wiki/wiki/Flakes)に列挙されています。

```nix :hello-rsのflake.nix
outputs = inputs: {
  packages."<system>"."<name>" = derivation;
  devShells."<system>"."<name>" = derivation;
  # templates, apps, formatter, overlays, nixosModules, etc...
};
```

例えば、`packages`は`nix build`, `nix shell`, `nix run`, 、`devShells`は`nix develop`で利用できます。これで複数の用途に対してエントリポイントが1つになりました。

### Nix command

`nix <subcommand>`の形で提供されるコマンド体系は**Nix command**と呼ばれます。Nix commandは内部でFlakesを利用するようになっており、Flakesの依存関係管理によってより強固な再現性を担保します。

#### `nix build`

`nix-build`のNix command版です。`outputs`の`packages`を評価します。
試しにhello-rsをFlake化して利用してみます。以下の`flake.nix`を作成しました。
`inputs`のnixpkgsをインポートして`pkgs`に束縛しています。`packages`には例のNix式をインポートしています。`pkgs ? import <nixpkgs> {}`なんて回りくどい書き方をしたのは、非Flakesベースのレガシーなコマンドでも評価できるようにするためです。

```nix :hello-rsのflake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };
  outputs = inputs:
  let
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
    };
  in
  {
    packages."x86_64-linux" = import ./default.nix pkgs;
  };
}
```

以下のコマンドでビルドします。FlakesはGitを介してファイルを追跡するので、ビルドに関わるファイルはステージかコミットされている必要があります。
Nix commandの引数は`<Flakeの場所>#<名前>`で与えます。

```shell
git add .
nix build .#hello-rs
```

リモートのFlakeも参照できます。`flake.nix`の`inputs`のurlの記法と同じフォーマットでFlakeを指定できます。

```shell
nix build github:nixos/nixpkgs#git
```

#### `nix run`

`nix build`同様、`packages`を評価しますがこちらはビルド完了後に一度だけ実行して終了します。`result`ディレクトリは作成されません。

#### `nix shell`

`nix-shell`のNix command版です。`nix-shell`には、`shell.nix`を用意する方法と`nix-shell -p <パッケージ名>`で直接パッケージを指定する方法の2つがあり、Nix commandでは前者が`nix develop`、後者が`nix shell`に分離されています。

#### `nix develop`

`devShell`を評価します。非常に便利な開発環境構築機能です。
以下のNix式を用意し、`nix develop`コマンドを実行するとDenoが導入されたbashが立ち上がります。

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";

  outputs = inputs: let
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
    };
  in {
    devShells."x86_64-linux".default = pkgs.mkShell {
      buildInputs = with pkgs; [
        deno
      ];
    };
  };
}
```

また、`.envrc`ファイルがあるディレクトリに移動すると自動で環境変数を設定してくれる[direnv](https://github.com/direnv/direnv)と併用すると、ディレクトリを移動するだけで勝手に開発環境が立ち上がる素晴らしい開発体験を得ることができます（[nix-direnv](https://github.com/nix-community/nix-direnv)が必要）。

```shell
echo "use flake" >> .envrc
direnv allow # direnv有効化
```

## NixOSの機能

NixOSはNixのProfilesを拡張し、root権限が必要なシステムレベルの設定をProfilesで行えるようにしています。ユーザー環境のProfileのである`profile`とは別に`system`というProfileを作成します。

```shell
$ ls /nix/var/nix/profiles/system
activate  append-initrd-secrets  bin  boot.json  dry-activate  etc
extra-dependencies  firmware  init  init-interface-version  initrd
kernel  kernel-modules  kernel-params  nixos-version  specialisation
sw  system  systemd
```

`/etc`に配置される各種設定ファイル、カーネルモジュール、サービス、システムレベルのコマンドなどがシンボリックリンクで配置されています。

### NixOS modules

NixOSの最大の特徴であり、非常に便利な機能です。私はこれなしにLinuxを使うことができなくなりました。

NixOS modulesはNix言語を用いて環境を宣言的に記述する機能です。
例として、設定が面倒なIMEとフォントに関するモジュールを示します。

```nix
{pkgs, ...}: {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = [pkgs.fcitx5-mozc];
  };

  fonts = {
    fonts = with pkgs; [
      noto-fonts-cjk-serif
      noto-fonts-cjk-sans
      noto-fonts-emoji
      nerdfonts
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif CJK JP" "Noto Color Emoji"];
        sansSerif = ["Noto Sans CJK JP" "Noto Color Emoji"];
        monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };
}
```

これを書いて`nixos-rebuild switch`コマンドを実行すると、日本語IMEが有効化され、日本語フォント(Noto Fonts)がデフォルトフォントに設定されます。

### ロールバック機能

再現性が高く、宣言的に記述できるといっても、誤った設定を書いてシステムを破壊する可能性は依然存在します。
でも大丈夫！NixOSはシステム環境もロールバックすることができます。NixOSでは前世代のProfileを使ってなんとブートローダーから環境をロールバックすることができます。

![NixOSのロールバック](https://nixos.org/images/screenshots/nixos-grub.png)
_引用: [Guides - How Nix Works - NixOS](https://nixos.org/guides/how-nix-works.html)_

設定でやらかしてLinuxが起動しないような事態に陥っても、再起動してブートローダーから安全な世代を読み込めば即座に復旧可能です。

**_システムの破壊？知るか！俺はNixOSだぞ！_**

## OSインストール

お待たせしました。ここからは手を動かしていきましょう！

NixOSにはグラフィカルインストーラーがあるのでそれを使っていきます。以下のリンクからISOをダウンロードしてUSBに焼いてください。[ventoy](https://www.ventoy.net/en/index.html)というツールがおすすめです。

@[card](https://nixos.org/download.html)

::::details ミニマルISOでのインストール
コンソールからインストールしたい方はMinimal ISO imageをダウンロードしてください。インストールマニュアルの*Installing NixOS*の*Manual Installation*に全ての手順が書いてあります。
手順に従ってインストールした後、作成したユーザーに`passwd`でパスワードを設定するのを忘れないでください。

:::message alert
手順自体は簡単ですが、NixOS独特の操作が一部入るので、初めての方は本記事に従い、まずはグラフィカルインストーラーでインストールするのをおすすめします。
:::

@[card](https://nixos.org/manual/nixos/stable/index.html#sec-installation)

::::

:::details Windowsとのデュアルブート

1. Windowsの設定からBitLocker暗号化を解除
2. BIOS/UEFIからSecure Bootを無効化
3. インストーラー起動後、GpartedでWindowsストレージをリサイズ

BitLocker暗号化が有効化されているとセキュアブート無効化後にWindowsにログインすると回復キーの入力を求められて面倒になるので切っておきます。ストレージのリサイズについて、Windowsの標準ツールでは断片化したストレージを縮小できないので、NixOSのインストーラーに内包されているGpartedで縮小しましょう。
:::

### NixOS installer

ブートローダーから一番上の項目を選択して起動するとこのような画面が現れます。Linuxデスクトップにおいては一般的なインストーラです。

![NixOS installer](/images/nixos-is-the-best/installer.png)

インストーラーから必要な項目を設定していきましょう。インストーラーを日本語にします。

![NixOS installer](/images/nixos-is-the-best/installer-lang.png)

ロケールを選びます。私はシステムの言語は英語（en_US.utf-8）にしていますが、一応ここでも日本語にしておきます。数値と日付のロケールに関しては、コマンドで日時が`○月○日`みたいに表示されると気持ち悪いのでAmerican Englishにしておきます。

![Location](/images/nixos-is-the-best/installer-location.png)

キーボードの配列です。私はUS配列を使っているのでそれを選びました。下の入力欄でタイプしてチェックできます。

![Keyboard](/images/nixos-is-the-best/installer-keyboard.png)

ユーザー名とパスワードを設定します。

![User](/images/nixos-is-the-best/installer-user.png)

デスクトップ環境を選びます。お好みでいいですが、こだわりがないならインストーラーと同じGNOMEにしておきましょう。NixOS modulesを用いて後から簡単に変更できるので特に気にしなくても大丈夫です。

![Desktop](/images/nixos-is-the-best/installer-desktop.png)

プロプライエタリなパッケージを許可するかどうかの質問です。後述の設定でまとめて行うので今はチェックしません。

![Unfree Software](/images/nixos-is-the-best/installer-unfree.png)

インストールするパーティションを選択します。

![Partition](/images/nixos-is-the-best/installer-partition.png)

設定事項を確認してインストールを実行します。40%あたりでプログレスバーがしばらく止まるかもしれませんが、スマホでNixのマニュアルでも読みながら気長に待ちましょう。

![Install](/images/nixos-is-the-best/installer-install.png)

終わりました！再起動しましょう。

![All done](/images/nixos-is-the-best/installer-done.png)

ブートローダーが起動するので、NixOSを選択しましょう。初期設定ではホストがUEFIの場合はsystemed-boot、BIOSならGrubがブートローダーになっています。。

![Boot Loader](/images/nixos-is-the-best/boot-loader.png)
_systemed-boot_

ログイン画面が現れたら設定したユーザー名とパスワードでログインしましょう。

## 環境構築

コンソールを開いて以下のパスを確認します。

```shell
$ ls /etc/nixos/
configuration.nix hardware-configuration.nix
```

この2つのファイルはインストール時に自動生成されたものです。`hardware-configuration.nix`はマシンのハードウェア関連の設定が記述されているため、触らず初期設定のまま利用する方針でいきます。
本題は`configuration.nix`の方で、こちらをバンバン書き換えていきます。

まず、`nano`を使って以下の設定を付け足します。`/etc`の配下なので`sudo`が必要です。

```shell
sudo nano /etc/nixos/configuration.nix
```

```diff nix
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
   # 各種設定...

+  nix = {
+    settings = {
+      experimental-features = ["nix-command" "flakes"];
+    };
+  };
}
```

書き換えたらビルドします。

```
sudo nixos-rebuild switch
```

再起動が必要な設定ではないため、このまま作業を継続します。

上記の設定でNix commandとNix Flakesが有効化されました。
試しにシステム情報を表示するneofetchを使ってみましょう。

```shell
nix run github:nixos/nixpkgs/nixpkgs-unstable#neofetch
```

![neofetch](/images/nixos-is-the-best/neofetch.png)

最初に37.9MBほどのダウンロードが走りますが、これはパッケージ本体ではなく、指定したパッケージリポジトリから最新のパッケージセット（Nix式のセット）をダウンロードしています。常に実行時点で最新のリポジトリを参照するため、リポジトリに更新が入る度にダウンロード処理も毎回実行されます。

`github:nixos/nixpkgs/nixpkgs-unstable`はよく使われるため、`nixpkgs`というAliasが設定されています。以下のコマンドは先程のものと等しいです。

```shell
nix run nixpkgs#neofetch
```

Aliasの一覧は以下のコマンドで確認できます。

```shell
nix registry list
```

### Flake化

Flakesを有効化したので、設定をFlake化しましょう。
`configuration.nix`と`hardware-configuration.nix`をコピーしてGitリポジトリを作ります。

```shell
mkdir ~/.dotfiles && cd ~/.dotfiles
cp /etc/nixos/* .
git init
```

`flake.nix`を作ります。`nix shell`で好きなエディターを導入して編集しましょう。
nixpkgsはローリングリリースのnixpkgs-unstableブランチを選びました。`outputs`には`nixosConfigurations`で定義し、Derivationは`nixpkgs.lib.nixosSystem`というユーティリティを利用します。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: {
    nixosConfigurations = {
      myNixOS = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}
```

ビルドコマンドは以下のように変わります。

```shell
sudo nixos-rebuild switch --flake .#myNixOS
```

### シェル環境の整備

`configuration.nix`を以下のように書き換えてみます。デフォルトのシェルをzshに変更し、諸々のパッケージを導入します。

```diff nix
{ config, pkgs, ... }:
{
  # 各種設定...

  users.users.ユーザー名 = {
    # ...
+    shell = pkgs.zsh; # デフォルトのシェルをZSHに変更
  };

  # ...

+  # 設定込みでパッケージを有効化
+  programs = {
+    git = {
+      enable = true;
+    };
+    neovim = {
+      enable = true;
+      defaultEditor = true; # $EDITOR=nvimに設定
+      viAlias = true;
+      vimAlias = true;
+    };
+    starship = {
+      enable = true;
+    };
+    zsh = {
+      enable = true;
+    };
+  };
}
```

`environment.systemPackages`で指定したパッケージはシステム全体にインストールされます。ユーザー単位でインストールしたい場合は`users.users.ユーザー名.packages`を使います。

`programs`はパッケージをただインストールするだけでなく、諸々のコンフィグを自動設定します。
例えば、bashやzshでstarship（良さげな見た目のプロンプト）を有効化するには、本来ならいくつかの設定を手動で行う必要があるのですが、NixOS moodulesでは`programs.starship.enable = true`だけで勝手に設定してくれます。
ビルド後、新しいコンソールのタブを開くと見た目がイケてるzshが起動します。

### IME・日本語フォントの有効化

大抵の場合、Linuxでこれらを設定するのはかなり面倒なのですが、NixOS modulesでは以下の設定だけで済みます。
ビルド後、再起動してください。Noto Fontsが適用された美しいUIが立ち上がり、IMEが有効化されます。

```diff nix
{ config, pkgs, ... }:
{
  # 各種設定

+ i18n.inputMethod = {
+   enabled = "fcitx5";
+   fcitx5.addons = [pkgs.fcitx5-mozc];
+ };

+ fonts = {
+   fonts = with pkgs; [
+     noto-fonts-cjk-serif
+     noto-fonts-cjk-sans
+     noto-fonts-emoji
+     nerdfonts
+   ];
+   fontDir.enable = true;
+   fontconfig = {
+     defaultFonts = {
+       serif = ["Noto Serif CJK JP" "Noto Color Emoji"];
+       sansSerif = ["Noto Sans CJK JP" "Noto Color Emoji"];
+       monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
+       emoji = ["Noto Color Emoji"];
+     };
+   };
+ };
}
```

### ドライバ・キーリマップ

[nixos-hardware](https://github.com/NixOS/nixos-hardware)はハードウェア関連の設定をよしなにやってくれるモジュールのコレクションです。Intel, AMD, NVIDIAなどのドライバの設定と、Raspberry PiやThinkPadなどのデバイス専用の設定を提供しています。利用できるモジュールはリポジトリの`flake.nix`を直接見るのが手っ取り早いです。

[xremap](https://github.com/k0kubun/xremap)はデスクトップ環境でキーマップを変更するツールです。[NixOS用](https://github.com/xremap/nix-flake/)が提供されています。CapsLockをCtrlに変えたり、Ctrl + HをBackSpaceにしたりできます。一部のアプリケーションにだけ適用、または除外することもできます。

```diff nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
+   nixos-hardware.url = "github:NixOS/nixos-hardware/master"; # ハードウェア設定のコレクション
+   xremap.url = "github:xremap/nix-flake"; # キー設定をいい感じに変更できるツール
  };

  outputs = inputs: {
    nixosConfigurations = {
      myNixOS = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
+       specialArgs = {
+           inherit inputs; # `inputs = inputs;`と等しい
+       };
      };
    };
  };
}
```

```diff nix :configuration.nix
{
+ inputs,
  config,
  pkgs,
  ...
}:
{
  imports =
    [
      # ...
    ]
+   # 環境に応じてインポートするモジュールを変更してください
+   ++ (with inputs.nixos-hardware.nixosModules; [
+     common-cpu-amd
+     common-gpu-nvidia
+     common-pc-ssd
+   ]);
+   # xremapのNixOS modulesを使えるようにする
+   ++ [
+     inputs.xremap.nixosModules.default
+   ]

+ # xremapでキー設定をいい感じに変更
+ services.xremap = {
+   userName = "ユーザー名";
+   serviceMode = "system";
+   config = {
+     modmap = [
+       {
+         # CapsLockをCtrlに置換
+         name = "CapsLock is dead";
+         remap = {
+           CapsLock = "Ctrl_L";
+         };
+       }
+     ];
+     keymap = [
+       {
+         # Ctrl + HがどのアプリケーションでもBackspaceになるように変更
+         name = "Ctrl+H should be enabled on all apps as BackSpace";
+         remap = {
+           C-h = "Backspace";
+         };
+         # 一部アプリケーション（ターミナルエミュレータ）を対象から除外
+         application = {
+           not = ["Alacritty" "Kitty" "Wezterm"];
+         };
+       }
+     ];
+   };
+ };
}
```

### その他の便利な設定

```diff nix :configuration.nix
{ config, pkgs, ... }:
{
+ # カーネルを変更する
+ boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

+ # ホスト名を変更する
+ networking.hostName = "好きなホスト名";

  nix = {
    settings = {
+     auto-optimise-store = true; # Nix storeの最適化
      experimental-features = ["nix-command" "flakes"];
    };
+   # ガベージコレクションを自動実行
+   gc = {
+     automatic = true;
+     dates = "weekly";
+     options = "--delete-older-than 7d";
+   };
  };

+ # プロプライエタリなパッケージを許可する
+ nixpkgs.config.allowUnfree = true;

+ # tailscale（VPN）を有効化
+ # 非常に便利なのでおすすめ
+ services.tailscale.enable = true;
+ networking.firewall = {
+   enable = true;
+   # tailscaleの仮想NICを信頼する
+   # `<Tailscaleのホスト名>:<ポート番号>`のアクセスが可能になる
+   trustedInterfaces = ["tailscale0"];
+   allowedUDPPorts = [config.services.tailscale.port];
+ };

+ # サウンド設定 - (デフォルトでこうなっているかもしれない)
+ sound.enable = true;
+ hardware.pulseaudio.enable = false; # pipewireに置き換える
+ security.rtkit.enable = true; # pipewireに必要
+ services.pipewire = {
+   enable = true;
+   alsa.enable = true;
+   alsa.support32Bit = true;
+   jack.enable = true;
+   pulse.enable = true;
+ };

+ # マイク用ノイズ低減アプリ
+ programs = {
+   noisetorch.enable = true;
+ };

+ # Dockerをrootlessで有効化
+ virtualisation = {
+   docker = {
+     enable = true;
+     rootless = {
+       enable = true;
+       setSocketVariable = true; # $DOCKER_HOSTを設定
+     };
+   };
+ };

+ # Linuxデスクトップ向けのパッケージマネージャ
+ # アプリケーションをサンドボックス化して実行する
+ # NixOSが対応していないアプリのインストールに使う
+ services.flatpak.enable = true;
+ xdg.portal.enable = true; # flatpakに必要

+ # Steamをインストール
+ # Proton ExperimentalはSteamの設定から有効化する
+ programs.steam = {
+   enable = true;
+   remotePlay.openFirewall = true;
+   dedicatedServer.openFirewall = true;
+ };

+ # Steamのフォントが文字化けするので、フォント設定を追加
+ # SteamだけフォントをMigu 1Pにする
  fonts = {
    fonts = with pkgs; [
      # ...
+     migu
    ];
    fontDir.enable = true;
    fontconfig = {
      # ...
+     localConf = ''
+       <?xml version="1.0"?>
+       <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
+       <fontconfig>
+         <description>Change default fonts for Steam client</description>
+         <match>
+           <test name="prgname">
+             <string>steamwebhelper</string>
+           </test>
+           <test name="family" qual="any">
+             <string>sans-serif</string>
+           </test>
+           <edit mode="prepend" name="family">
+             <string>Migu 1P</string>
+           </edit>
+         </match>
+       </fontconfig>
+     '';
    };
  };
}
```

## home-manager

NixOS modulesはどちらかというとシステム環境向けの機能であり、ユーザー環境向けの環境構築ツールが別に存在します。

[hoem-manager](https://github.com/nix-community/home-manager)とは、nix-community製のユーザー環境構築ツールです。こちらはNixと同様、他のディストリビューションやMacでも利用することができます。root権限が必要な領域までは設定できない一方、ユーザー環境で動作するアプリケーションに関してはNixOS modulesより多彩な設定ができます。

### 導入

NixOS modulesとして導入する方法とhome-manager単体で導入する方法があります。非NixOS環境でもhome-managerの設定を再利用できるように、今回はhome-manager単体で導入します。

```diff nix :flake.nix
{
  inputs = {
    # ...
+   home-manager = {
+     url = "github:nix-community/home-manager";
+     inputs.nixpkgs.follows = "nixpkgs";
+   };
  };

  outputs = inputs: {
    # ...
+   homeConfigurations = {
+     myHome = inputs.home-manager.lib.homeManagerConfiguration {
+       pkgs = import inputs.nixpkgs {
+         system = "x86_64-linux";
+         config.allowUnfree = true; # プロプライエタリなパッケージを許可
+       };
+       extraSpecialArgs = {
+         inherit inputs;
+       };
+       modules = [
+         ./home.nix
+       ];
+     };
+   };
}
```

```nix :home.nix
{
  home = rec { # recでAttribute Set内で他の値を参照できるようにする
    username="ユーザー名";
    homeDirectory = "/home/${username}"; # 文字列に値を埋め込む
    stateVersion = "22.11";
  };
  programs.home-manager.enable = true; # home-manager自身でhome-managerを有効化
}
```

ビルドします。`inputs.nixpkgs.follow`オプションを付けて導入している都合上、`flake.lock`を削除してからビルドする必要があります。削除後のステージングを忘れないでください。

```
rm flake.lock
git add .
nix run nixpkgs#home-manager -- switch --flake .#myHome
```

第1世代のProfileが作成されたら成功です。

### home.file

home-managerは、NixのProfilesを利用して、任意のファイルを$HOME以下の場所にシンボリックリンクとして配置できます。

```nix
home.file = {
  "wallpaper.png" = {
    target = "Wallpaper/wallpaper.png"; # ~/Wallpaper/wallpaper.pngに配置
    source = ./wallpaper.png; # 配置するファイル
  };
};
```

### home.packages

インストールしたいパッケージを指定します。

```diff nix :home.nix
+ home.packages = with pkgs; [
+   bat
+   bottom
+   exa
+   httpie
+   pingu
+   ripgrep
+ ];
```

ここまで何度か`with`構文が出てきましたが、上と下のコードは等しいです。

```nix
home.packages = [
  pkgs.bat
  pkgs.bottom
  pkgs.eza
  pkgs.httpie
  pkgs.pingu
  pkgs.ripgrep
];
```

### programs

NixOS modulesと同様、programsを利用して様々な設定を行えます。
以降の設定はあくまで例ですので、[Home Manager option search](https://mipmip.github.io/home-manager-option-search/)で適宜検索してください。

#### zsh & starship

```nix :zsh.nix
{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    autocd = true; # cdなしでファイルパスだけで移動
    enableCompletion = true; # 自動補完
    enableAutosuggestions = true; # 入力サジェスト
    syntaxHighlighting.enable = true; # シンタックスハイライト
    shellAliases = {
      cat = "bat";
      grep = "rg";
      ls = "eza --icons always --classify always";
      la = "eza --icons always --classify always --all ";
      ll = "eza --icons always --long --all --git ";
      tree = "eza --icons always --classify always --tree";
    };
  };
}
```

:::details starship (アイコンをNerdfonts化)

starshipで以下の設定を有効化したい場合、NixOS modulesのstarshipを無効化してください。

```diff nix :configuration.nix
- starship = {
-   enable = true;
- };
+ # starship = {
+ #   enable = true;
+ # };
```

```nix :starship.nix
{
  programs.starship = {
    enable = true;
    settings = {
      # Nerd Font Symbols
      aws.symbol = "  ";
      buf.symbol = " ";
      c.symbol = " ";
      conda.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      git_branch.symbol = " ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = "⌘ ";
      hg_branch.symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = " ";
      meson.symbol = "喝 ";
      nim.symbol = " ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      os.symbols = {
        Alpine = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "﯑ ";
        Gentoo = " ";
        HardenedBSD = "ﲊ ";
        Illumos = " ";
        Linux = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = " ";
        openSUSE = " ";
        OracleLinux = " ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        Redox = " ";
        Solus = "ﴱ ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Windows = " ";
      };
      package.symbol = " ";
      python.symbol = " ";
      rlang.symbol = "ﳒ ";
      ruby.symbol = " ";
      rust.symbol = " ";
      scala.symbol = " ";
      spack.symbol = "🅢 ";
    };
  };
}
```

:::

#### Git

```nix :git.nix
{pkgs, ...}: {
  programs.git = {
    enable = true;
    userName = "Git用のユーザー名";
    userEmail = "Git用のメールアドレス";
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    extensions = with pkgs; [gh-markdown-preview]; # オススメ
    settings = {
      editor = "nvim";
    };
  };
}
```

#### Neovim

Neovimのプラグイン管理を全てNixで行うことで、環境を移行しても`home-manager switch`すればどこでもNeovim環境を再現できます。
（私の場合、Vimプラグインはlazy.nvimで管理し、LSPやフォーマッタだけNixで管理しています。）

`extrapackages`で指定したパッケージは、ユーザー環境にはPATHが反映されずNeovim内部でのみ有効になります。`home.packages`で指定したパッケージと重複しても問題ありません。

```nix :neovim.nix
{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      # Treesitter
      (nvim-treesitter.withPlugins (plugins:
        with plugins; [
          tree-sitter-markdown
          tree-sitter-nix
          # ...
        ]))
      telescope-nvim
      # ...
    ];

    # Neovim内部でのみPATHが通されるパッケージ
    # LSPやフォーマッタ、その他Neovimから呼び出すツールを指定しよう
    extraPackages = with pkgs; [
      ripgrep
      biome
      nodePackages.eslint
      nodePackages.prettier
      nodePackages.typescript-language-server
      # ...
    ];

    # ~/.config/nvim/init.luaに文字列が展開される
    extraLuaConfig = builtins.readFile ./init.lua;
  };
}
```

`builtins.<関数名>`でNix言語のビルトイン関数を呼び出せます。ここでは`readFile`関数でファイルを文字列として読み込んでいます。

#### direnv

```nix :direnv.nix
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
```

#### 言語・ツール

グローバルにツールをインストールしていきます。

```nix :development.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    gcc
    go
    nodejs-slim # npmのないNode.js単体
    nodePackages.pnpm
    nodePackages.wrangler
    deno
    bun
    python312
    zig
  ];
}
```

私の場合、しっかり開発環境を整えたい時は、グローバルにインストールしたツールは使わず、プロジェクトごとに`flake.nix`でdevShellを構築しています。

#### Rustツールチェーン

RustをNixで入れる場合、そのままだとツールチェーンの管理が面倒なので[oxalica/rust-overlay](https://github.com/oxalica/rust-overlay)や[nix-community/fenix](https://github.com/nix-community/fenix)の利用を強く推奨します。例としてrust-overlayを追加してみましょう。

```diff nix :flake.nix
{
  inputs = {
    # ...
+   rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = inputs: {
    # ...
    homeConfigurations = {
      myHome = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true; # プロプライエタリなパッケージを許可
+         overlays = [(import inputs.rust-overlay)];
        };
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home.nix
        ];
      };
    };
}
```

```diff nix :development.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    # ...
+   rust-bin.stable.latest.default
  ];
}
```

[Overlays](https://nixos.wiki/wiki/Overlays)はnixpkgsを上書き・拡張するための仕組みです。そのため、rust-overlayで追加したパッケージは通常のパッケージと同様、`pkgs`を介してアクセスできます。`rust-bin.stable.latest.default`は、Rustの最新のStableのツールチェーンを一括インストールします。

また、以下のようにしてビルドターゲットを追加できます。

```diff nix
- rust-bin.stable.latest.default
+ (rust-bin.stable.latest.default.override {
+   targets = ["wasm32-unknown-unknown" "wasm32-wasi"];
+ })
```

これらは本来rustupで管理するものですが、Nixを使って宣言的に管理することもできます。

#### Wezterm

ターミナルエミュレータです。他にもAlacrittyやKittyなども`programs`で設定できます。

```nix :wezterm.nix
{
  programs.wezterm = {
    enable = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
}
```

```lua :wezterm.lua
local wezterm = require("wezterm")

return {
	-- Theme
	color_scheme = "MyTheme",

	-- Font
	font = wezterm.font_with_fallback({
		{ family = "JetBrainsMono Nerd Font", weight = "Regular" },
		{ family = "JetBrainsMono Nerd Font", weight = "Regular", assume_emoji_presentation = true },
		{ family = "Noto Sans CJK JP" },
	}),
	font_size = 14.0,

	-- Padding
	window_padding = {
		left = 10,
		right = 10,
		top = 10,
		bottom = 10,
	},

	-- Tab
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,

	-- Misc
	use_ime = true, -- Enable IME
	check_for_updates = false, -- Disable update check
	audible_bell = "Disabled", -- Disable bell
}
```

#### ブラウザ

FirefoxやChrome, Brave, Vivaldi等の各種Chromiumブラウザをprogramsで設定できます。
`commandLineArgs`で起動時のオプションを追加できます^[[ブラウザを完全にDarkにする](https://scrapbox.io/asa1984/ブラウザを完全にDarkにする)]。

```nix :browser.nix
{
  programs = {
    firefox.enable = true;
    google-chrome.enable = true;
    vivaldi = {
      enable = true;
      commandLineArgs = ["--enable-features=WebUIDarkMode" "--force-dark-mode"];
    };
  };
}
```

#### VS Code

`programs.vscode.enabal = true;`でVS Codeを有効化すると、`settings.json`等の設定ファイルがNixによって書き込み権限をロックされるため、VS Codeの設定同期機能が使えなくなります。同期機能を使いたい場合は、`home.packages = [pkgs.vscode];`でインストールしてください。

#### その他アプリケーション

```nix :apps.nix
{pkgs, ...}: {
  # Spotify TUI
  programs.ncspot.enable = true;

  # OBS
  programs.obs-studio.enable = true;

  home.packages = with pkgs; [
    discord
    discord-ptb
    gnome.totem # ビデオプレーヤー
    gnome.evince # PDFビューアー
    parsec-bin # 超速いリモートデスクトップクライアント
    remmina # VNCクライアント
    slack
    spotify
  ];
}
```

### 有効化

モジュール化した場合、`imports`でファイルパスを指定してインポートします。`import`とは動作が若干異なり、`imports`では指定したファイルの出力部分がそのまま呼び出し元のコードに展開されると考えてください。

```nix :home.nix
{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./neovim.nix
    ./direnv.nix
    ./development.nix
    ./wezterm.nix
    ./browser.nix
    ./apps.nix
  ];

  # ...
}

```

もう一度コマンドを実行するとインストールが始まり、ユーザー環境の構築が終わります。あとは自分好みに設定を変えていきましょう。お疲れさまでした。

## 痛み

> 要はバランスです

> 困った時はDockerを使おう

ここまで読んでくださった方ならNixOSの魅力を分かってくれたと思います。
しかし一方、NixOSはガッチガチに思想の強いLinuxディストリビューションであり、必然的にトレードオフが発生します。非純粋性の塊のようなシステムをここまで上手く扱えていることを称賛すべきなのですが、できないことも正しく知る必要があります。

### イミュータブルなファイル

当然ながらファイルの可変性を要求するソフトウェアとは相性が悪いです。例えば、Nixで管理している設定ファイルを何らかのソフトウェアが書き換えようとする（e.g. `.bashrc`等を書き換えてPATHにディレクトリを追加するインストーラー）と、Nixが書き込み権限を制限しているため失敗します。それが困る場合は該当する設定やパッケージをNixの管理外に置けば済む話で、実際他のLinuxディストロやMacでNix単体を使うだけならほとんど問題ないのですが、システムのベースがNixのNixOSでは上手くいかない場合もあります。

### Nixの籠の外

NixOSにおいて、独自のインストーラーやバイナリ形式で配布しているソフトウェアをインストールするには、ユーザーがNix式を書いてラップしてやる必要があります。
例えば実行可能ファイルを直接ダウンロードする形式の場合、nixpkgsの[Fetcher](https://ryantm.github.io/nixpkgs/builders/fetchers/)を利用すればダウンロードできます。ただし、再現性を担保するために事前にハッシュを指定する必要があります。もし、フェッチしてきたファイルのハッシュと指定したハッシュが異なればダウンロードが失敗します。

また、現代の開発ではプログラミング言語固有のパッケージマネージャで依存関係を管理をするのが常ですが、Nixパッケージとしてビルドするにはそれらのパッケージ情報をNix側に持ってくる必要があります。Rustなど健全なパッケージマネージャを持つ言語との相性はいいのですが、一部の行儀の悪いパッケージマネージャをラップしようとすると大変な手順を踏む場合があります。

### 情報がない

はい、情報がありません。NixOSはLinuxユーザー御用達のArch Wikiが通用しない数少ないディストロの1つであり、代わりに[NixOS Discourse](https://discourse.nixos.org)やGitHubのissueとにらめっこすることになります。
NixOSやhome-managerの設定について知りたいなら、他人のGitHubリポジトリを見に行ってコードを読み、[NixOS search](https://search.nixos.org/options)や[Home Manager option search](https://mipmip.github.io/home-manager-option-search/)でオプションの詳細を検索しましょう。そしてあなたも記事を書いてください！

## _NixOS is the best_

環境を破壊して起動しなくなったArch Linuxを前に悲しみに暮れていた頃、ロゴがカッコいいからとノリでインストールしてみたら、気づいたら手元のWindowsマシンが全てNixOSになっていました。感銘を受けてNixOSのパワーは素晴らしいぞと吹聴して回ったのですが、誰も使ってくれなかったのでこの記事を書きました。

![How Nix manage packages](https://pbs.twimg.com/media/Fm02rGNaYAECO88?format=jpg&name=large)
_学校の共有スペース_

これがBestなLinuxディストリビューションだ！と本気で言っているわけではないですが、最おもしろディストロではあると思うので、ぜひ触ってみてください。

## 参考

- [NixOS Wiki](https://nixos.wiki/wiki/Main_Page)
  - 非公式Wiki（NixOSにおけるArch Wiki）
  - NixOSで何か調べる時はまずこれを参照する
- [Nix reference Manual](https://nixos.org/manual/nix/stable/introduction.html)
  - Nixのコンセプトや仕組みを理解するのに良い
  - コマンドのリファレンスがある。
- [Zero to Nix](https://zero-to-nix.com)
  - 滅茶苦茶良質なNixのチュートリアル
  - 記事執筆中に発見。これで勉強したかった😭
- [NixOS Discourse](https://discourse.nixos.org)
  - 公式フォーラム
- [NixOS search](https://search.nixos.org/packages)
  - 公式のnixpkgsとNixOSのオプションの検索サイト
- [Home Manager option search](https://mipmip.github.io/home-manager-option-search/)
  - サードパーティーのhome-managerのオプション検索サイト
- [Tailscale on NixOS: A new Minecraft server in ten minutes](https://tailscale.com/blog/nixos-minecraft/)
  - NixOSとTailscaleでマインクラフトサーバーを建てるTailscaleのブログ
  - インフラとしてのNixOS利用例
- [HERPにおけるNix活用](https://blog.ryota-ka.me/posts/2022/10/08/how-we-use-nix-in-herp-inc)

  - 実際にNixを使っている会社の方のブログ
  - 非常にわかりやすい

- 使用したパッケージなど

  - [NixOS/nix](https://github.com/NixOS/nix)
  - [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)
  - [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)
  - [xremap/nix-flake](https://github.com/xremap/nix-flake)
  - [oxalica/rust-overlay](https://github.com/oxalica/rust-overlay)

- NixOS/home-managerの設定
  - [sherubthakur/dotfiles](https://github.com/sherubthakur/dotfiles)
    - [r/unixpornの投稿](https://www.reddit.com/r/unixporn/comments/wy695w/xmonad_the_functional_setup/)をきっかけにNixOSを知りました
  - [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)
  - [Misterio77/nix-config](https://github.com/Misterio77/nix-config)
  - [fufexan/dotfiles](https://github.com/fufexan/dotfiles)
  - [asa1984/dotfiles](https://github.com/asa1984/dotfiles)
    - 私の設定です
