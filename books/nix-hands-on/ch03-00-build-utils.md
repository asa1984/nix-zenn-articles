---
title: "第3部: ビルドユーティリティ"
---

Nix言語でパッケージをビルドする仕組みを学びましたが、derivation関数はプリミティブすぎて実用的ではありません。実際にビルドを行う際は**Nixpkgs**が提供するビルドユーティリティを使います。

[NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)は、公式が提供しているFlakeです。Nixpkgsは9万近いパッケージを提供する巨大なパッケージリポジトリであると同時に、Nix言語の標準ライブラリでもあります。概要は以下の解説をご覧ください。

https://zenn.dev/asa1984/books/nix-introduction/viewer/10-nixpkgs

今回はより踏み込んでNixpkgsが提供する以下の3つを見ていきます。

- Nixpkgs libs
- Standard environment
- ビルドヘルパー
