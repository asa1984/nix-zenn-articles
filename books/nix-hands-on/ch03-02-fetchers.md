---
title: "　§2. Fetcher"
---

## Fetcherのしくみ

**Fetcher**は再現性を損わずにインターネットからリソースを取得する仕組みです。FetcherはNix言語の関数として提供されており、用途ごとに様々な種類がありますが、その全てが**ハッシュ値**を引数にとります。Fetcher実行時、Nixは事前に指定されたハッシュと取得したリソースから算出したハッシュが一致するか検証します。もし、一致しなかった場合は例外を投げてNix式の評価を終了します。シンプルですが確実に冪等性を保証できます。

## 様々なFetcher

### ビルトインのFetcher

Nix言語の組み込み関数としていくつかのfetcherが搭載されています。ここでは`fetchGit`と`fetchTarball`を紹介します。

#### fetchGit

その名の通りGitリポジトリを取得するfetcherです。試しに[NixOS/nix](https://github.com/NixOS/nix)を取得してみましょう。執筆時点で最新のコミットハッシュを指定しておきます。

```nix :fetchGitDemo.nix
builtins.fetchGit {
  url = "https://github.com/NixOS/nix";
  ref = "master"; # ブランチ
  rev = "59def6c23b6d5173cc07990cf4d17d5a3ee1bddc"; # コミットハッシュ
}
```

```bash :fetchGitDemo.nixの評価結果
$ nix eval --file ./fetchGitDemo.nix
# ↓実際は1行だが見やすさのため表示を改変
{
  lastModified = 1723483316;
  lastModifiedDate = "20240812172156";
  narHash = "sha256-3D7e6g4doWtOXHleD1n555nw411bAu0rSSpsUWp8ti4=";
  outPath = "/nix/store/dpinwg1p2kynwji4hlvk7jqyv9zhyi8s-source";
  rev = "59def6c23b6d5173cc07990cf4d17d5a3ee1bddc";
  revCount = 18115;
  shortRev = "59def6c";
  submodules = false;
}
```

リポジトリを取得できました。
`fetchGit`はAttrSetを返します。`outPath`が取得したリポジトリが配置されたストアパスで、`narHash`はNix独自のアーカイブフォーマットである[NAR](https://zenn.dev/asa1984/books/nix-introduction/viewer/07-binary-cache#nar)のハッシュです。その他はGitリポジトリのメタデータです。
このAttrSetをmkDerivationの`src`に渡せばそのままビルドに使用できます。

#### fetchTarball

Tarball（`.tar.gz`など）を取得します。先程はGitリポジトリとして取得しましたが、今回はGitHubのreleaseからtarballを取得してみましょう。

`fetchTarball`はtarballのハッシュを指定する必要があるのですが、ハッシュがまだ分からないので空文字列を入れておきます。

```nix :fetchTarballDemo.nix
builtins.fetchTarball {
  url = "https://github.com/NixOS/nix/archive/refs/tags/2.24.2.tar.gz";
  sha256 = "";
}
```

```bash :fetchTarballDemo.nixの評価とエラー
$ nix eval --file ./fetchTarballDemo.nix
error:
       … while evaluating the file '/home/asahi/Anything/nix-src/fetchTarballDemo.nix':

       … while calling the 'fetchTarball' builtin

         at /home/asahi/Anything/nix-src/fetchTarballDemo.nix:1:1:

            1| builtins.fetchTarball {
             | ^
            2|   url = "https://github.com/NixOS/nix/archive/refs/tags/2.24.2.tar.gz";

       error: hash mismatch in file downloaded from 'https://github.com/NixOS/nix/archive/refs/tags/2.24.2.tar.gz':
         specified: sha256:0000000000000000000000000000000000000000000000000000
         got:       sha256:063yg69fx8s27q1zjihss0zci4744scj0cnf460yg11nn7kkzvlx
```

`sha256`に空文字列を指定すると代わりに`sha256:0000000000000000000000000000000000000000000000000000`というハッシュで検証が行われます。もちろん一致しないので失敗しますが、そのとき正しいハッシュも表示されます。正しいハッシュを入れてもう一度評価しましょう。

```diff nix :fetchTarballDemo.nix
builtins.fetchTarball {
  url = "https://github.com/NixOS/nix/archive/refs/tags/2.24.2.tar.gz";
- sha256 = "";
+ sha256 = "sha256:063yg69fx8s27q1zjihss0zci4744scj0cnf460yg11nn7kkzvlx";
}
```

```bash :もう一度fetchTarballDemo.nixを評価
$ nix eval --file ./fetchTarballDemo.nix
"/nix/store/11ny982v57jfyrm4q4iv2y3i4i76s2zk-source"
```

ストアパスが表示されました。`fetchTarball`は取得したtarballを展開するので、ストアパスの中身はディレクトリになっています。

## Nixpkgsが提供するFetcher

色々なfetcherが提供されているので、それぞれの用途に合ったものを使いましょう。

### fetchFromGitHub

最も広く使われているfetcherです。GitHubからソースコードを取得します。

`rev`にはreleaseのtag名を指定します。`hash`はコミットハッシュではなく、取得したアーカイブのハッシュです。

```nix :fetchGitDemo.nix
fetchFromGitHub {
  owner = "NixOS";
  repo = "nix";
  rev = "2.24.2";
  hash = "sha256-ne4/57E2hOeBIc4yIJkm5JDIPtAaRvkDPkKj7pJ5fhg=";
};
```

これと似たfetcherとして`fetchFromGitLab`があります。

## プログラミング言語固有のFetcher

現代的なプログラミング言語の多くは、独自の固有のパッケージマネージャを持っているので、`fetchurl`や`fetchFromGitHub`のように簡単にはいきません。この問題に対するアプローチとして主に以下の方法があります。

#### 1. ロックファイルを解析してfetcherに変換

主流の手法です。現代的なパッケージマネージャは、依存関係を記述したファイルとロックファイルを持っているため、これらを解析することでfetcherに変換できます。

Rustのパッケージマネージャ・Cargoの場合、`Cargo.lock`にパッケージの場所とチェックサムが記述されているので、これを読み取ってfetcherに変換することができます。

Rustだけでなく、様々なプログラミング言語に対応した専用のfetcherがNixpkgsから提供されています。

#### 2. コード生成

ツールを利用してfetcherが記述されたNixファイルを生成し、それを評価するというタイプです。1の手法がNix言語内部で完結するのに対し、この手法はコード生成を行う外部ツールが必要です。

このタイプのツールとして[zon2nix](https://github.com/nix-community/zon2nix)があります。これはZigの依存関係を定義する`build.zig.zon`を解析し、対応するfetcherが記述されたNixファイルを生成します。

#### 3. 手動でfetcherを記述

Node.jsのnpmやPythonのpipではよくある話ですが、一度パッケージをインストールした後、そのパッケージ独自のインストール処理を行う場合があります。これはfetcherの自動生成では対応できないので、手動でfetcherを記述する必要があります。

### Flakes as Fetcher

実は、Flakesをfetcherとして利用することができます。Flakeのinputsに`flake = false`というオプションをつけることで、Flake以外のものを取得することができます。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gnu-hello-src = {
      url = "https://ftp.gnu.org/gnu/hello/hello-2.12.tar.gz";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      gnu-hello-src,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          hello = pkgs.stdenv.mkDerivation {
            pname = "hello";
            version = "2.12";
            src = gnu-hello-src;
          };
        };
      }
    );
}
```

GNU Helloのソースコードのtarballをinputsに指定し、それをそのままmkDerivationの`src`に渡しています。

問題なくビルドすることができます。

```bash :ビルド & 実行
$ nix run .#hello
Hello, world!
```

今回はアーカイブのURLを指定しましたが、`github:owner/repo`のようにGitHubリポジトリを指定することも可能で、その場合は`fetchFromGitHub`と同じようにソースコードが取得されます。

通常のfetcherとの大きな違いは、自分でハッシュを記述することなく`flake.lock`で自動で管理できることです。初回取得時は`flake.lock`が自動生成され、更新するときも`nix flake update`だけで済みます。

デメリットとして、Flakeを評価すると必ず全てのinputsが取得されてしまうことが挙げられます。Fetcherは通常のNix式として評価されるので、遅延評価により必要になるまで実行されませんが、Flakeは一度評価されるとバージョンロックを行うために全てのinputsを取得してしまうので、不要なリソースを取得してしまう可能性があります。

## Fetcherの自動生成

[nvfetcher](https://github.com/berberman/nvfetcher)は設定ファイルからfetcherをコード生成するツールです。Gitリポジトリやpypiパッケージなどに対応しています。

https://github.com/berberman/nvfetcher

大量のfetcherを利用する場合に便利でしょう。GitHub ActionsなどのCIと組み合わせて、定期的にfetcherを更新するという使い方もできます。
