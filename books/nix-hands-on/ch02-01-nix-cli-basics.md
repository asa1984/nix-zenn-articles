---
title: "　§1. Nix CLIの基本"
---

## flake-urlのエイリアス

コマンドを打つ度に毎回長いflake-urlを書くのは面倒です。`nix registry`コマンドでflake-urlのエイリアスを設定することができます。

デフォルトでもいくつかのエイリアスが定義されており、例えば`github:NixOS/nixpkgs/nixpkgs-unstable`（Nixpkgsのnixpkgs-unstableブランチ）には`nixpkgs`というエイリアスが割り当てられています。以降、コマンドからNixpkgsを利用するときはこのエイリアスを使っていきます。

:::details デフォルトのエイリアス一覧

公式のFlakeだけでなく、サードパーティのFlakeにもエイリアスが設定されています。

```bash :nix registry list
$ nix registry list
global flake:agda github:agda/agda
global flake:arion github:hercules-ci/arion
global flake:blender-bin github:edolstra/nix-warez?dir=blender
global flake:bundlers github:NixOS/bundlers
global flake:cachix github:cachix/cachix
global flake:composable github:ComposableFi/composable
global flake:disko github:nix-community/disko
global flake:dreampkgs github:nix-community/dreampkgs
global flake:dwarffs github:edolstra/dwarffs
global flake:emacs-overlay github:nix-community/emacs-overlay
global flake:fenix github:nix-community/fenix
global flake:flake-parts github:hercules-ci/flake-parts
global flake:flake-utils github:numtide/flake-utils
global flake:helix github:helix-editor/helix
global flake:hercules-ci-agent github:hercules-ci/hercules-ci-agent
global flake:hercules-ci-effects github:hercules-ci/hercules-ci-effects
global flake:home-manager github:nix-community/home-manager
global flake:hydra github:NixOS/hydra
global flake:mach-nix github:DavHau/mach-nix
global flake:nickel github:tweag/nickel
global flake:nix github:NixOS/nix
global flake:nix-darwin github:LnL7/nix-darwin
global flake:nix-serve github:edolstra/nix-serve
global flake:nixops github:NixOS/nixops
global flake:nixos-hardware github:NixOS/nixos-hardware
global flake:nixos-homepage github:NixOS/nixos-homepage
global flake:nixos-search github:NixOS/nixos-search
global flake:nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable
global flake:nur github:nix-community/NUR
global flake:patchelf github:NixOS/patchelf
global flake:poetry2nix github:nix-community/poetry2nix
global flake:pridefetch github:SpyHoodle/pridefetch
global flake:sops-nix github:Mic92/sops-nix
global flake:systems github:nix-systems/default
global flake:templates github:NixOS/templatesash
```

:::

## Flakeのoutputsとコマンドの対応関係

| output         | 対応するコマンド      |
| -------------- | --------------------- |
| packages       | `nix build`/`nix run` |
| legacyPackages | `nix build`/`nix run` |
| apps           | `nix run`             |
| devShells      | `nix develop`         |
| formatter      | `nix fmt`             |
| checks         | `nix flake check`     |
| templates      | `nix flake init`      |

## nix build

```bash :nix build
# ビルド
nix build <flake-url>#<パッケージ名>
```

```nix :対応するattribute
# パッケージ
packages.<プラットフォーム>.<指定したパッケージ名> = <Derivation>;

# パッケージ（Nixpkgs）
legacyPackages.<プラットフォーム>.<パッケージ名> = <Derivation>;
```

対応するattributeを評価し、生成されたstore derivationをrealiseします。プラットフォームは自動で選択されます。

コマンド実行後、パッケージのストアパスがリンクされた`result`というシンボリックリンクがカレントディレクトリに作成されます。

```bash :GNU Helloをビルド
# x86_64-linuxで実行すると、
# NixpkgsのlegacyPackages.x86_64-linux.helloが評価される
$ nix build nixpkgs#hello

$ readlink result
/nix/store/4prjbnvjp40kkqjds62ywy9sr94j9g4b-hello-2.12.1

$ ls result
bin/ share/
```

## nix run

```bash :nix run
# 実行
nix run <flake-url>#<パッケージ名>
```

```nix :対応するattribute
# パッケージ
packages.<プラットフォーム>.<指定したパッケージ名> = <Derivation>;

# パッケージ（Nixpkgs）
legacyPackages.<プラットフォーム>.<パッケージ名> = <Derivation>;

# apps
apps."<プラットフォーム>"."<app名>" = {
  type = "app";
  program = "<ストアパス>";
};
```

対応するattributeを評価しrealiseするところまでは`nix build`と同じですが、`nix run`は`result`を作成せず、パッケージが提供する実行ファイルを1回だけ実行します。デフォルトでは`<パッケージのストアパス>/bin/<パッケージ名>`を実行します。

また、`nix run`専用のattributeとして`apps`があります。`apps`は`packages`と違って`nix build`からは利用できないので、スクリプトのようなワンショットな処理を定義します^[Node.jsの`package.json`でいう`scripts`です。]。

## nix shell

```bash :nix run
# Nixシェルの起動
nix shell <flake-url>#<パッケージ名>
```

```nix :対応するattribute
# パッケージ
packages.<プラットフォーム>.<指定したパッケージ名> = <Derivation>;

# パッケージ（Nixpkgs）
legacyPackages.<プラットフォーム>.<パッケージ名> = <Derivation>;
```

**Nixシェル**と呼ばれるシェルを起動します。指定したパッケージをビルドし、そのストアパスを直接`PATH`環境変数に追加した新たなシェル（`$SHELL`）を起動します。Ctrl + Dや`exit`でNixシェルを終了すると元に戻ります。

```bash :Nixシェル
$ nix shell nixpkgs#hello

# $PATHにhelloの実行ファイルが一時的に追加される
[Nixシェル]$ hello
Hello, world!

# Nixシェルを終了
[Nixシェル]$ exit

$ hello
hello: command not found
```

一時的にパッケージを導入したいときに便利です。

## nix develop

```nix :devShellsの形式
devShells.${system}.${name} = <Derivation>;
```

```bash :対応するコマンド
nix develop <flake-url>#<name>
```

- nix develop

Nixシェルを宣言的に定義することができます。使い方は後に解説します。

## nix fmt

```bash :nix fmt
nix fmt <flake-url>
```

```nix :formatterの形式
formatter.<プラットフォーム> = <Derivation>;
```

`formatter`に設定されたフォーマッターを実行します。任意のフォーマッターを設定することができます。大抵は以下のNix言語のフォーマッターのいずれかが設定されています。

- [nixfmt](https://github.com/NixOS/nixfmt)
- [alejandra](https://github.com/kamadorueda/alejandra)

また、[treefmt](https://github.com/numtide/treefmt)を用いてNix言語以外のファイルも一括でフォーマットしている場合もあります。

:::details nixfmt-rfc-style
nixfmtにはnixfmt-classicとnixfmt-rfc-styleの2つがあり、本書に登場するNix式は基本的にnixfmt-rfc-styleでフォーマットしています。
元々、nixfmtは公式のフォーマッターではありませんでしたが、2024年に公式のリポジトリに移管されました^[[Transfer to NixOS GitHub organisation #155](https://github.com/NixOS/nixfmt/issues/155)]。現在、[RFC 166](https://github.com/NixOS/rfcs/blob/master/rfcs/0166-nix-formatting.md)準拠のフォーマッターとして実装が進行中です^[[RFC 166 implementation tracking issue #153](https://github.com/NixOS/nixfmt/issues/153)]。まだ安定していないため、nixfmt-rfc-styleはNixpkgsのunstableブランチでのみ提供されています。
:::

## Flakeの操作

### nix flake init/new

```bash
nix flake init
nix flake init --template <flake-url>#<テンプレート名>

nix flake new <ディレクトリ名>
nix flake new <ディレクトリ名> --template <flake-url>#<テンプレート名>
```

```nix :対応するattribute
templates.<テンプレート名> = <テンプレートの設定>;
```

Flakeの初期化/新規作成を行います。デフォルトでは以下の`flake.nix`が作成されます。

:::details デフォルトで作成されるflake.nix

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

:::

`--template`オプションでテンプレートを利用することができます。公式のテンプレートも存在します。

https://github.com/NixOS/templates

```bash :c-helloテンプレートを使う
$ nix flake new c-hello --template github:nixos/templates#c-hello
wrote: /path/to/c-hello/Makefile.in
wrote: /path/to/c-hello/configure.ac
wrote: /path/to/c-hello/flake.nix
wrote: /path/to/c-hello/hello.c
```

### nix flake lock/update

`flake.lock`を生成/アップデートします。

### nix flake show

```bash :nix flake show
nix flake show <flake-url>
```

Flakeの`packages`から出力されているパッケージの一覧を取得します。

### nix flake check

```bash :nix flake check
nix flake check <flake-url>#<チェック名>
```

```nix :対応するattribute
checks.<プラットフォーム>.<チェック名> = <Derivation>;
```

`nix flake check`はFlakeのテストに用いられるコマンドで、対応するderivationをrealiseします。例えば、特定のパッケージがビルド可能かどうか検証するなど、Flakeの正常性を確認するためのチェックを行います。チェック名を指定しなかった場合は全てのチェックを評価します。

## Nixストア

### nix store gc

Nixストアのガベージコレクションを行うコマンドです。どこからも参照されていないストアパスを全て削除します。実質的なアンインストールコマンドです。依存関係を記録しているデータベースを解析して削除するため、時間がかかる場合があります。

### nix store delete

```bash :nix store delete
nix store delete <store-path>
```

指定されたストアパスを削除します。安全な削除を行うため、もし対象のストアパスが他から参照されていた場合は削除されません。`nix store gc`と同様にデータベースを解析するため、削除に時間がかかる場合があります。

## 【余談】NixpkgsのlegacyPackages

Nixpkgsのパッケージは`packages`ではなく、`legacyPackages`というattributeから出力されています。Nixpkgsの`flake.nix`のコメントにも書かれているように、これは「古いパッケージ」という意味ではありません。

https://github.com/NixOS/nixpkgs/blob/78642712b23839a9cbcb9dc654579890019173ed/flake.nix#L84-L92

`nix flake show`のようなパッケージ一覧を取得するコマンドを実行すると、Nixはパッケージのメタ情報を得るために`packages`から出力されている全てのNix式を評価します（ビルドはしません）。しかし、Nixpkgsのパッケージ数はあまりにも多いため、`packages`からパッケージを出力してしまうと、実に9万近いパッケージの評価が走り、とてつもない時間がかかってしまいます。

そこで`legacyPackages`です。デフォルトではNixは`legacyPackages`を無視します。実際にNixpkgsで`nix flake show`を実行すると`legacyPackages`の部分は`omitted`と表示されます。

:::details Nixpkgsでnix flake showを実行した結果

```bash
$ nix flake show nixpkgs
github:NixOS/nixpkgs/<コミットハッシュ>
├───checks
│   ├───aarch64-darwin
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───aarch64-linux
│   │   ├───nixosSystemAcceptsLib omitted (use '--all-systems' to show)
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───armv6l-linux
│   │   ├───nixosSystemAcceptsLib omitted (use '--all-systems' to show)
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───armv7l-linux
│   │   ├───nixosSystemAcceptsLib omitted (use '--all-systems' to show)
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───i686-linux
│   │   ├───nixosSystemAcceptsLib omitted (use '--all-systems' to show)
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───powerpc64le-linux
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───riscv64-linux
│   │   ├───nixosSystemAcceptsLib omitted (use '--all-systems' to show)
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───x86_64-darwin
│   │   └───tarball omitted (use '--all-systems' to show)
│   ├───x86_64-freebsd
│   │   └───tarball omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       ├───nixosSystemAcceptsLib: derivation 'nixos-system-nixos-24.11.20240815.8b90819'
│       └───tarball: derivation 'nixpkgs-tarball-24.11pre20240815.8b90819'
├───devShells
│   ├───aarch64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   ├───aarch64-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───armv6l-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───armv7l-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───i686-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───powerpc64le-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───riscv64-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───x86_64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   ├───x86_64-freebsd
│   │   └───default omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
├───htmlDocs: unknown
├───legacyPackages
│   ├───aarch64-darwin omitted (use '--legacy' to show)
│   ├───aarch64-linux omitted (use '--legacy' to show)
│   ├───armv6l-linux omitted (use '--legacy' to show)
│   ├───armv7l-linux omitted (use '--legacy' to show)
│   ├───i686-linux omitted (use '--legacy' to show)
│   ├───powerpc64le-linux omitted (use '--legacy' to show)
│   ├───riscv64-linux omitted (use '--legacy' to show)
│   ├───x86_64-darwin omitted (use '--legacy' to show)
│   ├───x86_64-freebsd omitted (use '--legacy' to show)
│   └───x86_64-linux omitted (use '--legacy' to show)
├───lib: unknown
└───nixosModules
    ├───notDetected: NixOS module
    └───readOnlyPkgs: NixOS module
```

:::

明示的に`--legacy`オプションを付けると`legacyPackages`の内容が表示されます。

## 【余談】nixpkgs-weekly

Nixpkgsの更新頻度は非常に高いため、コマンドからNixpkgsを利用すると頻繁にダウンロードが走ります。これでは少々ストレスなので、筆者は[FlakeHub](https://flakehub.com)^[Determinate Systemsが提供しているFlake共有プラットフォーム]で公開されている[nixpkgs-weekly](https://flakehub.com/flake/DeterminateSystems/nixpkgs-weekly)を利用しています。nixpkgs-weeklyは、公式のnixpkgs-unstableのスナップショットをとっており、週一で更新されます。`nix registry add`でエイリアスを追加して利用すると便利です。
