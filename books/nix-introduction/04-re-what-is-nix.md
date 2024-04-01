---
title: "Re: Nixとは何か"
---

前提知識の整理は終わりました。いよいよ本腰を入れてNixについて学んでいきます。ここではNixのコンセプトを解説します。

以下、[公式サイト](https://nixos.org)より引用・和訳したものを載せます。大切なことが書かれているので、しっかり目を通してください。

https://nixos.org

## Nix

> _"Nix is a tool that takes a unique approach to package management and system configuration. Learn how to make reproducible, declarative and reliable systems."_
>
> _「Nixはパッケージ管理とシステム構成に対して独自のアプローチを取るツールです。再現可能で宣言的で信頼性のあるシステムを構築する方法を学びましょう。」_

### 再現可能（Reproducible）

> _"Nix builds packages in isolation from each other. This ensures that they are reproducible and don't have undeclared dependencies, so **if a package works on one machine, it will also work on another**."_
>
> _「Nixはパッケージを互いに隔離してビルドします。これにより、パッケージが再現可能であり、未宣言の依存関係を持たないことが保証されます。**もしパッケージが1つのマシンで動作するなら、別のマシンでも動作するでしょう**。」_

### 宣言的（Declarative）

> _"Nix makes it **trivial to share development and build environments** for your projects, regardless of what programming languages and tools you’re using."_
>
> _「Nixは、どのようなプログラミング言語やツールを使っているかに関わらず、**プロジェクトの開発環境やビルド環境を共有することを非常に簡単にします**。」_

### 信頼性のある（Reliable）

> _"Nix ensures that installing or upgrading one package **cannot break other packages**. It allows you to **roll back to previous versions**, and ensures that no package is in an inconsistent state during an upgrade."_
>
> _「Nixは、1つのパッケージをインストールまたはアップグレードすることが**他のパッケージを壊すことができないようにします**。また、**以前のバージョンにロールバックすることができ**、アップグレード中にパッケージが不整合な状態になることがないようにします。」_

---

引用は以上です。

**再現性**・**宣言的**・**信頼性**はNixの重要なコンセプトです。本書でも繰り返しこのキーワードが出てくるので覚えておいてください。

## 再現可能なビルド

「再現可能なビルド」とは、いつどのマシンでも常にビルド結果が同じになるようなビルドを指します。ソフトウェアの配布やデプロイにおいて再現性は非常に重要な要素です。

Nixは強力なビルドシステムによって、恐らくこの世で最も完全に近い再現性を実現しています。どれほどの再現性かというと、NixOSのミニマルISOイメージという巨大なパッケージのビルドの再現性が100%に逹しています。^[[Nixos-unstable’s iso_minimal.x86_64-linux is 100% reproducible!](https://discourse.nixos.org/t/nixos-unstable-s-iso-minimal-x86-64-linux-is-100-reproducible/13723)]

### 関連する機能

- 純粋関数的ビルドシステム
- Nixストア
- バイナリキャッシュ
- Derivation
- Flakes

## 宣言的なビルド・開発環境構築

煩雑なビルド手順を一々手動で実行する必要はありません。**Nix言語**で一度パッケージ定義を記述すれば、後はビルドシステムがパッケージの依存関係解決からビルドに至るまでの全てを自動で実行します。

また、パッケージのビルドだけでなく、開発環境の構築もNix言語を用いることで宣言的に行うことができます。

### 関連する機能

- Derivation
- Nix言語
- Flakes

## 安全なパッケージ管理

「パッケージをアップグレードしたら環境が壊れた」というのは一般的なパッケージマネージャならよくあることですが、Nixには縁のない話です。Nixはパッケージとパッケージ構成を**不変**に扱うため、アップグレード由来の依存関係問題が発生しません。また、パッケージ構成を**世代**として管理するため、万が一アップグレードによって問題が発生してもパッケージ構成を元の状態に復元することができます。

### 関連する機能

- Nixストア
- Profiles

## 他のパッケージマネージャとの比較

Nixの特徴をより明確にするため、他のパッケージマネージャとの簡単な比較を行います。ただし、これは優劣を付けるものではないので、その点にご留意ください。

1. 権限領域
2. パッケージリポジトリの形態
3. バイナリインストールの可否
4. パッケージ数

比較を表にまとめます。

|    名前    | 権限領域 | パッケージリポジトリ | バイナリインストール | パッケージ数^[[repology.org](https://repology.org/repositories/statistics/total)] |
| :--------: | :------: | :------------------: | :------------------: | :-------------------------------------------------------------------------------: |
| Arch Linux |   root   |        中央型        |         可能         |                                   約7万（AUR）                                    |
|   Cargo    | ユーザー |        中央型        |        不可能        |                                      約4000                                       |
|     Go     | ユーザー |        分散型        |        不可能        |                                         -                                         |
|  **Nix**   | ユーザー |    中央型/分散型     |         可能         |                             約9万（nixpkgs unstable）                             |

### ユーザー権限で動作する

Nixはroot権限が必要な領域を操作できません。例えば、カーネルやデバイスドライバをビルドすることは可能ですが、環境にインストールすることはできません。これはaptやrpm、PacmanといったOSのパッケージマネージャとは異なる点です。Nixでそういったroot権限を要する操作を行いたいならNixOSを使う必要があります。

また、システムのパッケージマネージャと競合しないため、あらゆるLinuxディストリビューションとMacOSでNixを利用することができます。

### Nixpkgsと分散型パッケージリポジトリ

パッケージリポジトリには、単一のリポジトリにユーザーや管理者がパッケージを登録し利用する中央型と、複数のリポジトリが存在し、各々が任意でリポジトリを作成、利用できる分散型があります。

Nixのパッケージリポジトリは分散型です。[Nixpkgs](https://github.com/NixOS/nixpkgs)という公式リポジトリは存在するものの、あくまで複数あるリポジトリの中の1つという扱いになります。GitHubなどを利用することでユーザーは自由にパッケージを公開、利用することができます。この点はGo言語によく似ています。

### バイナリインストール可能

Nixは**バイナリキャッシュ**という仕組みによって再現性を保ったままビルド済みバイナリの直接インストールを可能にしています。「バイナリキャッシュ」の章で詳解します。

### 最大級のパッケージ数

Nixpkgsは最もパッケージ数の多いオープンソースのパッケージリポジトリです。執筆時点（2024/03/31）では、ローリングリリースのunstableブランチが約9万、同じく執筆時点で最新のstableブランチ（nixpkgs stable 23.11）は約8.8万のパッケージ数を誇ります。

https://repology.org/repositories/statistics/total
