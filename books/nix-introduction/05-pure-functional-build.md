---
title: "純粋関数的ビルド"
---

Nixのビルドシステムについて見ていきましょう。

Nixのビルドシステムは**純粋関数的**です。これがNixが純粋関数型パッケージマネージャと呼ばれる所以であり、「再現性」を実現する要です。

## 純粋関数

ほとんどのプログラミング言語における「関数」と数学の「関数」は全く異なる概念です。プログラミング言語の関数は、正確には関数ではなく、**サブルーチン**（または**プロシージャ**）と呼ばれるものです。サブルーチンは「処理の集まり」を意味します。

一方、数学の関数には明確な定義があります。数学用語抜きに簡単に説明すると「入力が定まると出力が唯一に定まるような関係」のことを関数と呼んでいます^[数学の関数は、集合論における**写像**として定義されている。集合$A$の全要素に対してちょうど1つずつ集合$B$へ対応づけるような規則$f$のことを「集合$A$から集合$B$への写像$f$」という。]。下に関数のイメージ図を載せます。

![関数のイメージ図。左側の入力の集合から右側の出力の集合への写像が、赤い矢印で表現されている。入力の集合の丸形要素から、それぞれ1つづつ出力の集合の菱形要素へ矢印が伸びている。](/images/nix-introduction/mapping.png)
_関数_

丸形要素からそれぞれ1つずつ菱形要素へ矢印が伸びています。

逆に、1つの入力に対して複数の出力が与えられるような、入力対出力が一対多となる関係は関数ではありません。

![関数ではない集合の対応の図解。左側の入力の集合から右側の出力の集合への対応が、赤い矢印で表現されている。](/images/nix-introduction/correspondence.png)
_関数ではない_

プログラミング言語の文脈ではサブルーチンと数学の関数を区別するために、数学的な関数のことを特別に**純粋関数**と呼んでいます。そして、関数がサブルーチンではなく純粋関数として扱われるようなプログラミング言語を**純粋関数型言語**と呼びます。

### 純粋関数の特性

#### 副作用がない^[[プログラム言語論 - 筑波大学](https://www.cs.tsukuba.ac.jp/~kam/lecture/plm2011/5-web.pdf)]

純粋関数は**副作用**を持ちません。関数の主作用は引数に対して値を返すことです。もし関数が値を返す以外に何かを行う場合、その関数は副作用を持ちます。
具体的には以下が副作用に相当します。

- 状態の変更
- IO（ファイル操作、標準入出力、インターネットアクセス、etc...）
- etc...

関数の外部にある引数以外の情報にアクセスすることが副作用に相当します。いずれもコンピュータを利用する上では必須の処理なので、純粋関数型言語では副作用を純粋に扱えるような工夫がなされています。

#### 参照透過性

**参照透過性**とは、同じ引数に対して常に同じ値を返すという性質です。数学的関数の定義を考えれば当たり前の性質です。
もし、ある関数が実行するタイミングや環境によって異なる結果を返すならば、それは参照透過ではありません。

## 純粋関数的ビルドシステム

実は、理想的なビルドシステムが備えるべき性質を考えると、それはぴったり純粋関数の性質に当てはまります。

まず、理想的なビルドは再現可能であるべきです。
再現可能ではないビルドは、同じソースコードからビルドしても、環境やタイミングによってビルド成果物の内容が変わったり、最悪ビルドに失敗したりします。

![単射でない関係の図解。左側の丸から右側の菱形、長方形、丸へと3本の赤い矢印が伸びている。](/images/nix-introduction/not-pure-build.png)
_再現性がない状態_

一方、再現可能なビルドでは、いつでもどの環境でも同じビルド成果物を得ることができます。ソースコードに対してビルド成果物が一意に定まる状態、つまりビルドが純粋関数になっていることが望ましいです。

![単射な関係の図解。左側の丸から右側の菱形へと1本の赤い矢印が伸びている。](/images/nix-introduction/pure-build.png)
_再現性がある状態_

パッケージのビルドを関数に見立ててみましょう。

$$
f(ビルドの入力) = ビルド成果物
$$

この関数の引数「**ビルドの入力**」とはパッケージを同定する全ての要素、つまりビルドに影響をもたらす全要素です。具体的には以下の情報が入力に相当します。

- 依存関係
- ソースコード
- ビルドスクリプト
- 環境変数
- システムアーキテクチャ
- etc...

ここで暗黙的依存について考えます。暗黙的依存とは、まさしくビルドの副作用です。多くのビルドシステムはビルドの入力に相当する情報をパッケージ定義ファイルに記述しますが、定義ファイルに明示的に記述されていない外部の要素からも影響を受けてしまうため、副作用を持ちます。

一方、Nixでは明示的にビルドの入力として指定したものだけがビルドに影響を及ぼし、外部の要素は一切干渉することができないようになっています。そのため、Nixのビルドは参照透過性を持ちます。同じ「入力」に対して常に同じ「ビルド成果物」を返すからです。

## サンドボックス環境^[[Sandboxing - Zero to Nix](https://zero-to-nix.com/concepts/sandboxing)]

では実際どのようにして純粋関数的なビルドを実現するのかというと、**サンドボックス**環境を利用します。

サンドボックス（直訳: 箱庭）とは、ホストシステムから隔離・保護された環境のことです。VMやDockerを使ったことがある人ならイメージしやすいかもしれません。

Nixは**入力**として指定されたものだけをサンドボックス内に導入しビルドを実行します。

![サンドボックス環境のイメージ図。ホストシステムからシェル、環境変数、依存パッケージ、ソースコードを入力に指定し、入力に指定したものだけがサンドボックス環境に導入されている。サンドボックス内からホストのパッケージ、ホストの環境変数、インターネットにアクセスすることが禁止されている。サンドボックス内でビルドを実行した結果、ビルド成果物がホストシステムへと出力されている。](/images/nix-introduction/sandbox.png)
_サンドボックスのイメージ図_

サンドボックス外へのアクセスは副作用として制限されています。

入力の指定は厳密に行わなければなりません。まず、ビルドスクリプトを実行するためのシェルから指定する必要があります。通常の環境ならほぼ確実にインストールされているような基本的なツールも明示的に指定しなければならず、例えば`cp`, `ls`, `rm`といったコマンドを使いたかったら`coreutils`をビルドの入力に指定する必要があります。万が一ビルドの入力に何も指定しなかった場合、サンドボックス内には本当に何も存在しないのです。

### インターネットアクセスの禁止

ちょっとビックリするかもしれませんが、Nixのサンドボックス環境ではインターネットにアクセスすることができません。インターネットへのアクセスはもちろん副作用ですし、レスポンスが羃等なことも保証されていないからです。

しかし、現代のプログラミング言語のパッケージマネージャはインターネットからパッケージをダウンロードすることが当たり前ですし、インターネットが使えないとなると非常に不便です。Nixはどうやってそれを解決しているのでしょうか。

Nixのビルドシステムには**Fetcher**という脱出口的な機能があります。これは再現性を損わずにインターネットからリソースを取得するための仕組みです。Fetcherはダウンロード前にダウンロード予定のリソースのハッシュ値を指定しておく必要があります。ビルド実行時、Fetcher経由で取得したリソースから算出したハッシュと事前に指定したハッシュが異なる場合、即座にビルドを失敗させるという仕組みです。

Fetcherは1つだけではなく、GitHubからソースコードをダウンロードするFetcherなど用途ごとに様々なFetcherが存在します。

## 再現性は保証されたか？

サンドボックス環境のおかげで、同じ入力に対して同じビルド成果物が出力されることが保証されました。しかし、まだ以下の問題が残っています。

1. 入力をどのように指定するか
2. 実行時依存をどのように解決するか

いざパッケージをビルドするとなった時に入力そのものが変化してしまえば元も子もありません。サンドボックスのビルドシステムを有効に使うには厳密に入力を指定する仕組みが必要です。

また、実行時依存はビルドシステムでは解決することができません。特に、実行時依存の代表格である共有ライブラリは依存関係地獄を引き起こす主要因です。

次のパートではパッケージ管理機構**Nixストア**がどのようにしてこれらの問題を解決するのかを見ていきます。
