---
title: "Profiles"
---

話がややこしくなるのを避けるため、ここまでグローバルインストールの話題を回避してきました。グローバルインストールはシステムのグローバルな状態に変更を加える手続きであり、これまで学んできたNixの特徴とは対極の位置にあるように思えます。

Nixはグローバルインストールにおいても非常にユニークな仕組みを持っています。この仕組みによってグローバルインストールがユーザー環境を汚染しないクリーンな操作になり、Nixとその他のパッケージマネージャの共存を可能になります。また、これは本書では扱っていないNixOSやhome-managerの基礎となっている仕組みでもあります。

本章ではNixのパッケージ構成管理機構**Profiles**^[[6.1. Profiles - Nix Reference Manual](https://nixos.org/manual/nix/stable/package-management/profiles)]について解説します。

## Profile

`hello`をグローバルインストールしたとして、そのPATHを見てみます。

```bash
$ which hello
/home/<ユーザー名>/.nix-profile/bin/hello
```

`~/.nix-profile`という謎のディレクトリの下に配置されていることが分かります。Nixでインストールしたものは全てNixストアに格納されるのではなかったのでしょうか？

実は、上記のファイルは**シンボリックリンク**になっており、`~/.nix-profile/bin/hello`はNixストア下のストアオブジェクトにリンクされています。

```bash
$ readlink $(which hello)
/nix/store/7bl684y3qpxrv01ird085rpf5kl6rk6f-hello-2.12.1/bin/hello
```

今度は`~/.nix-profile`の中を覗いてみましょう。

```
~/.nix-profile
├─/bin
├─/etc
├─/include
├─/lib
├─/libexec
├─/sbin
└─/share
```

典型的なUNIX系システムのディレクトリ構造になっています。ここに配置されているファイルは全てストアオブジェクトにリンクされたシンボリックリンクです。

このストアオブジェクトのシンボリックリンクだけで構成されたディレクトリを**Profile**と呼びます。

## Profileの世代機能

実は`~/.nix-profile`自体もシンボリックリンクになっています。

```bash
$ readlink ~/.nix-profile
/home/<ユーザー名>/.local/state/nix/profiles/profile
```

そしてリンク先もまたシンボリックリンクになっており…

```bash
$ readlink ~/.local/state/nix/profiles/profile
profile-7-link
$ readlink ~/.local/state/nix/profiles/profile-7-link
/nix/store/nqgsdc76ahkzgk4ysdhqjakmci4720iw-profile
```

なんとNixストアに辿り着きました。

Profileは通常のNixパッケージと同様、Nixによってビルドされています。ビルドといってもストアオブジェクトに対してシンボリックリンクを張るだけです。
Nixにおけるグローバルインストール/アンインストール/アップグレードは新しいProfileのビルドを意味します。パッケージのインストールは新しくシンボリックリンクが追加されたProfileのビルド、アンインストールは対象のシンボリックリンクが除外されたProfileのビルド、アップグレードは対象のシンボリックリンクがより新しいストアオブジェクトを指すように変更されたProfileのビルドとして実現されます。

`~/.local/state/nix/profiles`の下には過去のProfileが保管されています。Profileに変更を加えた時、Nixは現在のProfileを直接変更するのではなく、完全に新規のProfileをビルドし、シンボリックリンクのリンク先を新しいProfileに切り替えます。こうすることでパッケージ構成の変更が安全な操作になるのです。

さらに過去のProfileが不変のまま残るのを利用して、パッケージ構成をロールバックすることができます。例えばパッケージ構成を1つ前の状態に戻したくなった場合、前述の例では現在のProfileが`~/.local/state/nix/profiles`下の`profile-7-link`、つまり7世代目のProfileにリンクされていましたが、これを1世代前の`profile-6-link`にリンクし直せばいいのです。

## マルチユーザー

Nixストアでパッケージを一元管理しつつ、Profilesを利用することでマルチユーザーにも対応できます。

（前述の例のシンボリックリンクの構成とはやや異なるので注意してください。）

![マルチユーザーでProfileを利用した場合のイメージ図](https://nixos.org/manual/nix/stable/figures/user-environments.png)
_[Nix Reference Manual - 6.1.Profiles](https://nixos.org/manual/nix/stable/package-management/profiles)_

## Profilesの応用

ProfilesはNixOSやhome-managerといったツールの基盤になっています。

### NixOS

NixOSはProfilesをシステムレベルに拡張し、root権限の操作を行えるようにしたLinuxディストリビューションです。Nixがホームディレクトリ下で操作を行うのに対し、NixOSは`/etc`や`/run`などにシンボリックリンクを配置します。
さらにNixOSは世代機能をブートローダーレベルに拡張しており、万が一OSが起動しなくなってもブートローダーから安全な世代の環境へ復帰することができます。

また、Nix本体のProfilesは手続き的にコマンド操作でインストールを行いますが、NixOSではNix言語でインストールするパッケージやOSの環境設定を記述することで、宣言的にProfilesを扱えるようになっています。便利な設定がNixOS modulesとして再利用可能になっており、環境構築を大幅に簡略化することができます。

### home-manager

home-managerは[nix-community](https://github.com/nix-community)が開発している宣言的ユーザー環境構築ツールです。NixOSと同様こちらも宣言的にProfilesを扱えるようになっており、NixOSがシステム領域をターゲットにしているのに対して、home-managerはユーザー環境の管理に特化しています。ユーザー環境向けの設定が多数モジュール化されており、NixOSユーザーの多くはhome-managerも一緒に利用しています。
