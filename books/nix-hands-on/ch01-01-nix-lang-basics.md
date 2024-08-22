---
title: "　§1. Nix言語の基本"
---

まずはNix言語の基本的な構文や機能を学び、簡単な式を評価して雰囲気を掴みます。

## Nix言語でHello world

まずはHello worldしてみましょう。

以下のような`hello-world.nix`を作成します。

```nix :hello-world.nix
"Hello, world!"
```

`nix eval`コマンドでNixファイルを評価します。

```bash
$ nix eval --file ./hello-world.nix
"Hello, world!"
```

……なんだかプログラムというよりはただの文字列ですね。Nix言語で記述されたプログラムを**Nix式**^[「式（expression）」はプログラムの構文要素（「項（term）」といいます）の1つで、評価を繰り返すと必ず何らかの「値」に帰着します。]と呼びますが、Nix式は必ず1つの値を返す必要があります。`hello-world.nix`の中身は、常に`"Hello, world!"`という文字列を返す非常に原始的なNix式です。

また、Nix言語自体に標準出力に値を出力する機能はありません。上の例では`nix eval`コマンドが`hello-world.nix`の評価結果を標準出力に出力しているだけです。

### REPL

`nix repl`コマンドでNix言語のREPLを起動できます。

```bash :REPLでHello world
$ nix repl
nix-repl> "Hello, world!"
"Hello, world!"
```

## データ型

- プリミティブ型
  - Number
  - String
  - Path
  - Boolean
  - Null
- 複合型
  - List
  - Attribute Set

### Number

```bash :Number型と算術演算
# integer
nix-repl> 1
1

# integerの四則演算
nix-repl> 1 + 2
3

# floatを含む算術演算はfloatになる
nix-repl> 1.0 / 3
0.333333
```

#### 算術演算子の構文に関する注意点

除算演算子`/`は、オペランドと演算子の間に空白を入れないとPath型（後述）と解釈されてしまいます。

```bash :除算演算子とPath型
nix-repl> 10/2
/10/2

nix-repl> 10 / 2
5
```

また、Nix言語はケバブケースの命名を許容しているため、減算演算子`-`が変数名の一部と解釈されることがあります。

```bash :減算演算子とケバブケース
# nはNumber型の変数
nix-repl> n-1
error: undefined variable 'n-1'
       at «string»:1:1:
            1| n-1
             | ^
```

### String

```bash :String型
nix-repl> "Hello, world!"
"Hello, world!"

# 複数行の文字列
nix-repl> ''
          aaaa
          bbbb
          cccc
          ''
"aaaa\nbbbb\ncccc\n"

# String + String -> String
nix-repl> "Hello, " + "world!"
"Hello, world!"

# `${}`で変数を埋め込む
# (a = "Nix lang", b = "poor")
nix-repl> "${a} is ${b}"
"Nix lang is poor"
```

### Path

`Path`型はNix言語特有の型で、ファイルパスを表します。

```bash :REPLの場合
# 評価すると絶対パスが返ってくる
nix-repl> ./path/to/something
/absolute/path/to/something
```

Pathは、**Pathが記述されたNixファイルからの相対パス**として記述します。例えば、`./.`はNixファイルが配置されたディレクトリを表します。

```:/path/to/something.nix
./.
```

```bash :something.nixを評価
$ nix eval --file /path/to/something.nix
/path/to
```

Pathを評価すると絶対パスが表示されます。ただし、内部的にはただのファイルパスとは異なる別の形式を取っており、**derivation**と深い関わりがあります。詳細は「1.4. Nix言語とderivation」のセクションで説明します。

Path同士またはPathとStringを`+`演算子で結合することができます。Path + Stringの結果はPathになります。

```bash :Pathの結合
# Path + Path -> Path
nix-repl> /path + /to + /something
/path/to/something

# Path + String -> Path
nix-repl> ./. + "/hello"
<現在のディレクトリの絶対パス>/hello
```

### List

```bash :List型
nix-repl> [1 2 3]
[ 1 2 3 ]

# Listの要素は異なる型でもよい
nix-repl> ["a" 1 [2 3]]
[ "a" 1 [ ... ] ]
```

Listは`++`演算子で結合できます。

```nix :Listと++演算子
# List ++ List -> List
nix-repl> [1 2 3] ++ [4 5 6]
[ 1 2 3 4 5 6 ]
```

1つ注意点として、Listの中で関数を適用したい場合は`()`で囲んで範囲を明確にする必要があります。この挙動にハマる人が多いので公式ドキュメントにも[注意](https://nix.dev/manual/nix/2.18/language/values#list)が書かれています。

```bash :List内で関数を使うときの注意点
# 関数fの定義: Numberを受け取り、1を加えて返す

# 結果は`[Number Number Number]`となる
nix-repl> [1 2 (f 3)]
[ 1 2 4 ]

# `()`で囲まないと`[Number Number Function Number]`として扱われる
nix-repl> [1 2 f 3]
[ 1 2 «lambda @ «string»:1:1» 3 ]
```

### Attribute Set

**Attribute Set**（**AttrSet**や単に**Set**とも呼ばれる）はレコード型や辞書型に相当するもので、Key-Valueのペアを持ちます。このペアを**attribute**（属性）と呼びます。

```bash :AttrSet型
nix-repl> { a = 1; b = 2; }
{ a = 1; b = 2; }

# Attribute Setのattributeにアクセス
nix-repl> { a = 1; b = 2; }.a
1
```

attributeには文字列でもアクセスできます。

```bash :文字列でアクセス
nix-repl> { a = 1; b = 2; }."a"
1
```

`rec`（recursiveの意）をつけることで自身のattributeを参照できます。

```bash :recキーワード
# attributeを相互に参照
nix-repl> rec { a = 1; b = a + 1; }
{ a = 1; b = 2; }
```

`//`演算子を使うことで複数のAttrSetをマージできます。

```bash ://演算子
# AttrSetのマージ
nix-repl> { a = 1; b = 2; } // { c = 3; }
{ a = 1; b = 2; c = 3; }

# 同じattributeがある場合、後者が優先される
nix-repl> { a = 1; b = 2; } // { a = 4; c = 3; }
{ a = 4; b = 2; c = 3; }
```

## 基本的な言語機能

### let式

```bash :let-inによる変数の束縛
nix-repl> let a = 1; in a
1
nix-repl> let a = 1; b = 2; in a + b
3
```

`let-in`で変数を束縛できます。Nix言語の変数は不変なので、再代入はできません。

Nix式は必ず値を返す純粋な式なので、究極的には1つのインラインの式として記述することができます。しかし、それでは可読性が悪くなるので、let式を使って処理のステップを明確にしましょう。

```nix :可読性のためのlet式
let
  processed1 = # ステップ1の処理
  processed2 = # ステップ2の処理
  processed3 = # ステップ3の処理
in
processed3 # 結果を返す
```

REPLは全体が1つの`let-in`の中にあるような状態なので自由に変数を定義できます。

```bash :REPLでの変数定義
nix-repl> a = 1
nix-repl> a
1

# REPL内でのみシャドーイング可能
nix-repl> a = 2
nix-repl> a
2
```

### inherit

AttrSetで使用します。
以下のようなNix式を考えます。

```nix :Before
let
  a = 1;
in
{
  a = a;
}
```

`a = a`と書いていた部分を`inherit`を使って書き直します。以下は上のNix式と等価です。

```nix :After
let
  a = 1;
in
{
  inherit a;
}
```

### with式

```nix :with式のカタチ
with <AttrSet>; <式>
```

with式は与えられたAttrSetのattributeを変数として`;`以降の式のスコープに導入します。実際に使った方がわかりやすいです。

```nix :Before
let
  set = {
    a = 1;
    b = 2;
  };
in
set.a + set.b # -> 3
```

```nix :After
let
  set = {
    a = 1;
    b = 2;
  };
in
# setのattributeをそのまま変数として使える
with set; a + b # -> 3
```

AttrSetのattributeをListに入れるときによく使われます。

```nix :with式とList
let
  set = {
    a = 1;
    b = 2;
  };
in
with set; [ a b ] # -> [ 1 2 ]
```

:::message alert
**with式の多用は危険です。**
展開されたattributeと式中で定義された変数が衝突する場合があり、望ましくない挙動をする可能性があります。また、Nix言語のLanguage Serverのほとんどはwith式が使われたスコープを上手く解析することができません。
with式の影響範囲が広くなるとコードの可読性が極端に低下します。
:::

### if式

Nix言語は式指向なのでif文ではなくif**式**です。

```bash :if式
nix-repl> if true then 1 else 2
1

nix-repl> if false then 1 else 2
2
```

## 関数

関数型言語で一番大事なのはもちろん関数です。

Nix言語における関数は以下のように定義します。`:`の後は必ず空白を入れる必要があります。

```nix :関数の定義
<引数>: <式>
```

関数を使うには空白を空けて引数を渡します。関数型言語では関数に引数を渡すことを**適用**と呼びます。本書でもその表現に則ることにしましょう。

```nix :関数の適用
<関数> <引数>
```

### 具体的な例

```bash :関数
# 1つの引数をとる関数
nix-repl> add_1 = a: a + 1
nix-repl> add_1 1
2

# 2つの引数をとる関数
nix-repl> add_a_b = a: b: a + b
nix-repl> add_a_b 1 2
3

# 無名関数
nix-repl> (a: a + 1) 1
2

# 無名関数（2引数）
nix-repl> (a: b: a + b) 1 2
3
```

### Attribute Setと関数

Nix言語ではAttrSetを引数にとる関数を頻繁に利用するため、いくつかの便利な構文が用意されています。

#### Attributeを取り出す

```nix :Before
# { a = Number; b = Number; } -> Number
set: a + b
```

```nix :After
# { a = Number; b = Number; } -> Number
{ a, b }: a + b
```

#### 余分なattributeを無視する

```bash :...構文
# 普通に関数を定義
nix-repl> add_a_b = { a, b }: a + b

# 余分なattributeがあるとエラーになる
nix-repl> add_a_b { a = 1; b = 2; c = 3; }
ERROR: attribute 'c' missing

# `...`で余分なattributeを無視
nix-repl> add_a_b = { a, b, ... }: a + b

# エラーにならない！
nix-repl> add_a_b { a = 1; b = 2; c = 3; }
3
```

#### @構文

Attributeを取り出しつつ、`@`でAttrSet全体を取得できます。

```nix :@構文
args @ { a, b, ... }: a + b + args.c

# 後置でもOK
# { a, b, ... } @ args : a + b + args.c
```

```bash :REPL
nix-repl> add_a_b_c = args @ { a, b, ... }: a + b + args.c

nix-repl> add_a_b_c { a = 1; b = 2; c = 3; }
6
```

#### ?構文

`?`を使って特定のattributeが含まれているかチェックし、存在しなければデフォルト値を使います。

```nix :?構文
{
  a ? 1,
  b ? 2
}:
a + b
```

```bash :REPL
nix-repl> add_a_b = { a ? 1, b ? 2 }: a + b

nix-repl> add_a_b {}
3
```

### assert式

```:assertのカタチ
assert <条件式>; <式>
```

`assert`を使って検証を行うことができます。条件が真なら`;`以降の式を返し、偽なら例外を発生させます。

```nix :第二引数がゼロの場合、例外を発生させる関数
# Number -> Number -> Number
dividend: divisor:
assert divisor != 0;
dividend / divisor
```

```bash :REPL
nix-repl> divide = dividend: divisor: assert divisor != 0; dividend / divisor

# 正常な計算
nix-repl> divide 9 3
3

# ゼロ除算でエラー
nix-repl> divide 9 0
error: assertion '(divisor != 0)' failed

       at «string»:1:21:

            1|  dividend: divisor: assert divisor != 0; dividend / divisor
             |                     ^
```

## ループはないの？

大抵の関数型言語には`for`/`while`/`loop`といった構文がありません。代わりに再帰関数を使います。以下に5の階乗を計算する再帰関数を示します。

```nix :factorial5.nix
let
  f = n:
    if n == 0
      then 1
      else n * f (n - 1);
in
f 5
```

```bash :factorial5.nixの評価
$ nix eval --file ./factorial.nix
120
```

このセクション以降、再帰的な処理を書くことはないのでこれ以上詳しくは触れません。

興味がある方には、こちらの記事をおすすめします。

https://blog.ryota-ka.me/posts/2018/12/15/lazy-lists-in-nix-expressions-language#map-%E9%96%A2%E6%95%B0filter-%E9%96%A2%E6%95%B0

## どうやってパッケージをビルドするのか？

ここまで紹介してきた言語機能は非常に基本的なもので、到底パッケージのビルドなどはできません。実際にビルドを行うときは以下の機能を用います。

- derivation関数
- Import From Derivation

いずれもNixストアと相互作用する機能です。これらについては「1.4. Nix言語とderivation」で詳しく解説します。
