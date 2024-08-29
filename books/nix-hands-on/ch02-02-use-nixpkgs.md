---
title: "　§2. Nixpkgsを使う"
---

[Nixpkgs](https://github.com/NixOS/nixpkgs)は、Nixの公式パッケージリポジトリです。約9万個のパッケージのビルド式を提供しており、Nixを利用する際はほぼ必ずNixpkgsを利用することになります。

また、Nixpkgsはパッケージ以外にも、Nix言語の組み込み関数を拡張したライブラリや「第3部: ビルドユーティリティ」で解説するビルド用関数も一緒に提供しており、Nix言語の標準ライブラリのような役割も果たしています。詳しくは『Nix入門』の[Chapter 10 Nixpkgs](https://zenn.dev/asa1984/books/nix-introduction/viewer/10-nixpkgs)を参照してください。

ここではNixpkgsの利用方法を説明します。

## Nixpkgsのブランチ

本書ではnixpkgs-unstableを利用します。

- nixos-xx.yy
  - LTS
  - 執筆時点ではnixos-24.05が最新
- nixpkgs-unstable
  - ローリングリリース
  - いくつかのテストをパスした更新が適用される
- nixos-unstable
  - ローリングリリース
  - NixOS用のテストを通過した更新が適用される
- master
  - 最も新しいブランチ
  - テストされていない
  - 利用するべきではない

## Nixpkgsの導入

Nixpkgsを導入し、`hello`を再エクスポートしてみます。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      # 自分のシステムに合わせて変更してください
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        hello = pkgs.hello;
      };
    };
}
```

ちゃんとエクスポートできていたらOKです。

```bash
# outputsの確認
$ nix flake show
path:/path/to/flake?lastModified=<最終変更日時>&narHash=<ハッシュ>
└───packages
    └───x86_64-linux
        └───hello: package 'hello-2.12.1'

# 実行してみる
$ nix run .#hello
Hello, world!
```

### pkgs

`pkgs`という変数に`nixpkgs.legacyPackages.<プラットフォーム>`を束縛して使い回すのが慣習です。`pkgs.<パッケージ名>`でNixpkgsのパッケージを参照できます。[search.nixos.org](https://search.nixos.org/packages)で検索して必要なパッケージを指定してください。

## 複数のプラットフォームに対応する

今のところ私たちのFlakeは`x86_64-linux`用のパッケージしかエクスポートしていません。`aaarch64-linux`や`aarch64-darwin`からも利用できるように複数のプラットフォームに対応させたいのですが、わざわざ`packages.aarch64-linux.hello`や`packages.aarch64-darwin.hello`と書くのは冗長なので、`flake.nix`の記述を簡潔にするためのユーティリティ関数を使いましょう。

### flake-utilsを使う

flake-utilsは、Flake関連のユーティリティ関数を提供しているFlakeで、今回は`eachDefaultSystem`関数を使います。

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
      {
        packages = {
          hello = pkgs.hello;
        };
      }
    );
}
```

outputsでプラットフォームをベタ書きする必要がなくなりました。`eachDefaultSystem`には文字列を引数に取り、AttrSetを返す関数を渡します。その関数の引数（上の例では`system`）にはプラットフォーム名が渡されます。

```:eachDefaultSystemの型
eachDefaultSystem :: (String -> AttrSet) -> AttrSet
```

outputsを確認すると、複数のプラットフォーム向けにパッケージがエクスポートされていることがわかります。

```bash
# outputsの確認
$ nix flake show
path:/path/to/flake?lastModified=<最終変更日時>&narHash=<ハッシュ>
└───packages
    ├───aarch64-darwin
    │   └───hello omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   └───hello omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   └───hello omitted (use '--all-systems' to show)
    └───x86_64-linux
        └───hello: package 'hello-2.12.1'
```

Intel/AMD/ARMのLinux、Intel/AppleシリコンのmacOS向けに`hello`パッケージがエクスポートされています。前述のプラットフォーム以外にも対応したい場合は`eachSystem`関数などを使うといいでしょう。

:::message
`eachDefaultSystem`関数を使っても各プラットフォームで本当にビルドできるかどうかは保証されません。あくまでFlakeの構造を簡潔に記述するためのユーティリティ関数です。
:::

### ユーティリティ関数の自作

flake-utilsは依存ゼロのFlakeなので、全ての関数がNix言語の組み込み関数のみで実装されています。

```nix :eachDefaultSystemの実装
# 一部省略している
{
  defaultSystems = [
    "aarch64-darwin" # 64-bit ARM macOS
    "aarch64-linux" # 64-bit ARM Linux
    "x86_64-darwin" # 64-bit x86 macOS
    "x86_64-linux" # 64-bit x86 Linux
  ];


  eachSystem =
    systems: f:
    let
      op =
        attrs: system:
        let
          ret = f system;
          op =
            attrs: key:
            attrs
            // {
              ${key} = (attrs.${key} or { }) // {
                ${system} = ret.${key};
              };
            };
        in
        builtins.foldl' op attrs (builtins.attrNames ret);
    in
    builtins.foldl' op { } systems;

  eachDefaultSystem = eachSystem defaultSystems;
}
```

……Nix言語に慣れていない人には難しいかもしれません。

[Nixpkgs lib](https://nixos.org/manual/nixpkgs/stable/#id-1.4)を利用すればより短いコードで似たような関数を実装できます。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      supportSystems = [
        "aarch64-darwin" # 64-bit ARM macOS
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit x86 macOS
        "x86_64-linux" # 64-bit x86 Linux
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          hello = pkgs.hello;
        }
      );
    };
}
```

`eachDefaultSystem`と違って、outputsの各attributeごとに`forAllSystems`を使用する必要がありますが、概ね同じことができます。

ポイントは[`nixpkg.lib.genAttrs`](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.attrsets.genAttrs)です。Nixpkgsはパッケージだけでなく、Nix言語のライブラリも提供しています。

```:genAttrsの型
genAttrs :: [ String ] -> (String -> Any) -> AttrSet
```

### どれを使うべきか？

一番よく見かけるのはflake-utilsですが、自前の関数を用意している人も多いです。

また、[flake-parts](https://github.com/hercules-ci/flake-parts)というflake-utilsよりも高機能なライブラリもあります。

https://github.com/hercules-ci/flake-parts

https://flake.parts

本書では最も簡潔に記述できるflake-utilsを利用することにします。
