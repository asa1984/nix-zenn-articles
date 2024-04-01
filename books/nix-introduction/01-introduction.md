---
title: "はじめに"
---

## 背景

純粋関数型パッケージマネージャ**Nix**は、非常にユニークなアプローチによって再現性・宣言的・信頼性を実現するツールです。恐らくほとんどの人が聞いたことのないマイナーなパッケージマネージャですが、10年以上の歴史を持つ成熟した技術であり、そのコンセプトと実用性からユーザーから根強い支持を受けています。

最近、日本でも名が知られるようになってきましたが、依然として情報が不足しており学習コストが高い状態が続いています。そこで、Nixについて体系的に学べる日本語の入門資料として本書が執筆されました。

## 目的と対象読者

本書ではNixのコンセプトと仕組みの解説を行います。解説では可能な限り[Nix Reference Manual](https://nixos.org/manual/nix/stable/)の[用語集](https://nixos.org/manual/nix/stable/glossary.html)で定義されている用語を使用し、読了後Nixの公式ドキュメントを問題なく読めるようになることを目指します。

また、本書は以下のような方を読者として想定しています。

- Nixがどういうものなのか知りたい
- Nixの仕組みを知りたい
- 公式ドキュメントで挫折した
- FlakesベースのNixの解説を探している
<!-- - 再現性が高い/宣言的と聞くと興奮する -->

## 本書で扱わないこと

本書では以下の内容については扱いません。

- NixのCLIの使い方
- Nix言語の書き方
- Nixによる具体的なパッケージビルドの方法
- NixOS
- home-manager

本書はあくまでNixの仕組みを解説する資料であり、Nixのチュートリアルではありません。Nixのチュートリアルについては、別の本として『Nix入門: ハンズオン編』を現在執筆中です。公開日は未定です。

今すぐチュートリアルを読みたい方には、Determinate Systems社の[Zero to Nix](https://zero-to-nix.com)というハンズオン形式のチュートリアルをおすすめします。

https://zero-to-nix.com

また、Nixに密接に関わるソフトウェアであるNixOSとhome-managerについても本書の範囲外とします。軽く説明するとNixOSはNixを用いてシステムを宣言的に管理するLinuxディストリビューション、home-managerは宣言的ユーザー環境構築ツールです。

これらについて知りたいなら、[ryan4yjn](https://github.com/ryan4yin)先生の素晴らしいチュートリアルがあります。

https://nixos-and-flakes.thiscute.world

あるいは、拙著をご覧ください。

https://zenn.dev/asa1984/articles/nixos-is-the-best

## 前提知識

- UNIX系システム（Linux, MacOS）を使ったことがある
- パッケージマネージャを使ったことがある

冒頭でNixは純粋関数型パッケージマネージャであると述べましたが、本書を読む上で純粋関数型言語の知識は必要ありません。
また、理解を円滑にするためにいくつかのパッケージマネージャやプログラミング言語を例示することがあります。ご了承ください。

## 本書の構成

本書は、まず「Nixとは何か」で前提知識を整理し、「Nixがなぜ必要なのか」で既存のパッケージ管理技術の問題点を確認した後、「Re: Nixとは何か」でNixの概要とコンセプトを解説します。以降の章では各機能とその仕組みについて詳しく説明します。各章の内容は前章の知識を前提とした構成になっているため、順番通りに読み進めることをお勧めします。

## いざ、Nixの世界へ！

これで準備は整いました。
改めて、本書を開いていただきありがとうございます。

それでは、Nixの世界へようこそ！

![Nixのロゴ](https://raw.githubusercontent.com/NixOS/nixos-artwork/35ebbbf01c3119005ed180726c388a01d4d1100c/logo/nix-snowflake.svg)
_Welcome to Nix!_