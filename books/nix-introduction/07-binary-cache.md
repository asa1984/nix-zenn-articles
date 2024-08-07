---
title: "バイナリキャッシュ"
---

実は、前章で紹介したNixストアは正確には**ローカルストア**と呼ばれるNixストアの一種です。Nixストアには内部のフォーマットによって複数の種類があります。

- ローカルストア
- SSHストア
- ダミーストア
- ローカルデーモンストア
- バイナリキャッシュストア

基本的に「Nixストア」はローカルストアのことを指して言うことが多いですが、他のストアもそれぞれ役割を持っており、ここでは特に重要な**バイナリキャッシュストア**について解説していきます。

## ストアパスと決定的ビルド

Nixはビルドの入力を元にハッシュを生成し、それをビルド成果物の識別子（ストアパス）としていました。逆に言えば、同じストアパスが生成されれば同じビルド成果物が得られるということです。
ストアパスはビルドの実行前に生成されます。ストアパスが生成された時点で既に同じストアパスのストアオブジェクトが存在していた場合、Nixはビルドをスキップします。

一般的なビルドシステムではビルド結果のキャッシュの利用は限定的な範囲に留ります。一方、Nixのビルドは同じ入力に対して同じビルド結果が出力されることが保証されているため、安全にビルドをスキップすることができます。Nixのビルドは再現可能、言い換えれば予測可能です。このような性質を持つビルドは、**決定的ビルド**と呼ばれます。

## Substituter^[[glossary - Nix Reference Manual](https://nixos.org/manual/nix/stable/glossary#gloss-substituter)]

Nixはローカルストアに加えて、**Substituter**（代替者）という追加のNixストアを利用することができます。

Substituterを利用した場合、Nixのビルドは以下の手順で実行されます。

1. ストアパス生成
2. ローカルストアにビルド済みストアオブジェクトが存在するか確認
   - 存在すればビルドをスキップ
3. Substituterにビルド済みストアオブジェクトが存在するか確認
   - 存在すればビルドをスキップし、Substituterのストアオブジェクトをローカルストアに取得
4. ローカルストアにもSubstituterにも存在しなかった場合はビルド実行

Substituterはローカルストアを拡張するように振る舞います。Substituterは後述するバイナリキャッシュストアと併せて初めて真価を発揮します。

## バイナリキャッシュストア^[[4.4. Store Types - Nix Reference Manual](https://nixos.org/manual/nix/stable/store/types/)]

**バイナリキャッシュストア**は、ビルド済みストアオブジェクト（**バイナリキャッシュ**）の提供に特化した内部フォーマットを持つNixストアです。バイナリキャッシュストアにもいくつか種類があります。

- ローカルバイナリキャッシュストア
- HTTPバイナリキャッシュストア
- S3バイナリキャッシュストア

HTTPバイナリストアキャッシュはHTTPプロトコル、S3バイナリキャッシュはS3互換のオブジェクトストレージを利用し、インターネットを経由してバイナリキャッシュを提供します。つまり、バイナリキャッシュストアをSubstituterに指定すれば、ローカルでビルドすることなくインターネットから直接ビルド成果物をダウンロードできるのです！

Nixの公式パッケージリポジトリ[Nixpkgs](https://github.com/NixOS/nixpkgs)は、[cache.nixos.org](https://cache.nixos.org)でNixpkgsのビルド済みバイナリを提供しています。Nixpkgsのバイナリキャッシュストアは、デフォルトでSubstituterに追加されています。そのため、Nixpkgsからのパッケージのインストールは非常に高速です。

これは驚くべきことです。Substituterとバイナリキャッシュストアによって、ソースコードをローカルマシンでビルドして得られる結果と、インターネットから直接ビルド済みバイナリを取得して得られる結果が等価になるからです。

### NAR^[[[5.2.1. File system objects] Dolstra, Eelco. 2006. _The Purely Functional Software Deployment Model_.](https://edolstra.github.io/pubs/phd-thesis.pdf)]

**NAR**（**N**ix **AR**chive）はNixで利用されているアーカイブフォーマットです。ストアオブジェクトのシリアライズに利用されます。

NARは、TARのような既存のアーカイブフォーマットが不十分だったため設計されました。Nixのビルドシステムは決定的ですが、一般的なアーカイブフォーマットはパディングを追加したり、ファイルをソートしなかったり、タイムスタンプを追加したりするため非決定的です。これはシリアライズ結果が一意にならない可能性があることを意味します。Nixストアでハッシュ計算を行うためにはシリアライズがビットレベルで一意でなければならないため、決定的なアーカイブフォーマットとしてNARが開発されました。

## バイナリキャッシュ関連のツール・サービス

### Cachix

CachixはNixのバイナリキャッシュをホスティングできるCIサービスです。Cachixを使えば個人でも簡単にバイナリキャッシュを提供できます。GitHub ActionsなどのCIと連携することができます。

https://www.cachix.org

### Attic

Atticはセルフホスト可能なバイナリキャッシュサーバーです。Rustで実装されています。開発者のzhaofengli氏は[fly.io](https://fly.io)にインスタンスを建て、データベースには[Neon](https://neon.tech)、ストレージには[Cloudflare R2](https://developers.cloudflare.com/r2/)を利用しているそうです^[[Introducing Attic, a self-hostable Nix Binary Cache server](https://discourse.nixos.org/t/introducing-attic-a-self-hostable-nix-binary-cache-server/24343)]。

https://github.com/zhaofengli/attic

## Nixストア関連の様々な機能

### `nix copy`

`nix copy`コマンドはストアオブジェクトを別のNixストアにコピーするコマンドです。ローカルストアのストアオブジェクトをバイナリキャッシュストアにコピーしたり、別マシンのローカルストアにストアオブジェクトを直接移送したりできます。たとえどんなに複雑な依存関係であっても、Nixが完全な依存関係ツリー（Closures）を把握しているため安全に移送できます。

### リモートビルド^[[7.2. Remote Builds](https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds)]

1. ローカルマシンでビルドの入力を指定
2. リモートマシンでビルド実行
3. リモートマシンのビルド結果をローカルマシンにコピー

ビルドプロセスだけをリモートマシンに委譲することができます。低スペックなマシンからより高スペックなマシンにビルドを委譲し、ビルド時間を短縮するといった使い方ができます。
