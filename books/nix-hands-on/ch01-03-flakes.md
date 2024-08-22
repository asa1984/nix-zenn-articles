---
title: "　§3. Flakeを作る"
---

これまで書いてきた単純なNix式には依存がありません。より複雑なNix式を書くようになると、外部の依存を追加する必要が出てきます。Nixのプロジェクト管理機能 兼 依存関係管理機能・**Flakes**を使って、Nix言語のプロジェクト・**Flake**を作成してみましょう。

## Flakesとは

Nixに慣れていない人はよくFlakesを「難しい」と言いますが、それは適切な説明がなされていないか、あるいは誤解があるためです。実際のところFlakesの機能は非常にシンプルです。

Node.js, Rust, Goなどの言語の経験がある人にとって、Flakesが行う処理のほとんどはとても馴染み深いものです。

Flakeを作成する場合、`flake.nix`（`package.json`/`Cargo.toml`/`go.mod`に相当）という特別なNixファイルでFlakeを宣言します。このファイルにはプロジェクトの依存関係やエクスポートするNix式を記述します。また、`flake.lock`（`package-lock.json`/`Cargo.lock`/`go.sum`に相当）というロックファイルで依存関係をロックし、プロジェクトの再現性を保ちます。

つまるところ、Flakesは現代的な言語ならばおおむね共通して搭載しているプロジェクト管理機能をNix言語に持ち込んだものです。それ以上のことはありません。

## 用語の整理

本書では以下の意味で用語を使い分けます。

- **Flakes**: Nix言語のプロジェクト管理機能兼依存管理機能
- **Flake**: Flakesで管理されるNix言語のプロジェクト
- `flake.nix`: Flakeを宣言するファイル
- `flake.lock`: Flakeの依存関係をロックするファイル
- **inputs**: Flakeの依存関係
- **outputs**: FlakeがエクスポートするNix式

## flake.nixの形式と役割

`flake.nix`の構造は非常にシンプルで、その実体は`inputs`と`outputs`というattributeを持ったAttrSetです（他にもattributeがあるが重要ではないため省略）。

```nix
{
  inputs = <AttrSet> # 依存するFlake、省略可
  outputs = <Function> # Flakeの出力
}
```

`flake.nix`はFlakeを宣言するだけでなく、Nix言語を評価する際のエントリーポイントとしても機能します。

## FlakeでHello world

一番最初に扱った`"Hello, world!"`を返すNix式をFlake化してみましょう。まず、`flake.nix`を作成します。

```bash
mkdir hello-world
cd hello-world
touch flake.nix
```

```nix :flake.nix
{
  # このFlakeには依存がないのでinputsを省略
  # inputs = { };

  outputs = _inputs: {
    hello = "Hello, world!";
  };
}
```

Flakeを評価してみましょう。

```bash
$ nix eval .#hello
Hello, world!
```

`.#hello`は`<ファイルパス>#<outputs関数の返り値のattribute>`という形式になっています。`#`の前はFlake reference（後述）で、`#`の後はoutputs関数の返すAttrSetのattributeを指定しています。

`flake.nix`は特別なNixファイルなので、通常のNix式とは評価のワークフローが異なります。
Flake評価時、Nixは`outputs`関数の引数にAttrSetを渡します。このAttrSetには`inputs`で指定した依存関係が含まれており、ここでFlakeの依存関係の解決が行われます。そして、`outputs`関数の返り値を最終的なFlakeの評価結果として返します。

## Flakeに依存を導入してみよう

次は、依存関係を持つFlakeを作成してみましょう。`sub`ディレクトリに別のFlakeを作成して、それを本体のFlakeで利用してみます。

```bash :subディレクトリにflake.nixを作成
mkdir ./sub
touch ./sub/flake.nix
```

```: ディレクトリ構成
./
├── sub/
│  └── fleke.nix <- 依存
└── flake.nix    <- 本体のFlake
```

`sub`ディレクトリのFlakeからは、2つの引数を取って`+`演算子を適用する関数を`add_a_b`としてエクスポートします。

```nix :./sub/flake.nix
{
  # add関数をエクスポートするFlake
  outputs = _inputs: {
    add_a_b = a: b: a + b;
  };
}
```

続いて、`sub`ディレクトリのFlakeを本体のFlakeのinputsで指定します。

```nix :./flake.nix
{
  inputs = {
    # "path:./sub" は、subデイレクトリのFlakeを示すflake-url（後述）
    sub_flake.url = "path:./sub";
  };

  outputs = { sub_flake, ... }: {
    # ./sub#addを使って 1 + 2 を計算
    sum_1_2 = sub_flake.add_a_b 1 2;
  };
}
```

最後に、実際に評価してみましょう。

```bash
$ nix eval .#sum_1_2
3
```

成功です！

初回評価時、`flake.lock`が生成されることに注意してください。

## inputs

Flakesは中央集権的なレジストリ（e.g. [npmjs.com](https://www.npmjs.com), [crates.io](https://crates.io)）を持ちません。代わりに、GitHubリポジトリやFlakeのアーカイブを提供しているURLを直接指定します。このような分散型の方式はGoのモジュール管理機能とよく似ています。

依存するFlakeの指定には**Flake reference**というFlakeの場所を示す表現を用います。

```nix :flake.nix
{
  inputs = {
    local-flake.url = "path:./path/to/flake"; # ローカルのFlake
    github-flake.url = "github:owner/repo/branch"; # GitHubリポジトリ
    git-https-flake.url = "git+https://path/to/flake"; # Gitリポジトリ
    tarball-flake.url = "https://path/to/flake"; # tarball
    nested-flake.url = "github:owner/repo/branch?dir=path/to/flake"; # ルートにflake.nixがない場合
  };

  outputs = #省略
}
```

### Flake reference

Flake referenceの形式にはAttrSetによる表現とURLライクな構文による表現の2つがあります。上で示した例はURLライクな構文です。

#### AttrSetによる表現

この表現を使うことはあまりないです。

```nix
{
  type = "github";
  owner = "NixOS";
  repo = "nixpkgs";
}
```

#### URLライクな構文による表現

AttrSetで指定するよりも簡潔なので、大抵の場合URLライクな構文の方を使います。この構文に正しい呼び方はないようですが、Nixのmanページの表現に従って**flake-url**と呼ぶことにします。

flake-urlは`flake.nix`だけでなく、NixのCLIでも使う形式なので覚えておきましょう。

| 種類             | 形式                                  | 説明                                    |
| ---------------- | ------------------------------------- | --------------------------------------- |
| ローカルのFlake  | `path:./path/to/flake`                | ローカルのFlake                         |
| GitHubリポジトリ | `github:owner/repo/branch`            | GitHubリポジトリ                        |
| Gitリポジトリ    | `git+https://path/to/flake`           | 任意のGitリポジトリ（GitLabなど）       |
| アーカイブ       | `https://path/to/flake`               | FlakeをアーカイブしたtarballのURL       |
| `?dir`付きURL    | `<任意のflake-url>?dir=path/to/flake` | ルートに`flake.nix`がない場合の指定方法 |

ファイルパスについて、接頭辞`path:`を外すとエラーは出ませんが意味が変わってしまい、Flakeを評価する度に`flake.lock`が再生成されてしまうので注意してください。

実際は以上に示したもの以外の形式やパラメータもありますが、ここでは最も一般的なものを紹介します。詳細は公式リファレンスを参照してください。

https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-flake#flake-references

### flake.lock

`flake.lock`は依存関係をロックするためのファイルです。前述の例ではGitを使わずにFlakeを作成しましがた、基本的にFlakesはGitとの併用を前提としています。特にインターネット上でFlakeを公開するときはGitリポジトリ化は必須です。

Git管理下のFlakeを依存関係として導入する場合、`flake.lock`は**Gitのコミットハッシュ**を利用してバージョンをロックします。

例えば、以下のようなNixpkgsに依存するFlakeがあったとします。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = _: { }; # 返り値は省略
}
```

このFlakeを評価すると`flake.lock`が生成されます。今回は`nix flake lock`コマンドを使って手動でロックします。

```
$ nix flake lock
warning: creating lock file '/path/to/flake.lock'
```

`flake.lock`の中身を覗くとコミットハッシュが記述されていることが分かります。

```json :flake.lock
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1722073938,
        "narHash": "sha256-OpX0StkL8vpXyWOGUD6G+MA26wAXK6SpT94kLJXo6B4=",
        "owner": "NixOS",
        "repo": "nixpkgs",

        // ↓これがコミットハッシュ
        "rev": "e36e9f57337d0ff0cf77aceb58af4c805472bfae",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "ref": "nixpkgs-unstable",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

この例の場合は以下のコミットに対応します。

https://github.com/NixOS/nixpkgs/commit/e36e9f57337d0ff0cf77aceb58af4c805472bfae

一度ロックすると、以降は`flake.lock`に従って依存関係を解決するため、コミットレベルで同一のNix式を得られるようになります。

## outputs

```nix
{ inputs, self, ... }: <attrset>
```

outputsは、AttrSetを受け取りAttrSetを返す関数です。任意のAttrSetを返すことができるため、実質なんでもエクスポートすることができます。

しかし、何でも返せると言っても実際はある程度のルールがあり、Flakeの利用者が期待する出力を返すことが望ましいです。前述の例では説明を簡単にするために敢えてルールを無視しています。outputsのルールについては後の章で詳しく説明します。

### outputsの引数

- `inputs`: 最初にinputsで定義した依存するFlake
- `self`: Flake自身

## GitとFlake

FlakeをGitリポジトリ化すると、FlakesはGitによってファイルを追跡するようになります。例えば以下のNix式があったとします。

```nix
import ./something.nix
```

```nix
builtins.readFile ./something.nix
```

ここで`something.nix`がまだGitにステージングされていない（=未追跡）状態だったとします。この状態でFlakeを評価すると「ファイルパスが存在しない」というエラーが発生します。

FlakeはGitリポジトリ化されていることを検知すると、Gitを介してのみファイルを取得するモードに切り替わります。そのため、**Flakeに新たにファイルを追加した場合は、評価する前に一時的にでも`git add`を行う必要があります**。

FlakesはNix言語の再現性をより強固なものにするために、このようにGitを用いた厳密なファイル管理を行います。

:::details gitignore
Gitを介してファイルを追跡するので、`.gitignore`で指定されたファイルをFlakeで利用することはできません。

Flakesが登場するより前、ソースコードを読み込む際に無視すべきファイルまで読み込まないように`.gitignore`を解析してファイルをフィルターするという関数が使われることがありましたが、現在はFlakesが勝手に弾いてくれるので必要ありません。Flakesはまだ実験的機能という位置付けなので、そういったフィルター関数は今もNixpkgsに残っています。
:::

## Flakesと非純粋な組み込み関数

Flake内では非純粋な組み込み関数の利用が制限されています。

```nix :flake.nix
{
  # inputs = { };

  outputs = _: {
    now = builtins.currentTime;
  };
}
```

このFlakeを評価してみると、そもそも`currentTime`が`builtins`に存在しないというエラーが発生します。明示的に`--impure`を付けて評価するとエラーは出ません。

```bash :非純粋関数の制限とimpureオプション
$ nix eval .#now
error: attribute 'currentTime' missing

       at /nix/store/jwa6z6jlpmb8ln8w2p38401xrv6ny2a3-source/flake.nix:4:24:

            3|
            4|   outputs = _: { now = builtins.currentTime; };
             |                        ^
            5| }

$ nix eval --impure .#now
1723722280
```

エラーが出ない場合もあります。`getEnv`はエラーを返す代わりに常に空文字列を返すようになります。

```nix :flake.nix
{
  # inputs = { };

  outputs = _: {
    user = builtins.getEnv "USER";
  };
}
```

```bash :getEnvはエラーにならない
$ nix eval .#user
""

$ nix eval --impure .#user
"asahi"
```

## まとめ

- FlakesはNix言語のプロジェクトを管理する
- FlakesはNix言語の依存関係を解説する
- Flakeは任意のNix式をエクスポートする
- FlakeはGitと非純粋関数の制限でNix式の純粋性を保つ
- Gitと併用しているときは`git add`を忘れない
