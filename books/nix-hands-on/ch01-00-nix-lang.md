---
title: "第1部: Nix言語"
---

**Nix言語**に入門しましょう。

## Nix言語の特徴

- ドメイン固有言語
- イミュータブル
- 式指向
- 純粋関数型
- 遅延評価
- 動的型付け

一見いかつい特徴が揃っていますが、実際はとてもシンプルな言語です。

まず、Nix言語は特定の目的（パッケージのビルド定義など）のために設計された言語なので、通常のプログラミング言語ほど汎用的な機能はありません。そのため、関数型言語と一口にいっても、OCamlやHaskellほど高度な言語機能はありません。
Nix言語の使用感はプログラミング言語よりも、JSONやYAMLのような設定記述言語に近いです。ライブラリの作者でもない限り、Nix言語で複雑なプログラムを書くことはほとんどありません。関数を使えてちょっとした計算ができるリッチなJSONと思っていた方がわかりやすいでしょう。

## 必要な知識

純粋関数型言語の経験は不要です。「純粋関数」がどのようなものか知っていれば十分です。
一方、**Nixストア**と**Derivation**についての知識は必須です。Nix言語は当然Nixの機構と密接に結びついているため、これらの知識がないとNix言語の理解が難しくなります。

よく分からないという方は以下の解説に目を通しておいてください。

https://zenn.dev/asa1984/books/nix-introduction/viewer/05-pure-functional-build

https://zenn.dev/asa1984/books/nix-introduction/viewer/06-nix-store

https://zenn.dev/asa1984/books/nix-introduction/viewer/08-derivation

## 【余談】型システム

Nixが歩んできた10年以上の歴史の中で、Nix言語に型システムを導入しようという議論がなかったわけではありません。

NixのGitHubリポジトリには[Static type system](https://github.com/NixOS/nix/issues/14)というclose済みのissueがあります。執筆時点の最新のissueは#11298ですが、なんとこのissueは **#14** であり、2012年にNixの作者である[Eelco Dolstra](https://github.com/edolstra)先生自らが立てています。

> Nix won't be complete until it has static typing.

https://github.com/NixOS/nix/issues/14

そして2018年に[close](https://github.com/NixOS/nix/issues/14#event-1553720064)されています。なぜ閉じたんだという質問に対する先生の回答がこちらです。

> Because it's not realistically going to happen (and I'm cleaning up some backlog issues).

悲しい！

[TAPL第1章](https://www.ohmsha.co.jp/LinkClick.aspx?fileticket=EtTyUXyhRHY%3d&tabid=104&mid=739)でも述べられているように、型システムを持たない言語に後づけで型システムを導入するのは非常に困難なので、これは仕方のないことです。
