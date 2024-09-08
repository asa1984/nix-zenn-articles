---
title: "用語の定義"
---

用語の曖昧さは学習の妨げになるだけでなく、不毛な争議の原因にもなります。特にNixにまつわる用語は混同されやすいため、本書で使う用語を明確に定義しておきます。

本書では可能な限りバージョン2.20版Nix Reference Manualの[13. Glossary](https://nix.dev/manual/nix/2.20/glossary)で定義されている用語を使います。Nix独自の用語はカタカナあるいはアルファベットで表記します^[「Instantiateされたstore derivationをrealiseする」というような奇妙な文章が度々出てきます。ご了承ください。]。

https://nix.dev/manual/nix/2.20/glossary

このセクションでは本書における「Nix」の意味を定義します。

## Nix

Nixは単なるパッケージマネージャに過ぎず、以下のように様々な側面を持っています。

- パッケージマネージャとしてのNix
- ビルドシステムとしてのNix
- Nix言語（ドメイン固有言語）
- Nixpkgs（パッケージレジストリ）
- NixOS（Linuxディストリビューション）

全て「Nix」という名を冠しているので、文脈によっては混乱してしまうでしょう。

そこで本書では「Nix」という言葉を「[NixOS/nix](https://github.com/NixOS/nix)で開発されているパッケージマネージャ」という意味で使うことにします。

https://github.com/NixOS/nix

Nixは以下のような特徴・機能を持っています。

- 特徴
  - UNIX系OS全般のためのパッケージマネージャ
  - ユーザー権限で動作する
- 機能
  - パッケージ管理（[Nixストア](https://zenn.dev/asa1984/books/nix-introduction/viewer/06-nix-store)）
  - パッケージ構成管理（[Profiles](https://zenn.dev/asa1984/books/nix-introduction/viewer/12-profiles)）
  - ビルドシステム
  - Nix言語の評価

NixはあらゆるLinuxディストリビューションやmacOSをサポートするユニバーサルなツールです。通常のファイル構造（[Filesystem Hierarchy Standard](https://ja.wikipedia.org/wiki/Filesystem_Hierarchy_Standard)）から独立した場所でパッケージ管理を行うため、APT, Pacman, RPM, Homebrewなどのパッケージ管理システムと競合せず、またユーザー権限で動作するため、これらを完全に代替するものでもありません。

Nixは、OSのパッケージマネージャというよりも、プログラミング言語のパッケージマネージャ（Cargo, npmなど）に近いツールです。

本書ではNixのユニバーサルなツールとしての側面を重視し、その使い方を解説します。

## Nix言語

Nix言語は、Nixで利用される専用のプログラミング言語（ドメイン固有言語）です。Nix言語とNix言語を利用するツール（=パッケージマネージャNix）の名前が同じなので、混乱を避けるために常に「Nix言語」と呼ぶことにします。

## NixOS

**パッケージマネージャとしてのNixとNixOSは別物です**。

NixOSは、Nixを単なるパッケージマネージャとして利用しているわけではありません。NixOSではOSの設定（ユーザー、ネットワーク、サービス、ドライバー、etc）をNix言語で記述し、それをNixで評価・ビルドした後、NixOS側で変更を適用することで環境構築を行う特殊なLinuxディストリビューションです。

ユーザー権限で動作するNixと異なり、NixOSはroot権限の領域を操作することができるため、カーネルやドライバーといったシステム用のパッケージをインストールすることができます。

パッケージマネージャNixが[NixOS/nix](https://github.com/NixOS/nix)で開発が進められているのに対し、NixOSは[NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)から提供されていることからも、両者が区別される存在であることが分かると思います。

https://github.com/NixOS/nix

https://github.com/NixOS/nixpkgs

本書ではNixOSについては取り扱いません。
