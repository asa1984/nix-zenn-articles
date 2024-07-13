---
title: "Flakes"
---

**Flakes**とは、"Nix言語の"依存関係管理システムです^[[8.5.15. nix flake - Nix Reference Manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake)]。Rustに対するCargo、Node.jsに対するnpm、Pythonに対するpip、Nix言語に対するFlakesというように、Nix言語の依存関係管理を行うのがFlakesです。

そもそもNixが依存関係管理システムなのに、また別の依存関係管理システム？と困惑しているかもしれませんが、前章の内容を思い出してください。NixにおけるパッケージリポジトリとはNix言語のライブラリなのでした。つまり、Nixでパッケージリポジトリを利用するというのは、Nix言語の外部ライブラリを依存関係として導入するということなのです。

Nixによるパッケージビルドの流れを見ると、Nixは他のビルドシステムよりも段階が1つ多いことが分かります。大抵のビルシステムは人間がビルドレシピを書き、それを元にビルドを実行しますが、Nixの場合は人間がNix言語を書き、厳密なビルドレシピ（Derivation）を生成し、それを元にビルドします。

Nixで依存関係の解決が行われるタイミングは2回あります。1回目はNix式を評価する時で、FlakesがNix言語の依存関係を解決します。2回目はDerivationのrealise時で、NixストアがDerivationの依存関係を解決します。

![Flakesの図解](/images/nix-introduction/flakes.png)
_Flakesによるビルドの流れ_

つまり、FlakesはNixの高レベル表現世界の依存関係管理システムです。

## Flake

FlakesではNix言語のパッケージに相当するものを**Flake**と呼びます。ちょうどRustのパッケージがCrateと呼ばれるのと同じです。

FlakesはGitとの併用を前提としており、Flakeの実体は`flake.nix`という特別なファイルをルートに配置したGitリポジトリです。
`flake.nix`はnpmの`package.json`やCargoの`Cargo.toml`のような役割を果たします。拡張子を見て分かる通り、`flake.nix`自体もNix言語で記述されています。また、`flake.nix`はNix言語のエントリポイントとして振る舞います。

`flake.nix`の構造は非常にシンプルで、プロジェクトが依存するFlake（**inputs**）とプロジェクトが出力するNix式（**outputs**）が記述されています。
Flakeを評価したとき、Nixはinputsに指定されているFlakeを取得し、それらのoutputsを現在評価しているFlakeのoutputsの引数に渡します。依存解決もシンプルです。

### 依存関係の固定

モダンなパッケージマネージャがlockファイルによって依存関係の固定するように、Flakesも`flake.lock`ファイルによるinputsのバージョン固定を行います。Flakesは**Gitのコミットハッシュ**によって依存関係を固定します。つまり、Flake（≒パッケージリポジトリ）のバージョンがコミットレベルで同一になります。同じNix式は同じDerivationを出力し、同じDerivationは同じパッケージを出力するため、Nixの再現性はもはや完全といっていいでしょう。

### 利用可能なファイルの制限

FlakesがGitを利用するのは依存関係の固定だけではありません。
Nix言語はファイルの読み取りができます。主にソースコードやビルドスクリプトの取得に用いられるのですが、読み取り対象のファイルパスを無制限に指定できるため、場合によってはファイルがあったりなかったりするという問題が発生する可能性があります。Flakesは、FlakeのGitリポジトリの管理下にないファイルへのアクセスを制限します。例えばリポジトリ外のファイルや`.gitignore`で除外されているファイル、ステージングされていないファイルにアクセスしようとするとNix言語はエラーを起こします。

FlakesはNix言語の純粋性を高める機能でもあります。

## inputs

inputsにはFlakeのURLまたはファイルパスを指定します。

```nix
{
  inputs = {
    # GitHubリポジトリを指定
    example-github.url = "github:オーナー/リポジトリ/ブランチ";

    # Flakeのアーカイブを指定
    example-archive.url = "https://example.com/example.tar.gz";

    # Flakeのローカルディレクトリを指定
    example-directory.url = "path:/path/to/flake";
  };
}
```

基本的にGitHubリポジトリを指定することが多いですが、URLでアーカイブを指定することもできます。GitHubリポジトリを指定する場合は`flake.lock`がGitを利用して勝手にバージョン固定を行ってくれますが、アーカイブを指定する場合はURLに対してコンテンツが不変でなければいけません。

Nix専門の企業[Determinate Systems](https://determinate.systems)は、[FlakeHub](https://flakehub.com)というFlake共有プラットフォームを提供しています。こちらはアーカイブでFlakeを提供しています。

https://flakehub.com

## outputs^[[Flakes - NixOS Wiki](https://nixos.wiki/wiki/Flakes#Output_schema)]

outputsは関数になっており、Flakeの評価時にinputsに指定したFlakeのoutputsが引数に渡されます。outputsはAttribute Setを返します。

実は、outputsで返せるのはパッケージだけではありません。outputsには以下のようなものを指定できます。

```nix
{
  inputs = {
    # 依存するFlake
  };

  outputs = inputs: {
    packages."<システムアーキテクチャ>"."<パッケージ名>" = derivation;
    devShells."<システムアーキテクチャ>"."<devShellの名前>" = derivation;
    formatter."<システムアーキテクチャ>"."<パッケージの名前>" = derivation;
    templates."<テンプレートの名前>" = {
      path = "<ストアパス>";
      description = "テンプレートの説明";
    };

    # ...その他多数
  };
}
```

上記以外にも複数のattributeを指定することができ、またサードパーティのプログラムによって拡張することができます。例えば[deploy-rs](https://github.com/serokell/deploy-rs)というNixOSのデプロイツールは、Flakeのoutputsにdeployという名前のattributeが存在することを期待しますが、これはdeploy-rs独自のものです。
Flakeのoutputsと言ってもただのNix言語に過ぎないので、それを評価するプログラム次第で様々な使い方ができます。

### packages

packagesにはその名の通りパッケージのDerivationを指定します。ここに指定したDerivationは`nix build`でビルド、`nix run`でビルド & 実行することができます。

### devShells

devShellは宣言的な開発環境構築機能です。`nix develop`コマンドで利用することができます。

`nix develop`は、Flakeのoutputsの`devShells`に`mkShell`関数の返り値が来ることを期待します。`mkShell`はNixpkgsが提供する特別な関数です。

```nix
mkShell {
  packages = [
    # 利用したいパッケージ
  ];
  shellHook = ''
    # devShell起動時に実行したいシェルスクリプト
  '';
}
```

`mkShell`が返すDerivationをrealiseすると、シェルスクリプトが記述されたテキストがビルドされます。このシェルスクリプトは`mkShell`の引数に指定した`packages`をPATHに追加し、`shellHook`に記述したスクリプトをshellHook環境変数に代入します。

対して、`nix develop`は以下の順序で動作します。

1. Bashを起動
2. outputsのdevShellを読み取り、`mkShell`が返すDerivationをrealise
3. ビルドされたスクリプトを実行
4. shellHook環境変数の中身を実行
5. （`mkShell`で宣言したパッケージが導入された開発環境が完成！）

devShellでインストールしたパッケージはdevShell内でのみ有効化され、グローバルにはインストールされません。Pythonのvenvに近い機能ですが、devShellはあらゆるプログラミング言語で利用することができます。

devShellのいいところは、Dockerと違って仮想環境を使う必要がない上、既にホストシステムにインストールされているパッケージをそのまま利用できることです。これは非純粋な状態ですが、開発環境では純粋性よりも利便性を優先し、ビルドは純粋な環境で行うといった使い分けができます。

### formatter

Nix言語のフォーマッターのDerivationを指定します。大抵の場合、`nixfmt`, `alejandra`, `nixpkgs-fmt`が指定されます。`nix fmt`で実行できます。

### templates

templatesはディレクトリのテンプレートを定義できます。`nix flake init --template`で利用することができます。
