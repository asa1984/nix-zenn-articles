---
title: "　§4. Overlays"
---

## Overlays

**Overlays**という仕組みを利用することでNixpkgsを拡張・上書きすることができます。Nixpkgsにパッチを適用したり、新しいパッケージを追加したりできます。

OverlayはFlakeのoutputsの`overlays` attributeからエクスポートされます。

```nix :Flakeのoutputs
overlays.<overlayの名前> = final: prev: #...
```

### Overlayを使ってみる

例として[NUR](https://github.com/nix-community/NUR)を使ってみます。NUR（Nix User Repository）はコミュニティ駆動のパッケージリポジトリで、4000近いパッケージを公開しています。NUR本体ではメンテナンスやレビューを行っておらず、ユーザーが自身のリポジトリをNURに紐付け、NURがそれを定期的に同期するという仕組みになっています（面白いことに[Mozilla](https://github.com/mozilla/nixpkgs-mozilla)もリポジトリを登録しています）。

https://nur.nix-community.org

これまでは`nixpkgs.legacyPackages.${system}`という形でNixpkgsのパッケージを参照していましたが、overlayを利用する場合は`import nixpkgs`を使います。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nur.url = "github:nix-community/NUR";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      nur,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # `nur.overlays.<overlayの名前>`ではなく`nur.overlay`
        # `outputs.overlay`は現在非推奨だが恐らく後方互換性のために残されている
        overlays = [ nur.overlay ];
        pkgs = import nixpkgs { inherit system overlays; };
      in
      {
        packages = {
          default = pkgs.nur.repos.mic92.hello-nur;
        };
      }
    );
}
```

NURをoverlayとして追加すると、`pkgs.nur`からNURのパッケージを参照できるようになります。この`flake.nix`ではNURのメンテナーである[Mic92](https://github.com/Mic92)氏が提供している`hello-nur`を再エクスポートしています。実行してみましょう。

```bash :hello-nurの実行
$ nix run
Hello, NUR!
```

他にも様々なoverlayが存在するので、興味があれば調べてみてください。
