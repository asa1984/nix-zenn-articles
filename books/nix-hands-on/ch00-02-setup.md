---
title: "Nixのセットアップ"
---

## Nixのインストール

公式のインストーラーではなく、Determinate Systemsの[nix-installer](https://github.com/DeterminateSystems/nix-installer)を利用します。

https://github.com/DeterminateSystems/nix-installer

nix-installerは、公式インストーラーに比べて以下のメリットがあります。

- アンインストーラー付属
- Linuxコンテナ環境に対応
- **FlakesとNix commandを自動で有効化**

本書ではFlakesとNix commandを基軸としたNixの使い方を解説します。この2つはNixの実験的機能であり、設定で有効化しないと使うことができません。本来はユーザーが手動で有効化しなければいけませんが、nix-installerはそれを自動で行ってくれます。

:::details 公式インストーラーでインストールした方へ

`~/.config/nix/nix.conf`または`/etc/nix/nix.conf`に以下の行を追加してください。

```
experimental-features = nix-command flakes
```

:::

:::details NixOS/home-managerユーザーへ

それぞれ以下の設定を追加してください。

1. NixOSを使っている場合

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

2. home-managerを使っている場合

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

:::

:::details 実験的機能で大丈夫なの？
FlakesとNix commandはその有用性から事実上のデファクトスタンダードとなっており、既に削除や大きな変更ができないレベルで普及しています。これからNixを学ぶ上でこれらを避ける理由はないので、本書ではこれらの機能をベースとした解説を行います。

これは余談なのですが、FlakesとNix commandの普及度に反し、これらを基軸に解説する資料が少ないというのが本書の執筆理由の1つでもあります。
:::

## 筆者の環境

本書に登場するコードは以下の環境の両方で動作確認を行っています。

| CPU    | 実行環境               | Nixのバージョン |
| ------ | ---------------------- | --------------- |
| x86_64 | Ubuntu 22.04 (Docker)  | Nix 2.20        |
| x86_64 | NixOS (nixos-unstable) | Nix 2.18        |

Linuxであれば問題なく動作するでしょう。
macOSに関しては筆者がMacを持っていないため、動作確認を行っていません。問題があれば気軽に[issue](https://github.com/asa1984/nix-zenn-articles)を立ててください。
