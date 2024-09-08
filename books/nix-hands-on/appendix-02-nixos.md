---
title: "付録B. NixOS"
---

本書では取り扱わなかったNixOSに興味がある方に向けたリンク集です。

## 入門資料

### NixOS & Flakes Book

FlakesベースのNixOSの使い方を学ぶことができる本です。NixOSの入門として最もおすすめのドキュメントです。

https://nixos-and-flakes.thiscute.world

### nix-starter-configs

こちらはドキュメントではなく、NixOSの設定のテンプレートです。最初の一歩を踏み出すのに役立つでしょう。

https://github.com/Misterio77/nix-starter-configs

## ブログ

### NixOSとRaspberry Piで自宅server

[ymgyt](https://github.com/ymgyt)さんが書かれている全5パートのブログです。自宅サーバーをNixOSとRaspberry Piで構築する方法が紹介されています。[deploy-rs](https://github.com/serokell/deploy-rs)を用いたNixOSのデプロイや[ragenix](https://github.com/yaxitech/ragenix)によるシークレット管理など、NixOSならではの題材が取り扱われています。

https://blog.ymgyt.io/entry/homeserver-with-nixos-and-raspberrypi-install-nixos/

### Tailscale on NixOS: A new Minecraft server in ten minutes

VPNサービス[Tailscale](https://tailscale.com)とNixOSを用いてMinecraftサーバーを構築する方法が紹介されています。Tailscaleによるネットワークの抽象化とNixOSの宣言的な設定が組み合わさると恐しいほど簡単にサーバーを構築できることが分かります。

https://tailscale.com/blog/nixos-minecraft

### ぼくが普段使っているOS - NixOSの話

筆者がNixOSを使い始めるきっかけとなった記事の1つです。

https://tech.dely.jp/entry/2018/12/03/110227

## 動画

### Nix in 100 Seconds

Nixと題されていますが、ほとんどはNixOSについての解説です。

https://youtu.be/FJVFXsNzYZQ?si=X5fVZeWxkSjz1qp-

## dotfiles

NixOSのdotfilesは他のLinuxディストリビューションとは一味違います。以下に列挙したdotfilesはスターの付き方からしてまずおかしいですが、面白い試みをしているものばかりなので、是非見てみてください。

https://github.com/Mic92/dotfiles
https://github.com/fufexan/dotfiles
https://github.com/Misterio77/nix-config
https://github.com/ryan4yin/nix-config
