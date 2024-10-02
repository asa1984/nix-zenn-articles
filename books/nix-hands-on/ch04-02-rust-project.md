---
title: "　§2. Rustプロジェクトのビルド"
---

通常、Rustのプロジェクト（クレート）はCargoで管理します。今回は、Nixpkgsが提供しているRust用ビルドユーティリティを使ってクレートをNixパッケージ化します。

## devShellの用意

Rustには[rustup](https://github.com/rust-lang/rustup)という優れたツールがあり、通常はこれを使ってRustのツールチェーンを管理しますが、今回はNixのdevShellを用いて宣言的にツールチェーン管理を行います。

### Rustツールチェーンの管理

では、Nixpkgsから`rustc`や`cargo`をインストールして……といきたいところですが、Nixpkgsから直接Rustツールチェーンをインストールするのは実用的ではありません。というのもNixpkgsがメンテナンスしているRustのバージョンは最新の安定板のみであり、過去のバージョンを取得しようとするとNixpkgsのコミットを遡らなければならず、nightlyは提供されていません。また、rustupを経由しないため、コンパイルターゲットを追加（例: WASMをターゲットに追加）することができません。

そこで[rust-overlay](https://github.com/oxalica/rust-overlay)を利用します。rust-overlayはRustツールチェーンのoverlayを提供しているFlakeで、ツールチェーンのバージョン指定やコンパイルターゲットの追加が可能です。

https://github.com/oxalica/rust-overlay

rust-overlay以外にもRustツールチェーンを提供するFlakeはいくつか存在し、[fenix](https://github.com/nix-community/fenix)はrust-overlayと並んでよく利用されています。fenixはrust-analyzerも提供しています。

https://github.com/nix-community/fenix

:::details nixpkgs-mozilla
実は、Mozilla公式も[nixpkgs-mozilla](https://github.com/mozilla/nixpkgs-mozilla)というFlakeからRustのoverlayを提供しているのですが、上記のFlakeはnixpkgs-mozillaの代替を目的として提供されているため、nixpkgs-mozillaをRustのために利用するのは推奨されていないようです。
:::

### devShellの設定

devShellを設定します。

```bash :ディレクトリの作成
mkdir rust-with-nix
cd rust-with-nix
touch flake.nix
```

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.rust-bin.stable.latest.default
          ];
        };
      }
    );
}
```

rust-overlayをinputsに追加する際、`inputs.nixpkgs.follow`というオプションを指定しています。rust-overlayはNixpkgsに依存しているため、素朴に導入すると「私たちのFlakeのinputsのNixpkgs」と「rust-overlayのinputsのNixpkgs」で2つのバージョンのNixpkgsが存在することになります。依存関係の整合性という観点では分離されている方が望ましいですが、その分ストレージを多く消費します。今回はrust-overlayが依存しているNixpkgsを私たちが導入したNixpkgsに置き換えています。

Overlayを入れると`pkgs`に`rust-bin`というattributeが追加されます。`nix develop`でdevShellを起動し、`cargo`や`rustc`がインストールされていることが確認できたらOKです。

## 1. 基本的なビルド

### クレートの作成

クレートを初期化します。

```bash :クレートの初期化
$ cargo init

# 実行できることを確認
$ cargo run
Hello, world!
```

### Nixパッケージ化

まずはこのままの状態でNixパッケージ化してみます。

Nixpkgsから提供されている`pkgs.rustPlatform.buildRustPackage`を使います。

```nix :nix/rust-with-nix.nix
{ rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "rust-with-nix";
  version = "0.1.0";

  src = ../.;
  cargoLock.lockFile = ../Cargo.lock;
}
```

```diff nix :flake.nix
 {
   inputs = # ...

   outputs =
     {
       nixpkgs,
       flake-utils,
       rust-overlay,
       ...
     }:
     flake-utils.lib.eachdefaultsystem (
       system:
       let
         pkgs = # ...
       in
       {
         devshells.default = # ...
+        packages.default = pkgs.callPackage ./nix/rust-with-nix.nix { };
       }
     );
 }
```

Nixでビルドして実行できることを確認します。

```bash
$ nix run
Hello, world!
```

### rust-overlayを利用する

`pkgs.rustPlatform`はNixpkgsのCargoやrustcを内部で使用するため、今回私たちがdevShellで利用しているrust-overlayのRustツールチェーンを使うように変更します。

`pkgs.makeRustPlatform`でcargoとrustcをrust-overlayのものに置き換えたrustPlatformを作成します。

```diff nix :nix/rust-with-nix.nix
-{ rustPlatform }:
+{ makeRustPlatform, rust-bin }:
+let
+  toolchain = rust-bin.stable.latest.default;
+  rustPlatform = makeRustPlatform {
+    cargo = toolchain;
+    rustc = toolchain;
+  };
+in
 rustPlatform.buildRustPackage {
   pname = "rust-with-nix";
   version = "0.1.0";

   src = ../.;
   cargoLock.lockFile = ../Cargo.lock;
 }
```

問題なく実行できるはずです。

```bash
$ nix rust
Hello, world!
```

## 2. OpenSSLに依存するクレートのビルド

少し発展的なビルドを行います。[reqwest](https://github.com/seanmonstar/reqwest)というHTTPクライアントライブラリを導入します。

```bash :依存クレートの追加
cargo add reqwest --features=blocking
```

:::details blocking feature
通常、reqwestは非同期ランタイム上で動作します。Rust本体には非同期処理を表現する型や構文などはあるものの、実際にタスクを実行するランタイムはライブラリとして追加しなければなりません。今回はあくまでNixによるビルドの解説なので、`blocking` featureを有効にして、素のRustで同期的に動かせるようにしています。
:::

`main.rs`を以下のように書き換えます。

```rust :src/main.rs
fn main() {
    let url = match std::env::args().nth(1) {
        Some(url) => url,
        None => panic!("No URL provided"), // 引数がない場合は異常終了
    };

    let response = reqwest::blocking::get(&url).unwrap();

    println!("Statu code: {}", response.status());
}
```

引数にURLを受け取って、そのURLにGETリクエストを送り、レスポンスのステータスコードを表示するプログラムです。

`cargo run`で実行してみます。

```bash
$ cargo run https://example.com
# エラー！
# pkg-configまたはOpenSSLが見つからないと怒られる
```

筆者の環境では「pkg-configが見つからないぞ」と怒られてしまいました。しかし、読者の環境によってはビルドに成功するかもしれません。

デフォルトのreqwestはOpenSSLに依存しており、ビルド時にpkg-configを利用してOpenSSLのライブラリを探します。そのため、pkg-configやOpenSSLをインストールしていない環境ではビルドエラーが発生します。これはCargo単体では解決できない依存関係であり、まさしく暗黙的な依存です。

最も簡単で推奨されている解決方法は、reqwestの`rustls-tls` featureを有効化して、OpenSSLの代わりにRust実装のTLSライブラリ[rustls](https://github.com/rustls/rustls)を利用するようにすることです。

ですが今回は敢えてrustlsを使わず、devShellでOpenSSLをインストールしてビルドする方法を試してみます。

### devShellの拡張

devShellにOpenSSLとpkg-configを追加します。

```diff nix :flake.nix
  # ...
  devShells.default = pkgs.mkShell {
-   packages = [
-     pkgs.rust-bin.stable.latest.default
-   ];
+   packages = with pkgs; [
+     openssl
+     pkg-config
+     rust-bin.stable.latest.default
+   ];
  };
  # ...
```

再びdevShellを起動してビルドします。

```bash :devShell内で実行
$ nix develop
$ cargo run https://example.com
Statu code: 200
```

ビルドが成功し、example.comへ送ったリクエストに対するレスポンスのステータスコードが表示されました。

devShellは外部ライブラリを多用する場面に非常で有効的です。グローバルインストールを行わず、プロジェクト単位で依存関係を管理できるため、他のプロジェクトとの依存関係の衝突を気にせずに開発を進めることができます。

### Nixパッケージ化

devShellと同様、ビルド式にも依存関係を追加する必要があります。mkDerivation関数と同様に、`buildInputs`に実行時依存（OpenSSL）、`nativeBuildInputs`にビルド時依存（pkg-config）を追加します。

```diff nix nix/rust-with-nix.nix
-{ makeRustPlatform, rust-bin }:
+{
+  makeRustPlatform,
+  rust-bin,
+  openssl,
+  pkg-config,
+}:
 let
   toolchain = rust-bin.stable.latest.default;
   rustPlatform = makeRustPlatform {
     cargo = toolchain;
     rustc = toolchain;
   };
 in
 rustPlatform.buildRustPackage {
   pname = "rust-with-nix";
   version = "0.1.0";

+  buildInputs = [ openssl ];
+  nativeBuildInputs = [ pkg-config ];

   src = ../.;
   cargoLock.lockFile = ../Cargo.lock;
 }
```

Nixでもビルドできることを確認します。

```bash
$ nix build
$ ./result/bin/rust-with-nix https://example.com
Statu code: 200
```

成功です！

## 内部で何をしているのか？

`pkgs.rustPlatform.buildRustPackage`は、引数としてSHA-256文字列あるいは`Cargo.lock`のPathを受け取り、依存クレートを取得するfetcherに変換します。内部では`pkgs.fetchzip`や`pkgs.fetchurl`を利用して[crates.io](https://crates.io)からクレートのtarballを取得する処理が走っているようです。

依存関係とソースコードの取得が終われば、後は`cargo build`をbuildPhaseで実行してパッケージをビルドします。また、テストが存在する場合はcheckPhaseで`cargo test`が実行されます（`doCheck = false`で無効化可能・テストがネットワークを利用する場合はfalseにするとよい）。

詳細はNixpkgsのRustのビルドに関するドキュメントを参照してください。

@[card](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md)

## Nipxkgs以外のRustのビルドユーティリティ

RustはNixコミュニティでも非常に人気のある言語なので、Nixpkgs以外からも複数のビルドユーティリティが提供されています。筆者の観測範囲では、特に[crane](https://github.com/ipetkov/crane)がよく利用されているようです。

https://github.com/ipetkov/crane
https://github.com/nix-community/naersk
https://github.com/cargo2nix/cargo2nix

## その他の言語のビルド

Rust以外の言語でも、同じようなビルドをサポートする関数が提供されています。Nixpkgsの`/doc/languages-framworks`ディレクトリに各言語のビルドに関するドキュメントが格納されているので、目的の言語のドキュメントを参照してください。

https://github.com/NixOS/nixpkgs/tree/master/doc/languages-frameworks

また、Nixpkgs以外のビルドユーティリティを探すなら[awesome-nix](https://github.com/nix-community/awesome-nix)も役に立つかもしれません。

https://github.com/nix-community/awesome-nix?tab=readme-ov-file#programming-languages
