---
title: まとめ
---

解説は以上です。お疲れ様でした。

ここまで読み切った方なら、本書冒頭で提示した以下の内容を自分で説明できるはずです。

1. 純粋関数的ビルドシステム
2. Nixストアによるパッケージと依存関係の厳密な管理
3. Nix言語とFlakesによる宣言的ビルド
4. Profilesによる非破壊的パッケージ構成管理

最後にちょっとだけ豆知識をお伝えします。『Nix』はラテン語で『雪』を意味する単語です。Nixのロゴは雪の結晶のような見た目をしていますが、よく見ると純粋関数型言語の基礎となっている計算モデル、ラムダ計算のλ（ラムダ）が6つ組み合わさってできています。かっこいいですね。

![Nixのロゴ](https://raw.githubusercontent.com/NixOS/nixos-artwork/35ebbbf01c3119005ed180726c388a01d4d1100c/logo/nix-snowflake.svg)
_豆知識: Nixのロゴは非常に鋭いため、緊急時は武器になる_

## 次のステップ

恐らく多くの方が実際に手を動かして学べるNixのチュートリアルを求めていることでしょう。

最もおすすめのチュートリアルは、Determinate Systems社の[Zero to Nix](https://zero-to-nix.com)です。Zero to NixはNixのインストールから始まり、CLIの使い方やパッケージのビルド方法を学ぶハンズオン形式のチュートリアルです。

https://zero-to-nix.com

また、本書の後編にあたるチュートリアル本『Nix入門: ハンズオン編』を現在執筆中です。公開日は未定ですが、Zero to Nixの日本語版のような内容になる予定です。

Nixの内部の理解を深めたいなら、[Nix Reference Manual](https://nixos.org/manual/nix/stable/)を読むといいでしょう。本書の大部分はこのドキュメントを参照しています。

https://nixos.org/manual/nix/stable/

さらに踏み込んでNixの理論的背景を知りたいなら、Dolstra先生の論文[_The Purely Functional Software Deployment Model_](https://edolstra.github.io/pubs/phd-thesis.pdf)を読んでください。

https://edolstra.github.io/pubs/phd-thesis.pdf

また、Nixから発展してNixOSに興味があるという方には、ryan4yjn先生の[NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world)がおすすめです。

https://nixos-and-flakes.thiscute.world

## 最後に

当たり前のことですが、この世に完璧なソフトウェアは存在しません。Nixにも改善の余地は残されています。しかし、未来の開発/ビルド/デプロイが、Nixがコンセプトとして掲げている再現性・宣言的・信頼性の性質を備えているべきだという主張には、全ての開発者が同意することだと思います。Nixは手段の1つに過ぎないかもしれませんが、向かうところは皆同じです。

本書を読んでNixを使ってみようと思った方、別に使わなくてもいいなと思った方、そしてNixコミュニティの方々、あらゆる開発者と共に健全なソフトウェア開発の未来を作っていけたら嬉しいです。

最後まで本書を読んでいただきありがとうございます！
