---
title: "　§4. Nix言語とderivation"
---

いよいよNix言語の核心に迫ります。これまで紹介してきたNix言語の機能はどれも基本的なもので、到底パッケージのビルドなどはできません。実際にビルドを行うにはNixのビルドシステムと連携する必要があります。

このセクションでは**derivation関数**と**IFD**（**Import From Derivation**）について学び、Nix言語がNixストアとどのように連携しているのかを理解しましょう。

## derivation関数

derivation関数はNix言語の最も重要な関数です。この関数はAttrSetを受け取ってAttrSetを返し、副作用としてNixストアにstore derivationを生成します。

```:derivationの型
derivation :: AttrSet -> AttrSet
```

---

derivation関数を使ってみましょう。以下のNixファイルを作成します。

```nix :drv.nix
derivation {
  name = "hello-txt";
  builder = "/bin/sh";
  args = [
    "-c"
    "echo -n Hello > $out"
  ];
  system = builtins.currentSystem;
}
```

`name`はパッケージ名、`builder`はビルドを実行する実行可能ファイルのパス、`args`は`builder`に渡す引数です。`system`にはビルドターゲットのプラットフォームを指定します。

今回はあくまで例なので`builder`に`/bin/sh`を指定し、`system`に非純粋な組み込み関数`currentSystem`を入れています。実際のビルドでは`builder`には基本的にbashのストアパスが指定されます。

評価するとAttrSetが得られます。

```bash
# 見やすさのために評価結果に改行を入れています
$ nix eval --file ./drv.nix
{
  all = [ «repeated» ];
  args = [ "-c" "echo -n Hello > $out" ];
  builder = "/bin/sh";
  drvAttrs = {
    args = «repeated»;
    builder = "/bin/sh";
    name = "hello-txt";
    system = "x86_64-linux";
  };
  drvPath = "/nix/store/ybkx07yfg2w33mr909bk2g7z0264sy4x-hello-txt.drv";
  name = "hello-txt";
  out = «repeated»;
  outPath = "/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt";
  outputName = "out";
  system = "x86_64-linux";
  type = "derivation";
}
```

`drvPath`が指すファイルパスを確認してみましょう。Store derivation（`.drv`ファイル）が生成されていることが確認できます。

```bash :Store derivationの確認
$ cat /nix/store/ybkx07yfg2w33mr909bk2g7z0264sy4x-hello-txt.drv
# Store derivationの内容が表示される
```

次は`outPath`を確認してみます。

```bash :outPathの確認
$ cat /nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt
cat: /nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt: No such file or directory
```

`outPath`はビルド成果物が配置されるストアパスを示しているのですが、今はまだ何も存在しません。実際にビルドを行うにはderivation関数が生成したstore derivationをrealiseする必要があります。

### Instantiation

derivation関数の返り値としてstore derivationが出力されるのではなく、**derivation関数の副作用としてstore derivationが生成されます**。これを**Instantiation**と呼びます。

副作用と聞くとNix言語の純粋関数型言語としての性質と相反するように思えますが、Nixストアとビルドシステムとの連携により全体としては純粋なシステムとして機能しています。暗黙的な挙動ではありますが、Nix言語の評価やビルドの決定性を損うものではありません。

### Store derivation

Store derivationの内容をJSON形式で表示してみましょう。`nix derivation show`コマンドを使います。

```bash
$ nix derivation show --file ./drv.nix
{
  "/nix/store/ybkx07yfg2w33mr909bk2g7z0264sy4x-hello-txt.drv": {
    "args": ["-c", "echo -n Hello > $out"],
    "builder": "/bin/sh",
    "env": {
      "builder": "/bin/sh",
      "name": "hello-txt",
      "out": "/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt",
      "system": "x86_64-linux"
    },
    "inputDrvs": {},
    "inputSrcs": [],
    "name": "hello-txt",
    "outputs": {
      "out": {
        "path": "/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt"
      }
    },
    "system": "x86_64-linux"
  }
}
```

`env`キーに注目してください。ここには、このstore derivationをrealiseするとき（つまり実際にビルドを実行するとき）にビルド環境で有効化される環境変数が指定されています。

このstore derivationは最もシンプルな形なので、以下の環境変数が指定されています。

| 環境変数名 | 内容                                   |
| ---------- | -------------------------------------- |
| builder    | ビルドを実行する実行可能ファイルのパス |
| name       | パッケージ名                           |
| out        | ビルド成果物を配置するストアパス       |
| system     | ビルドターゲットのプラットフォーム     |

このstore derivationをrealiseすると、Nixはサンドボック化されたビルド環境で`/bin/sh -c "echo -n Hello > $out"`を実行します。つまり、`$out`に`Hello`という文字列を書き込みます。

### Realisation

先程生成したstore derivationをrealiseし、実際にビルドを実行します。

```bash :Realise
$ nix-store --realise /nix/store/ybkx07yfg2w33mr909bk2g7z0264sy4x-hello-txt.drv
/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt

$ cat /nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt
Hello
```

ビルドが成功し、`outPath`に`Hello`という文字列が書き込まれたファイルが生成されました。

後述するIFDを除き、基本的にNix言語自体がrealisationを実行することはできません。Nix言語はstore derivationを生成するDSLとして機能し、Nixのコマンド（`nix-store --realise`/`nix build`など）が実際のビルドを行います。

## 実際のパッケージのstore derivation

先程例として示したstore derivationは非常にシンプルなもので、実際のパッケージの場合はもっと複雑です。以下にNixpkgsに収録されているGNU Helloを評価した際に生成されるstore derivationを示します。長いので折り畳んでいます。
:::details GNU Helloのstore derivation

```json
{
  "/nix/store/9hxg3racppqcn970nbj5mk3a8qm9kss7-hello-2.12.1.drv": {
    "args": [
      "-e",
      "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
    ],
    "builder": "/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin/bash",
    "env": {
      "__structuredAttrs": "",
      "buildInputs": "",
      "builder": "/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin/bash",
      "cmakeFlags": "",
      "configureFlags": "",
      "depsBuildBuild": "",
      "depsBuildBuildPropagated": "",
      "depsBuildTarget": "",
      "depsBuildTargetPropagated": "",
      "depsHostHost": "",
      "depsHostHostPropagated": "",
      "depsTargetTarget": "",
      "depsTargetTargetPropagated": "",
      "doCheck": "1",
      "doInstallCheck": "1",
      "mesonFlags": "",
      "name": "hello-2.12.1",
      "nativeBuildInputs": "/nix/store/cg6y5cyhfdkb6pqiqjvrr7g9gy93by7h-version-check-hook",
      "out": "/nix/store/39z5zpb72qrnxl832nwphcd4ihfhix3j-hello-2.12.1",
      "outputs": "out",
      "patches": "",
      "pname": "hello",
      "postInstallCheck": "stat \"${!outputBin}/bin/hello\"\n",
      "propagatedBuildInputs": "",
      "propagatedNativeBuildInputs": "",
      "src": "/nix/store/pa10z4ngm0g83kx9mssrqzz30s84vq7k-hello-2.12.1.tar.gz",
      "stdenv": "/nix/store/hix7sl0wxajb5aq14afjdvzc3w0i8b14-stdenv-linux",
      "strictDeps": "",
      "system": "x86_64-linux",
      "version": "2.12.1"
    },
    "inputDrvs": {
      "/nix/store/1pmgv5n6qr9b96jvhli7zj0fs6vmaz9p-version-check-hook.drv": {
        "dynamicOutputs": {},
        "outputs": ["out"]
      },
      "/nix/store/2miv8n4k7nram4qnbjfjcg400dzkzcdg-bash-5.2p32.drv": {
        "dynamicOutputs": {},
        "outputs": ["out"]
      },
      "/nix/store/8fpibqm1vvfdgmm7ba13wbanpv6pg4hb-hello-2.12.1.tar.gz.drv": {
        "dynamicOutputs": {},
        "outputs": ["out"]
      },
      "/nix/store/h7lm4p6i89k48q8qqcl02z0g4sqwzh5v-stdenv-linux.drv": {
        "dynamicOutputs": {},
        "outputs": ["out"]
      }
    },
    "inputSrcs": [
      "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
    ],
    "name": "hello-2.12.1",
    "outputs": {
      "out": {
        "path": "/nix/store/39z5zpb72qrnxl832nwphcd4ihfhix3j-hello-2.12.1"
      }
    },
    "system": "x86_64-linux"
  }
}
```

:::

まず、`builder`にbashのストアパスが指定されており、`args`にもシェルスクリプトファイルのストアパスが含まれています。そして先程の例では空だった`inputDrvs`にいくつかのstore derivationが指定されています。これらはパッケージをビルドする際に必要な依存です。
そして`env`にはたくさんの環境変数が指定されています。特に注目すべきは`src`で、ここにはGNU Helloのソースコード（tarball）のストアパスが指定されています。

derivation関数だけを使ってこのような複雑なstore derivationを生成するのはとても大変なので、実際のパッケージビルドではNixpkgsから提供されている**stdenv**を使用します。stdenvはderivation関数をラップしており、より直感的にビルド定義を記述することができます。詳細は[_3.1. stdenv_](ch03-01-stdenv)で解説します。

## Import From Derivation

Nix式の値はストアオブジェクトに依存することができます。`import`や`readFile`を使ってストアオブジェクトを読み込むと**Import From Derivation**（**IFD**）が発生します。

一旦先程realiseしたストアオブジェクトを削除します。

```bash :ストアオブジェクトの削除
$ nix store delete /nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt
1 store paths deleted, 0.00 MiB freed
```

:::message
`nix store delete`は「安全な削除^[依存関係の不整合を発生させないために、他のパッケージから参照されているか否かを判定します。Nixはパッケージ間の依存関係をデータベースで管理しており、大量のパッケージが存在する場合は解析に時間がかかります。]」を行うため、時間がかかる可能性があります。
:::

新たなNix式を作成します。

```nix :IFD.nix
let
  drv = import ./drv.nix;
in
builtins.readFile drv.outPath
```

`drv`変数に`drv.nix`を読み込みます。

`drv.outPath`が示すファイルは先程削除しました。derivation関数でstore derivationを生成しても、realiseしない限り`drv.outPath`が示すストアパスにファイルは存在しないので、`readFile`は失敗するはずです。評価してみましょう。

```bash :drv.nixの評価
$ nix eval --file ./IFD.nix
"Hello"
```

なんと成功してしまいました。

これは不正な挙動ではありません。
Nix式の評価中、ストアオブジェクトへのアクセスが必要とされる場面に遭遇すると、Nixは自動的にstore derivationをrealiseするのです。これがIFDです。Nix言語は、Nix式の評価中にinstantiationだけでなく、realisationも行う場合があります。

IFDは、以下の組み込み関数でストアパスにアクセスしたときだけ発生します。いずれもファイルシステムにアクセスする関数です。

- **import**
- **readFile**
- readFileType
- readDir
- pathExists
- filterSource
- path
- hashFile
- scopedImport

IFDはNix式の評価をブロックします。IFDが発生すると評価が一時的に中断され、対象のrealise（つまりビルドの実行）が終了するまで待機します。Realisationが完了するとNix式の評価が再開されます。
例えば、realise対象が長いコンパイル時間を要するパッケージだった場合、その時間分だけNix式の評価時間も長くなります。また、IFD中にrealisationが失敗するとNix式の評価も失敗します。

やや難しい概念ですが、公式リファレンスの図を見るとイメージしやすいかもしれません。

https://nix.dev/manual/nix/2.20/language/import-from-derivation#illustration

## Derivation型

derivation関数が返すAttrSetを便宜上Derivation型と呼ぶことにします。Derivation型は通常のAttrSetと異なり、以下の特別な扱いを受けます。

1. `toString`を適用すると、ストアパスが返ってくる
2. `"${}`で文字列に埋め込むと、ストアパス文字列に変換される
3. String型を引数にとる組み込み関数を適用すると、ストアパス文字列として適用される
4. Path型を引数にとる組み込み関数を適用すると、ストアパスとして適用される

Derivation型は実際のビルド式では至るところで利用されるので、利便性のためにこのような挙動になっているのだと思われます。

:::details 厳密には「型」ではない
動的型付け言語の「型」とは、実行中に変数ではなく値に付与されるラベルです。Nix言語にはそのような型を判定する組み込み関数（e.g. `isNumber`/`isFloat`/`isAttrs`）がありますが、`isDerivation`関数はありません。厳密には「Derivation型」は存在せず、特定のattributeを持ったAttrSetでしかありません。

ただし、REPLでderivation関数を評価すると`<<derivation>>`と表示されることや後述の挙動を見る限り特別扱いされていることは間違いありません。そのため、本書では便宜上「Derivation型」と呼ぶことにします。

```bash: REPLでdrv.nixを評価
nix-repl> import ./drv.nix
«derivation /nix/store/ybkx07yfg2w33mr909bk2g7z0264sy4x-hello-txt.drv»
```

:::

### 1. toStringとDerivation型

通常、AttrSetに`toString`関数を適用すると、`__toString` attributeが存在しない限りエラーとなりますが、Derivation型の場合はエラーにならず、文字列に変換された`outPath`が返ってきます。

```bash
nix-repl> drv = import ./drv.nix

nix-repl> drv.outPath
"/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt"

nix-repl> builtins.toString drv
"/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt"
```

### 2. 文字列埋め込みとDerivation型

`toString`と同様に文字列に変換された`outPath`が埋め込まれます。

```bash
nix-repl> drv = import ./drv.nix

nix-repl> drv.outPath
"/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt"

nix-repl> "${drv}"
"/nix/store/z4j03hs3qk7a3cbiwglgys2cz61pbi6s-hello-txt"
```

### 3. String型を引数にとる組み込み関数とDerivation型

`stringLength`関数はStringを引数にとり、その長さを返します。Derivation型に適用すると、文字列に変換された`outPath`の長さが返ってきます。

```bash
nix-repl> drv = import ./drv.nix

nix-repl> builtins.stringLength drv.outPath
53

nix-repl> builtins.stringLength drv
53
```

### 4. Path型を引数にとる組み込み関数とDerivation型

そのまま`outPath`に適用されます。

```bash
nix-repl> drv = import ./drv.nix

nix-repl> builtins.readFile drv.outPath
"Hello"

nix-repl> builtins.readFile drv
"Hello"
```

## Nix言語は「純粋」なのか？

IFDの存在は、Nix言語の評価がrealisation（ビルドの実行）に依存することを意味します。

一見、言語の評価がパッケージビルドに依存するのは問題があるように思えますが、それはビルドが決定論的でない場合の話です。Nixのビルドシステムは決定論的であり、必ず同じ結果を返します。もしrealiseに失敗したら、それは「絶対に失敗する」ときです。
Nix言語の評価が決定論的であることと、ビルドが決定論的であることはほとんど等価です。

また、store derivationの生成やIFDはNix言語からは隠蔽されており、Nix言語世界は純粋に保たれています。Nix言語はstore derivationに直接触れることができません。IFDを通じてのみ、間接的にstore derivationをrealiseすることができます。

## 参照

https://nix.dev/manual/nix/2.22/language/derivations

https://nix.dev/manual/nix/2.22/language/import-from-derivation
