---
title: "　§1. helloのビルド"
---

いつまで`Hello, world!`するんだと思ったあなたへ、こんにちは！
この本は入門書なので最後までハローワールドします。挨拶は大事ですからね。

と言っても、ここに至るまでの間に何度もGNU Helloをビルドしてきました。今回は、FlakeをGit込みでセットアップし、一から自作の`hello`をNixパッケージ化します。プログラムの作成からビルドまでの一連の流れを確認しましょう。

## 1. Flakeのセットアップ

```bash :Flakeの作成
nix flake new hello-nix
```

コマンドを実行すると`hello-nix/`ディレクトリが作成され、その中に以下の`flake.nix`が配置されます。

```nix :flake.nix
{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

  };
}
```

## 2. inputsの導入

初期のinputsには`github:nixos/nixpkgs?ref=nixos-unstable`（`github:nixos/nixpkgs/nixos-unstable`と等価）が設定されていますが、今回作るパッケージはNixOS以外のシステムでも利用したいので、nixpkgs-unstableを使います。また、flake-utilsで複数のプラットフォームに対応します。

```diff nix :flake.nix
{
- description = "A very basic flake";
+ description = "hello package written in Rust";

  inputs = {
-   nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
+   nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
+   flake-utils.url = "github:numtide/flake-utils";
  };

- outputs = { self, nixpkgs }: {
-
-   packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
-
-   packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
-
- };
+ outputs =
+   { nixpkgs, flake-utils, ... }:
+   flake-utils.lib.eachDefaultSystem (
+     system:
+     let
+       pkgs = nixpkgs.legacyPackages.${system};
+     in
+     {
+       packages = {
+         hello = pkgs.hello;
+         default = pkgs.hello;
+       };
+     }
+   );
}
```

今は初期状態と同じくNixpkgsのGNU Helloをエクスポートしていますが、これから私たち`hello`に置き換えていきます。

## 3. helloを作る

今のコードはただNixpkgsが提供するGNU Helloを再エクスポートしているだけなので、自作の`hello`に置き換えましょう。前回と同じではつまらないので、今回はRustで書きます。

```bash :helloの作成
mkdir src
touch ./src/hello.c
```

```rust :src/hello.rs
fn main() {
    println!("Hello, world!");
}
```

ここで親切なRustaceanは「Hey you! Cargo（Rustのプロジェクト管理ツール）を使いなよ！」とアドバイスをくれると思いますが、諸事情により今回はrustc（Rustコンパイラ）のみを使います。

mkDerivationでビルド式を書きます。

```diff nix :flake.nix
{
  description = # (略)

  inputs = # (略)

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
+       hello = pkgs.stdenv.mkDerivation {
+         pname = "hello";
+         version = "0.0.1";
+         src = ./src;
+         nativeBuildInputs = with pkgs; [ rustc ];
+         buildPhase = ''
+           rustc ./hello.rs
+         '';
+         installPhase = ''
+           mkdir -p $out/bin
+           cp ./hello $out/bin/hello
+         '';
+       };
      in
      {
        packages = {
-         hello = pkgs.hello;
-         default = pkgs.hello;
+         inherit hello;
+         default = hello;
        };
      }
    );
}
```

`nativeBuildInputs`でビルド環境にrustcを導入し、`buildPhase`でコンパイルします。生成された実行ファイルは`installPhase`で`$out/bin`にコピーします。

`nix run`で実行しましょう。

```bash :実行
$ nix run
# エラー発生！
```

「ファイルがないぞ！」というエラーが発生しました。今回はFlakeをGitリポジトリ化したため、NixはGit経由でファイルを探しますが、まだ追加したファイルをステージしていないのでエラーが発生します。`git add`してから`nix run`しましょう。

```bash :ステージしてから実行
$ git add .

$ nix run
Hello, world!
```

## 4. リファクタリング

今回のような小さなプロジェクトなら`fleke.nix`1つで十分ですが、大きなプロジェクトなら`flake.nix`に記述する内容は最小限に留めた方がいいので、ファイル分割してみましょう。また、パッケージのメタ情報が不足しているのでmkDerivationに設定を追加します。

リファクタリングに入る前にコミットしておきます。

```bash :コミットしておく
git commit --message="add hello-rs"
```

### 5.1. ファイル分割

`import`を使ってもいいですが、ここはNixpkgsが採用している**callPackageパターン**^[[Callpackage Design Patter - Nix Pills](https://nixos.org/guides/nix-pills/13-callpackage-design-pattern)]を用います。`nix/`ディレクトリを作り、`flake.nix`に記述していたビルド式を`nix/hello.nix`に移します。

```nix :nix/hello.nix
{ stdenv, rustc }:
stdenv.mkDerivation {
  pname = "hello";
  version = "0.0.1";

  src = ../src; # 注意！nix/hello-rs.nixから見たsrc/への相対パス
  nativeBuildInputs = [ rustc ];
  buildPhase = ''
    rustc ./hello.rs
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./hello $out/bin/hello
  '';
}
```

`pkgs.callPackage`で`nix/hello.nix`をインポートします。

```diff nix :flake.nix
{
  description = # (略)

  inputs = # (略)

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
-       hello = # (略)
      in
      {
        packages = {
-         inherit hello;
-         default = hello;
+         hello = pkgs.callPackage ./nix/hello.nix { };
+         default = pkgs.callPackage ./nix/hello.nix { };
        };
      }
    );
}
```

実行して同じ結果が得られることを確認してください。

```bash :実行して確認
# nix/hello.nixを追加したのでステージング
$ git add .

$ nix run
Hello, world!
```

`callPackage`関数はPathとAttrSetを引数に取り、Pathで指定されたNixファイルの関数に`pkgs`を渡します。[_1.1. Nix言語の基本_](ch01-01-nix-lang-basics)で扱ったように、AttrSetを引数にとる関数は受け取ったAttrSetからattributeを取り出して記述できるので、前述の`hello.nix`では`{ stdenv, rustc }`というように`pkgs.stdenv`と`pkgs.rustc`を取り出しています。
また、今回は`callPackage`の第二引数として空のAttrSetを渡していますが、このAttrSetは`pkgs`にマージされます。つまり、正確には`pkgs // {}`が`hello.nix`に与えられます。

```:callPackageの望ましい型
callPackage :: Path -> AttrSet -> Derivation
```

### 5.2. meta attributeの追加

mkDerivationでは`meta`というattributeで詳細なメタ情報を設定できます。

```diff nix :nix/hello.nix
-{ stdenv, rustc }:
+{
+  stdenv,
+  rustc,
+  lib,
+}:
stdenv.mkDerivation {
  pname = "hello";
  version = "0.0.1";

  src = ../src; # 注意！nix/hello-rs.nixから見たsrc/への相対パス
  nativeBuildInputs = [ rustc ];
  buildPhase = ''
    rustc ./hello.rs
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp ./hello $out/bin/hello
  '';

+ meta = {
+   mainProgram = "hello";
+   description = "A hello world program written in Rust";
+   longDescription = ''
+     This is a demo package for the Nix-Hands-On, which is a hello world program written in Rust.
+   '';
+   license = lib.licenses.mit;
+   platforms = lib.platforms.all;
+ };
}
```

#### mainProgram

`mainProgram`は`nix run`で実行されるプログラムを指します。複数の実行可能ファイルを含むパッケージやパッケージ名と実行可能ファイルの名前が異なるパッケージで利用します。`nix run`はデフォルトでは`<ストアパス>/bin/<pname>`を実行します。

#### descriptionとlongDescription

`description`/`longDescription`に記述された説明は[search.nixos.org](https://search.nixos.org/)で表示されます。
また、`description`は、`nix search <flake-url> <検索ワード>`による検索の対象になります。

```bash :descriptionを利用した検索
# "rust"はパッケージ名には含まれないが、descriptionには含まれるためヒットする
❯ nix search . rust
* packages.x86_64-linux.default (0.0.1)
  A hello world program written in **Rust**

* packages.x86_64-linux.hello (0.0.1)
  A hello world program written in **Rust**
```

#### license

`license`にはパッケージのライセンスを指定します。`lib.licenses`は様々なライセンスを収録したAttrSetで、[nixpkgs/lib/licenses.nix](https://github.com/NixOS/nixpkgs/blob/master/lib/licenses.nix)で定義されています。`meta.license`にunfreeとしてマークされているライセンスを指定すると、デフォルト設定では評価時にエラーが発生します。

```nix :Unfreeなライセンスを指定する
# 非営利・改変禁止なライセンスを指定
# https://creativecommons.org/licenses/by-nc-nd/4.0/deed.ja
license = lib.licenses.cc-by-nc-40;
```

```bash :Unfreeパッケージを評価
$ nix run
# エラー発生！
```

`$NIXPKGS_ALLOW_UNFREE`環境変数を設定したり、Nixpkgsをインポートするときに`allowUnfree = true`を指定することで、unfreeなライセンスのパッケージの評価を許可できます。

```bash
# Nix言語の非純粋な関数（getEnv）で環境変数を読み取るため、--impureオプションを付ける
$ NIXPKGS_ALLOW_UNFREE=1 nix run --impure
Hello, world!
```

```nix :Nixpkgsのインポート時にallowUnfreeを指定
pkgs = import nixpkgs {
  inherit system;
  config = {
    allowUnfree = true;
  };
};
```

#### platforms

`platforms`はパッケージがサポートするプラットフォームをListで指定します。[nixpkgs/lib/systems/doubles.nix](https://github.com/NixOS/nixpkgs/blob/master/lib/systems/doubles.nix)で定義されており、主に以下の区分でプラットフォームを指定できます。

- OS（Linux, Darwin, Windows, FreeBSD, Cygwin, UNIXなど）
- CPUアーキテクチャ（x86, ARM, RISC-Vなど）
- etc...

`platforms`で指定されていないプラットフォームでパッケージを評価しようとするとエラーが発生します。例えば、`platforms`に`lib.platforms.darwin`（macOS）のみを指定し、Linuxで評価しようとするとエラーが発生します。

```bash :macOSのみをサポートする
platforms = lib.platforms.darwin;
```

今回はクロスプラットフォームなパッケージなので、`lib.platforms.all`を指定しています。

#### その他のattribute

基本的に`meta`の情報はNixpkgsで利用されるものなので、これ以上は省略します。その他のattributeや詳細については以下の公式マニュアルを参照してください。

https://nixos.org/manual/nixpkgs/stable/#sec-standard-meta-attributes
