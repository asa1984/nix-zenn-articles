---
title: "Nixpkgs"
---

[Nixpkgs](https://github.com/NixOS/nixpkgs)はNixの公式パッケージリポジトリです。GitHubリポジトリで管理されており、そのコミット数は60万を超えています。

https://github.com/NixOS/nixpkgs

Nixpkgsはただのパッケージリポジトリというだけでなく、Nixエコシステムの中心として他にも重要な役割を果たしてます。本章ではNixpkgsについて詳しく見ていきます。

本章の内容のほとんどは[Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)を参照しています。

https://nixos.org/manual/nixpkgs/stable/

## 驚異的なパッケージ数

驚くべきはそのパッケージ数です。実は、Nixpkgsは現在最もパッケージ数の多いパッケージリポジトリです。

以下のグラフは[Repology](https://repology.org)によるパッケージリポジトリの統計を視覚化したものです。横軸は「パッケージの数」、縦軸は「新しい状態に保たれているパッケージの数」です。ほとんどのパッケージリポジトリは左下の領域に集まっていますが、AURとNixpkgsだけ大きく離れて右側に位置しています。そして最も右上に位置しているのはNixpkgsのローリングリリースブランチであるnixpkgs unstableです。

![Repologyによるパッケージリポジトリの統計の点グラフ。横軸に`Number of packages in repository`、縦軸に`Number of fresh packages in repository`と付記されている。グラフを上下左右の4つの領域に分割したとき、ほとんどのパッケージリポジトリの点が左下に位置し、そこから大きく離れてNixpkgsの各ブランチとAURの点が右側に位置している。AURの点は右下に位置しているが、Nixpkgsの各ブランチは右上に位置している。nixpkgs unstableの点がグラフ全体で最も右上に位置している。](https://repology.org/graph/map_repo_size_fresh.svg)
_[repology.org](https://repology.org/repositories/graphs)より引用_

本章執筆時点（2024/03/31）において、nixpkgs unstableは90924パッケージ、執筆時点最新のstableブランチであるnixpkgs stable 23.11は88843パッケージが存在しています。

Nixはビルドシステムの強い制約や独自概念がありますが、Nix言語の柔軟性が非常に高いため、一般的なパッケージマネージャではカバーしきれない範囲までNixでラップすることができるのです。

こちらのWebサイトからパッケージを検索することができます。

https://search.nixos.org/packages

## Nixpkgsのブランチ

Nixpkgsには複数のブランチがあります。まず、ローリングリリースのunstableブランチと安定版のstableブランチがあります。安定版ブランチの新しいリリースには基本的にセキュリティアップデートのみが含まれます。

また、NixOSユーザー向けの`nixos-*`ブランチと非NixOSユーザー向けの`nixpkgs-*`ブランチがあります。これらの何が違うのかというと、実行されるテストの内容が異なります^[[Differences between Nix channels - NixOS Discourse](https://discourse.nixos.org/t/differences-between-nix-channels/13998/5)]。Nixpkgsでは、[Hydra](https://nixos.org/hydra/)というCIツールを利用してパッケージのビルドとテストを行っています。ブランチごとにジョブが設定されており、ビルドが成功し、テストを通過しない限り更新が反映されないようになっています。

`nixpkgs-unstable`と`nixos-unstable`は、全てのブランチの中で最も新しい`master`ブランチに追従していますが、`master`からの反映には通常数日の遅れがあります。これは、更新がテストを経て安全性が確認されてからでないと反映されないようになっているからです。

また、Hydraを用いてバイナリキャッシュの作成も行っており、ビルド成果物をAWSのS3にアップロードし、[cache.nixos.org](https://cache.nixos.org)からバイナリキャッシュを提供しています。

## 対応プラットフォーム

Nixpkgsが主にサポートするプラットフォームは以下の通りです。

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`
- `x86_64-darwin`

`x86_64-linux`が最高レベルのサポートを受けており、`aarch64-darwin`（Apple Silicon）は`x86_64-darwin`（Intel Mac）よりも高いサポートを受けています。

Nixpkgsは上記のプラットフォーム以外もサポートしており、[RFC046](https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md)の[Appendix A](https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md#appendix-a-non-normative-description-of-platforms-in-november-2019)にサポートのTierごとに対応プラットフォームがリストアップされています。このリストは2019年11月時点のものであり、例えば`aarch64-darwin`のTierが現状とは異なったりするので注意してください。

## Unfreeパッケージ

NixpkgsではプロプライエタリなパッケージがUnfreeパッケージにカテゴライズされ、デフォルトではインストールできないようになっています。
これはNixpkgsの利用者は全て自由ソフトウェアの利用者であり、Nixpkgsの利用者および開発者が、不自由ソフトウェアへのアクセスを制限し厳しく管理することを望んでいるためだと説明されています。

もちろん設定さえすればUnfreeパッケージも問題なくインストールできます。

[Install unfree packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree)

https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree

## Nixpkgsの実体

実は、Nixpkgs自体が1つのNix式になっています。Nixのパッケージリポジトリはプログラミング言語のライブラリに近いものです。実際にNixpkgsを利用する際は、Nix言語でNixpkgsのNix式をインポートします。ちょうどプログラミング言語で外部ライブラリをインポートするのと同じです。

言ってしまえば、Nixpkgsは「パッケージのビルド用関数が約9万個収録されたNix言語のライブラリ」なのです。

## パッケージ以外の提供物

### [Nixpkgs lib](https://nixos.org/manual/nixpkgs/stable/#id-1.4)

Nix言語の標準ライブラリを提供しています。

### [Standard Environment](https://nixos.org/manual/nixpkgs/stable/#chap-stdenv)

Standard Environment（直訳: 標準環境）は、UNIXパッケージをビルドする上で必要な標準的なビルド環境を提供します。Derivationの章で`stdenv`として登場したものです。
`stdenv.mkDerivation`はNixpkgsが提供する最も重要な関数の1つです。なぜならNixpkgsが提供するほとんどのパッケージはstdenvを用いてビルドさているからです。

Nix言語のビルトイン関数である`derivation`は、実際のビルドに使うにはプリミティブすぎるという問題があります。対して、stdenvには[様々なツール](https://nixos.org/manual/nixpkgs/stable/#sec-tools-of-stdenv)が最初から組み込まれており、`gcc`, `coreutils`, `find`, `grep`, `make`といった代表的なGNUツールチェーン、ビルド用の便利なシェルスクリプト、そしてビルドを実行するシェルであるBashが最初から導入されています。また、Linuxのstdenvには、実行可能ファイルにパッチを適用する[patchelf](https://github.com/NixOS/patchelf)も導入されています。

stdenvは多くのビルド手順を自動化するため、標準の`make`や`make install`を使用するUNIXパッケージをビルドする場合は一切ビルドスクリプトを書く必要がありません。そうでない場合も通常のビルドスクリプトを書くのと大差ないようなインターフェースでカスタマイズできるようになっています。

他にもまだまだ機能がありますが、本書での解説はここまでとします。

### [ビルドヘルパー](https://nixos.org/manual/nixpkgs/stable/#part-builders)

プログラミング言語やフレームワークごとの典型的なビルドワークフローを抽象化するために様々なビルド用ユーティリティ関数が提供されています。

#### [Fetchers](https://nixos.org/manual/nixpkgs/stable/#chap-pkgs-fetchers)

ビルドシステムの章でも紹介したFetcherが提供されています。もう一度説明しておくと、Fetcherは事前にダウンロード予定のコンテンツのハッシュ値を指定しておき、Fetcher実行時にハッシュの異なるコンテンツがダウンロードされた場合異常終了させることで、再現性を保ったままインターネットからのリソース取得を可能にする仕組みです。

`fetchFromGitHub`や`fetchFromGitLab`などのソースコードホスティングプラットフォームからソースコードを取得するFetcherは、Nixpkgs内で最も広く利用されているFetcherの1つです。

#### [イメージ](https://nixos.org/manual/nixpkgs/stable/#chap-images)

AppImageやSnap、Dockerイメージをビルドするための関数が提供されています。

`dockerTools.buildImage`関数を使うことでDockerfileを記述することなく、Nix言語でDockerイメージをビルドすることができます。明示的に指定したパッケージだけがイメージに含まれることになるので、再現性はもちろん、[distroless](https://github.com/GoogleContainerTools/distroless)以上にミニマルなイメージを作ることもできます。

#### [言語・フレームワーク](https://nixos.org/manual/nixpkgs/stable/#chap-language-support)

言語やフレームワークごとのビルド用ユーティリティ関数が提供されています。たとえば、Rustは`rustPlatform.buildRustPackage`、Goは`buildGoModule`です。VimプラグインをNixパッケージ化する`vimPlugins`という関数もあります。

この領域はNixpkgs以外でも熱心に開発が行われており、Rustの[crane](https://github.com/ipetkov/crane)やPoetry（Pythonのpipの代替パッケージマネージャの1つ）の[poetry2nix](https://github.com/nix-community/poetry2nix)など、多数のライブラリが存在します。
