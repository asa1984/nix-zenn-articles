---
title: "　§5. Flakeのoutputs"
---

## outputsのスキーマ

技術的には`flake.nix`のoutputsには任意のNix式を記述することができますが、実際は標準のスキーマに則っていることが望ましいです。使い方や詳しい挙動は[_第2部: 実践Nix_](ch02-00-nix-practice)で解説します。

### CLIが利用するattribute

Nixのコマンドの多くは`flake.nix`をエントリーポイントとしてNix式を評価します。その際、コマンドによってoutputsのどのattributeを利用するかが決まっています。

```nix :flake.nixのoutputs
outputs = { ... }:
{
  # `nix build <flake-url>#name`でビルド
  packages."<プラットフォーム>"."<パッケージ名>" = <Derivation>;
  # `nix build <flake-url>`でビルド
  packages."<プラットフォーム>".default = <Derivation>;

  # Nixpkgsで使われているattribute
  # packagesとほぼ同じ
  legacyPackages."<プラットフォーム>"."<パッケージ名>" = <Derivation>;

  # `nix run `<flake-url>#<name>`で実行
  apps."<プラットフォーム>"."<パッケージ名>" = {
    type = "app";
    program = "<ストアパス>";
  };
  # `nix run `<flake-url>`で実行
  apps."<プラットフォーム>".default = <Derivation>;

  # `nix fmt`で実行
  formatter."<プラットフォーム>" = <Derivation>;

  # `nix develop <flake-url>#<name>`でNixシェルを起動
  devShells."<プラットフォーム>"."<name>" = <Derivation>;
  # `nix develop <flake-url>`でNixシェルを起動
  devShells."<プラットフォーム>".default = <Derivation>;

  # `nix flake check`で実行
  checks."<プラットフォーム>"."<name>" = <Derivation>;

  # `nix flake init -t <flake>#<name>`でテンプレートを使う
  templates."<name>" = {
    path = "<ストアパス>";
    description = "templateの説明文";
  };
  # `nix flake init -t <flake>`でテンプレートを使う
  templates.default = ...
}
```

### Nix言語から利用するattribute

Nix言語から`flake.nix`をインポートする際に利用するattributeです。Overlayに関しては、[_2.4. Overlays_](ch02-04-overlays)で解説します。

```nix :flake.nixのoutputs
outputs = { ... }:
{
  # derivation以外の汎用的なNix言語ライブラリ
  # CLIからは利用せず、Nix式としてインポートする
  lib.<name> = <任意のNix式>;

  # Overlay
  # CLIからは利用せず、Nix式としてインポートする
  overlays."<name>" = final: prev: { };
}
```

### Nix以外のツールが利用するattribute

Nix以外のツールが独自のattributeを要求することがあります。

```nix :flake.nixのoutputs
outputs = { ... }:
{
  # NixOS
  ## `sudo nixos-rebuild switch --flake .#<hostname>`でNixOSの設定を適用
  nixosConfigurations."<hostname>" = {};
  ## NixOS module
  nixosModules."<name>" = { config, ... }: { options = {}; config = {}; };

  # home-manager
  ## home-managerの設定
  homeConfigurations = {
    "<ユーザー名@ホスト名>" = ...
  };
  ## home-manager module
  homeManagerModules = # home-managerのモジュール

  # Hydra
  ## Hydraのジョブセット
  hydraJobs."<AttrSet>"."<プラットフォーム>" = derivation;

  # deploy-rs
  deploy.nodes.<name> = # デプロイノード
}
```
