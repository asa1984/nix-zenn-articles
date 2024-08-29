---
title: "　§1. stdenv"
---

## Standard Environment

**stdenv**（Standard Environment）は、UNIXパッケージのビルドに必要な標準的な環境を提供するderivationです。Nixpkgsが提供するパッケージのほとんどは、直接的・間接的に**stdenv**を用いてビルドされています。

stdenvはLinuxとDarwin（macOS）で内容が微妙に異なるのですが、ここではLinuxのstdenvを例にとって解説します。stdenvは非常に多機能なので、重要な部分をピックアップして説明します。

## stdenvの構成

stdenvをrealiseするとストアパスは以下のようになります。

```bash :stdenvのストアパスの中身
├── nix-support/
└── setup
```

重要なのは`setup`という1700行ほどのシェルスクリプトです。先頭部分は以下のようになっています。

```sh :setupの先頭部分
export SHELL=/nix/store/i1x9sidnvhhbbha2zhgpxkhpysw6ajmr-bash-5.2p26/bin/bash
initialPath="/nix/store/cnknp3yxfibxjhila0sjd1v3yglqssng-coreutils-9.5 /nix/store/5my5b6mw7h9hxqknvggjla1ci165ly21-findutils-4.10.0 /nix/store/fy6s9lk05yjl1cz2dl8gs0sjrd6h9w5f-diffutils-3.10 /nix/store/9zsm74npdqq2lgjzavlzaqrz8x44mq9d-gnused-4.9 /nix/store/k8zpadqbwqwalggnhqi74gdgrlf3if9l-gnugrep-3.11 /nix/store/2ywpssz17pj0vr4vj7by6aqx2gk01593-gawk-5.2.2 /nix/store/nzzl7dnay9jzgfv9fbwg1zza6ji7bjvr-gnutar-1.35 /nix/store/7m0l19yg0cb1c29wl54y24bbxsd85f4s-gzip-1.13 /nix/store/cx1220ll0pgq6svfq7bmhpdzp0avs09w-bzip2-1.0.8-bin /nix/store/70anjdzz5rj9lcamll62lvp5ib3yqzzr-gnumake-4.4.1 /nix/store/i1x9sidnvhhbbha2zhgpxkhpysw6ajmr-bash-5.2p26 /nix/store/6rv8ckk0hg6s6q2zay2aaxgirrdy4l6v-patch-2.7.6 /nix/store/xzdawyw3njki7gx2yx4bkmhdzymgjawm-xz-5.6.2-bin /nix/store/rnndls2fiid1sic81i06dkqjhh24lpvr-file-5.45"
defaultNativeBuildInputs="/nix/store/dv5vgsw8naxnkcc88x78vprbnn1pp44y-patchelf-0.15.0 /nix/store/i4iynx9axbq23sd0gyrc5wdb46zz6z8l-update-autotools-gnu-config-scripts-hook /nix/store/h9lc1dpi14z7is86ffhl3ld569138595-audit-tmpdir.sh /nix/store/m54bmrhj6fqz8nds5zcj97w9s9bckc9v-compress-man-pages.sh /nix/store/wgrbkkaldkrlrni33ccvm3b6vbxzb656-make-symlinks-relative.sh /nix/store/5yzw0vhkyszf2d179m0qfkgxmp5wjjx4-move-docs.sh /nix/store/fyaryjvghbkpfnsyw97hb3lyb37s1pd6-move-lib64.sh /nix/store/kd4xwxjpjxi71jkm6ka0np72if9rm3y0-move-sbin.sh /nix/store/pag6l61paj1dc9sv15l7bm5c17xn5kyk-move-systemd-user-units.sh /nix/store/jivxp510zxakaaic7qkrb7v1dd2rdbw9-multiple-outputs.sh /nix/store/ilaf1w22bxi6jsi45alhmvvdgy4ly3zs-patch-shebangs.sh /nix/store/cickvswrvann041nqxb0rxilc46svw1n-prune-libtool-files.sh /nix/store/xyff06pkhki3qy1ls77w10s0v79c9il0-reproducible-builds.sh /nix/store/aazf105snicrlvyzzbdj85sx4179rpfp-set-source-date-epoch-to-latest.sh /nix/store/gps9qrh99j7g02840wv5x78ykmz30byp-strip.sh /nix/store/62zpnw69ylcfhcpy1di8152zlzmbls91-gcc-wrapper-13.3.0"
defaultBuildInputs=""
export NIX_ENFORCE_PURITY="${NIX_ENFORCE_PURITY-1}"
export NIX_ENFORCE_NO_NATIVE="${NIX_ENFORCE_NO_NATIVE-1}"

# (中略)
```

`$SHELL`はBashのストアパス、`$initialPath`はcoreutilsやmakeといったツール群のストアパス、`$defaultNativeBuildInputs`は複数のシェルスクリプトやgccのストアパスを指しています。
省略しましたが、これより下にはビルド補助用のBash関数の定義や`$PATH`を設定する処理、そして**Phase**と呼ばれるビルドの各ステップを実行する処理が続きます。

[_1.4. Nix言語とderivation_](ch01-04-derivation)でderivation関数を用いて`hello-txt`（`Hello`と書かれたただのtxtファイル）をビルドしたとき、`/bin/sh`でシェルスクリプトを実行したことを覚えているでしょうか？
stdenvの`setup`はまさしくそこで実行されるシェルスクリプトです。`setup`はビルドを実行するシェル（Bash）や標準的なツール群（coreutilsなど）、その他ビルドを補助する独自のシェルスクリプトなどをPATHに含んだ「ビルド環境」を構築します。つまり、ビルドに必要となる最低限の環境を整えてくれるのです。

意外と原始的な方法で構築されていますね。ただし、PATHに導入されるツールやシェルスクリプトのパスは全てストアパスになっており、ビルド環境はサンドボックス化されホスト環境から隔離されるため、外部の要素が入り込む余地はありません。

## stdenvに含まれるツール

stdenvのPATHには一般的なUNIX環境で使われるツールが含まれています。

https://nixos.org/manual/nixpkgs/stable/#sec-tools-of-stdenv

- Bash
- gcc
- coreutils（`cat`/`cp`/`ls`など）
- findutils（`find`）
- diffutils（`diff`/`cmp`）
- sed
- grep
- awk
- tar
- アーカイブツール
  - gzip
  - bzip2
  - xz
- make
- ビルドを補助するシェルスクリプト
- patchelf（Linuxのみ）

stdenvの亜種として**stdenvNoCC**というものがあり、こちらにはgccが含まれていません。

### シェルスクリプト

<!-- TODO -->

<!-- いくつかのbash関数が定義されており、ビルドスクリプト内でそのまま利用することができます。 -->

TODO!

### patchelf

Linuxの場合、[patchelf](https://github.com/NixOS/patchelf)が導入されます。patchelfはELF形式のバイナリに直接パッチを当てるツールです。動的リンクするライブラリのパスを変更することができます。

## GNU Helloをビルドしよう！

実際にビルドを行うには`stdenv.mkDerivation`関数を使ってstdenvにパッケージのソースコードや依存関係を追加する必要があります。

`mkDerivation`関数について詳しく見る前に、一度stdenvを使って自分たちでGNU Helloをビルドしてみましょう。`nix build .#hello`でビルドできたら成功です。

まずはFlakeを作成します。

```bash :Flakeの作成
$ mkdir gnu-hello-nix
$ cd gnu-hello-nix
$ touch flake.nix
```

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      { }
    );
}
```

GNU Helloのソースコード（tarball）をダウンロードします。展開する必要はありません。

```bash :helloのソースコードを取得
# wgetがない場合はnix shellで一時的に取得しよう
# 便利！
$ nix shell nixpkgs#wget

# 北陸先端科学技術大学院大学のミラーサイトからダウンロード
$ wget https://ftp.jaist.ac.jp/pub/GNU/hello/hello-2.12.tar.gz

$ ls
flake.nix  hello-2.12.tar.gz
```

いよいよビルド式を書いていきます。

stdenvは通常のパッケージと同様にNixpkgsのlegacyPackagesから提供されています。
`stdenv.mkDerivation`関数はAttrSetを引数に取ります。パッケージ名とソースコードを指定しましょう。

```diff nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
-     { }
+     {
+       packages = {
+         hello = pkgs.stdenv.mkDerivation {
+           pname = "hello";
+           version = "2.12";
+         };
+       };
+     }
    );
}
```

これでNix式は完成です。ビルドして実行してみましょう！

```bash
$ nix build .#hello

$ ls result
bin/ share/

$ ./result/bin/hello
Hello, world!
```

成功です！

## mkDerivation関数

前述の例ではビルドスクリプトを一切書かずにビルドすることができました。これはmkDerivation関数のデフォルト値として、典型的なUNIXパッケージを自動でビルドする設定が適用されているためです。GNUが提供しているような`make`をビルドツールとして利用するようなパッケージは多くの場合ビルドスクリプトを書く必要がありません。もちろん、mkDerivationは汎用的なビルド用関数なので、そうでない場合はデフォルト値を上書きして使用します。

### 環境変数

<!-- TODO -->

TODO!

### name/pname/version

`pname`にはパッケージ名、`version`にはバージョンを指定します。`name`はデフォルトでは`${pname}-${version}`となっています。

### src

`src`にはソースコードのディレクトリ、またはアーカイブ（tarball）のストアパスを指定します。今回はtarballのPathを渡しました。

ここで指定したソースコードは`$src`経由でビルドスクリプトから参照できます。

### buildInputsとnativeBuildInputs

今回はstdenvにデフォルトで内包されているgccやmakeで事足りるので、特に依存パッケージを導入しませんでしたが、もし必要なパッケージがあれば`buildInputs`または`nativeBuildInputs`に追加します。

`nativeBuildInputs`にはビルド時依存、`buildInputs`には実行時依存を追加します。前述のstdenvにデフォルトで内包されているパッケージは`nativeBuildInputs`に含まれています。

### Phase

stdenvでビルドを実行すると、まずは`setup`シェルスクリプトによってビルド環境が構築され、その後に`genericBuild`というbash関数が呼び出されます。`genericBuild`は、`buildCommandPath`または`buildCommand`、そして複数の**Phase**を実行します。

stdenvはビルドを複数のステップに分けています。

- Controlling phase
- Unpack phase
- Patch phase
- Configure phase
- Build phase
- Check phase
- Install phase
- Fixup phase

前述のGNU Helloのビルドでは、ビルドスクリプトを一切書かずにビルドすることができました。これは各phaseのデフォルト値として、典型的なUNIXパッケージのビルド設定が適用されているためです。GNU Helloのような`make`をビルドツールとして利用するパッケージは、大まかに以下の手順でビルドされます。

1. ソースコードのtarballを展開（unpack phase）
2. `make`を実行してビルド（build phase）
3. `make install`を実行して所定の場所にビルド成果物を配置（install phase）

:::details Phaseのデフォルト設定

各phaseのデフォルトのスクリプトは、[nixpkgs/pkgs/stdenv/generic/setup.sh](https://github.com/NixOS/nixpkgs/blob/e1d92cda6fd1bcec60e4938ce92fcee619eea793/pkgs/stdenv/generic/setup.sh)内でbash関数として定義されています。この`setup.sh`はstdenvをrealiseした際にストアオブジェクト`setup`として配置されます。

以下はunpack phaseのデフォルトスクリプトである`unpackPhase`関数です。
https://github.com/NixOS/nixpkgs/blob/e1d92cda6fd1bcec60e4938ce92fcee619eea793/pkgs/stdenv/generic/setup.sh#L1167-L1243

:::

もちろん、stdenvは上記の手順を踏まないパッケージもビルドできます。その場合は各phaseを独自のビルドスクリプトで上書きして利用します。

ここではいくかの重要なphaseをピックアップして説明します。他のphaseについては公式マニュアルを参照してください。

https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases

#### Unpack phase

`src`（`$src`）に与えられたストアパスがアーカイブだった場合、unpack phaseで展開されます。アーカイブではなく通常のディレクトリだった場合は展開処理はスキップされます。

```bash :GNU Helloのアーカイブを展開する
$ tar -xzf hello-2.12.tar.gz
```

```diff nix :展開済みのソースコードを指定
stdenv.mkDerivation {
  name = "hello";
- src = ./hello-2.12.tar.gz;
+ src = ./hello-2.12;
}
```

`$src`または`$src`を展開したものがstdenvにおける初期位置のディレクトリになります。

Unpack phaseは上書きする必要がほとんどないので大抵はデフォルトのままです。

#### Build phase

最も上書きする機会が多いのがbuild phaseです。自分でビルドスクリプトを書く場合はこのphaseを上書きします。

```diff nix :Build phaseの上書き
stdenv.mkDerivation {
  name = "hello";
  src = ./hello-2.12.tar.gz;
+ buildPhase = ''
+   make
+ '';
}
```

#### Check phase

Check phaseでは主にテストを実行します。

#### Install phase

Build phaseでビルドした成果物をNixストアに配置する処理を記述します。1つ注意点として、`$out`は自動では作成されないので、スクリプトから`$out`ディレクトリを作成したり`$out`に直接ファイルをコピーしたりしないといけません。

デフォルトでは`install`が実行されますが、ここでは`cp`を使って素朴にビルド成果物をコピーするように変更してみましょう。

```diff nix :Install phaseの上書き
stdenv.mkDerivation {
  name = "hello";
  src = ./hello-2.12.tar.gz;
+ installPhase = ''
+   mkdir -p $out/bin
+   cp hello $out/bin
+ '';
}
```

```bash :ビルドの実行
$ nix build .#hello

# treeコマンドでresultの構造を確認
$ nix run nixpkgs#tree -- result
result
└── bin
    └── hello
```

この例では実行可能ファイル`hello`のみを`$out/bin`にコピーするように変更したので、`result`に`share`が含まれていません。

### Phaseの分離は必要なのか？

Phaseの分離は機能的な制約によるものではないので、例えばbuild phaseでソースコードの展開からビルド、インストールに至るまでの全ての処理を行ってしまうことも可能です。実際、個人利用のパッケージではそのような書き方をしている人もいます。

Phaseが複数に分離されているのは、ビルドワークフローを再利用可能にするためです。例えば、アーカイブの展開処理は多くのパッケージで共通して行われますが、それ以降の流れは大きく異なるので、unpack phaseとして展開処理の部分を分離しておけば再利用できます。

また、Nixpkgsから提供されているパッケージは`overrideAttrs`などの関数でmkDerivationの設定を上書きすることができます。以下のコードでは、Nixpkgsが提供する`hello`の`installPhase`を先程紹介した例と同じになるように上書きしています。

```nix :helloのinstallPhaseを上書きする
pkgs.hello.overrideAttrs {
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin
  '';
};
```

Phaseが分離されているおかげで最低限の変更で済みます。
パッケージの再利用性を考えるならきちんとphaseを分離しておいた方が良いでしょう。基本的にbuild phaseとinstall phaseの分離を意識していれば十分です。

## インターネットアクセスの問題

先程の`hello`のビルドでは、一度wgetでソースコードをローカルにダウンロードしてから`src`に指定していましたが、ソースコードの取得処理もビルド式に含めた方がよりスマートでしょう。

`nativeBuildInputs`に`wget`を追加し、`unpackPhase`でソースコードを取得するように変更します。

```diff nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
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
-           src = ./hello-2.12.tar.gz;
+           nativeBuildInputs = with pkgs; [ wget ];
+           unpackPhase = ''
+             wget https://ftp.gnu.org/gnu/hello/hello-2.12.tar.gz
+             tar -xvf hello-2.12.tar.gz
+             cd hello-2.12
+           '';
          };
        };
      }
    );
}
```

ビルドしてみます。

```bash :ビルドの実行とwgetのエラー
❯ nix build .#hello
error: builder for '/nix/store/a903fx91awgp0lk3a5lwqxbr0imi357y-hello-2.12.drv' failed with exit code 4;
       last 4 log lines:
       > Running phase: unpackPhase
       > --2024-08-17 08:33:20--  https://ftp.gnu.org/gnu/hello/hello-2.12.tar.gz
       > Resolving ftp.gnu.org (ftp.gnu.org)... failed: Temporary failure in name resolution.
       > wget: unable to resolve host address 'ftp.gnu.org'
       For full logs, run 'nix log /nix/store/a903fx91awgp0lk3a5lwqxbr0imi357y-hello-2.12.drv'.
```

なんと失敗してしまいました。wgetのエラーメッセージを見ると、名前解決に失敗していることがわかります。

> --2024-08-17 08:33:20-- https://ftp.gnu.org/gnu/hello/hello-2.12.tar.gz
> Resolving ftp.gnu.org (ftp.gnu.org)... failed: Temporary failure in name resolution.
> wget: unable to resolve host address 'ftp.gnu.org'

Nixのビルド環境はサンドボックス化されているため、インターネットへアクセスすることができません。そのため、ビルドスクリプトからインターネット上のリソースを取得できないのです。これは非常に困ります。特に独自のパッケージマネージャを持つ言語にとってはパッケージの依存関係の解決が不可能になるため致命的な問題です。

もちろん、Nixはこの問題を解決するための仕組みを提供しています。次のセクションでは、冪等性を保ちながらインターネットアクセスを可能にする機構・**Fetcher**について学びます。

## 参照

https://nixos.org/guides/nix-pills/19-fundamentals-of-stdenv

https://nixos.org/manual/nixpkgs/stable/#part-stdenv
