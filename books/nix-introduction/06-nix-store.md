---
title: "Nixストア"
---

**Nixストア**はビルドシステムと双璧をなすNixの最も重要な概念の一つです。
前章では純粋関数的なビルドシステムが暗黙的依存を排除することを学びました。Nixストアは依存関係を共有可変状態ではなく、不変の分離された状態で管理することで依存関係の衝突を防ぎます。

NixストアはNixのパッケージ管理機構であり、実体は`/nix/store`というディレクトリです。Nixによってビルドされたものは全てNixストアに格納されます。Nixストアに格納されたものは**ストアオブジェクト**（**Store Object**）と呼ばれます。

本パートでは`curl`を例にとり、Nixストアがどのようにパッケージを管理するのかを見ていきます。

## ストアパス^[[4.3. Store Path - Nix Reference Manual](https://nixos.org/manual/nix/stable/store/store-path)]

筆者の環境の`curl`は以下のパスに格納されていました。

```bash
/nix/store/dzs2chgxcwzpwplcw6wvv8nzkn01yr7y-curl-8.6.0-bin/bin/curl
```

`/nix/store`下にあるのはいいとして、この長いファイルパスは何を意味しているのでしょうか。

ストアオブジェクトにはハッシュが識別子として付与されたファイルパス、**ストアパス**（**Store Path**）が与えられます。

```bash
dzs2chgxcwzpwplcw6wvv8nzkn01yr7y-curl-8.6.0-bin

# ハッシュ
dzs2chgxcwzpwplcw6wvv8nzkn01yr7y

# パッケージ
curl-8.6.0-bin
```

`curl`のストアオブジェクトは以下のようなディレクトリ構造になっています。

```
/nix/store/dzs2chgxcwzpwplcw6wvv8nzkn01yr7y-curl-8.6.0-bin/
└── bin/
  └── curl
```

ストアパスのハッシュはビルド入力を元に生成されます。
依存関係、ソースコード、環境変数、etc...これらの情報が1ビットでも異なると全く異なるハッシュが生成されます。

![Nixによるビルドとハッシュ計算](/images/nix-introduction/build-and-hash.png)

### 複数バージョンの共存

ハッシュによるパッケージの区別は依存関係の衝突を防ぐ手段として非常に有効的です。以下に筆者の環境に存在する**全ての**curlパッケージを示します。

```
/nix/store/0mjq6w6cx1k9907vxm0k5pk7pm1ifib3-curl-8.4.0-bin
/nix/store/c58hy8bh832hd9m4hkslk71zl98g7h7n-curl-8.2.1-bin
/nix/store/dzs2chgxcwzpwplcw6wvv8nzkn01yr7y-curl-8.6.0-bin
/nix/store/j1yhiywlyh13ayzx46lzh7h1y7cq9p9c-curl-8.5.0-bin
/nix/store/vcvcpdn0bspcl722qkwp2s72wws9gw7s-curl-7.72.0-bin
/nix/store/x23aqwc39pp4zx5iiz0mqyh5mnvrz43z-curl-8.6.0-bin
```

`8.6.0`や`8.2.1`など複数のバージョンのcurlが共存しています。通常、パッケージの更新は古いバージョンを上書きすることになります。しかし、Nixストアではパッケージの内容に差違があると異なるストアパスが生成され、結果として異なるディレクトリにパッケージが配置されるため、上書きが発生しません。Nixストア内のパッケージは削除されるまで永久にイミュータブルに扱われます。

ちょっと待ってください！なぜかバージョン`8.6.0`のcurlが2つあります。これは同じバージョンでもビルド時のオプションや依存しているパッケージなど、バージョン以外のパッケージを同定する要素が異なるためです。ほんの些細な違いでもNixはそれを別のパッケージとして厳密に区別します。Nixによるパッケージ管理において、バージョンは「人間にとって分かりやすい」程度の意味しかありません。

## 依存関係の管理

### ビルド時依存

Nixはビルドの入力をただの名前やバージョンといった曖昧なものではなく、ストアパスで指定します。ハッシュによってパッケージの依存関係が一意に定まるため、ビルドの再現性が保証されます。さらにビルドシステムによる暗黙的依存の排除によって完全な依存関係のツリーが構築されます。

### 実行時依存^[[9.3. Runtime dependencies - Nix Pills](https://nixos.org/guides/nix-pills/automatic-runtime-dependencies)]

Nixストアでパッケージのビルド時依存が解決されていることは分かりましたが、実行時依存はどうなっているのでしょうか。

`ldd`で`curl`に動的リンクされている共有ライブラリを確認します。

```bash
$ ldd $(which curl)
linux-vdso.so.1 (0x00007ffc009f8000)
libcurl.so.4 => /nix/store/wl49n8fs5vd1zcjwfyjvp7z78d9wxbhr-curl-8.6.0/lib/libcurl.so.4 (0x00007fa9a1c35000)
libssl.so.3 => /nix/store/lvdxawlh51yk1jxx5s0k67mxkil4kq35-openssl-3.0.13/lib/libssl.so.3 (0x00007fa9a1b87000)
libcrypto.so.3 => /nix/store/lvdxawlh51yk1jxx5s0k67mxkil4kq35-openssl-3.0.13/lib/libcrypto.so.3 (0x00007fa9a1600000)
libz.so.1 => /nix/store/bqwpsy99nbgp918w3mwn73jygm1i5ck4-zlib-1.3.1/lib/libz.so.1 (0x00007fa9a1b69000)
libc.so.6 => /nix/store/ksk3rnb0ljx8gngzk19jlmbjyvac4hw6-glibc-2.38-44/lib/libc.so.6 (0x00007fa9a1417000)
libnghttp2.so.14 => /nix/store/i5layvdnbjxlbgdb764pafq5rlm1bnfx-nghttp2-1.59.0-lib/lib/libnghttp2.so.14 (0x00007fa9a1b37000)
libidn2.so.0 => /nix/store/krqp9wj3rgalmqv04y0sqw987mxsnddn-libidn2-2.3.7/lib/libidn2.so.0 (0x00007fa9a1b06000)
libssh2.so.1 => /nix/store/kxban1v2m6d5zm3q95ivy7la7sjgj3kl-libssh2-1.11.0/lib/libssh2.so.1 (0x00007fa9a1ac0000)
libpsl.so.5 => /nix/store/vzr75ghvjw89wph6pp9ifipqvcwvdag6-libpsl-0.21.5/lib/libpsl.so.5 (0x00007fa9a1aaa000)
libgssapi_krb5.so.2 => /nix/store/mmccprkxbzn2iqn1rsj3lx32lcrgpg3j-libkrb5-1.21.2/lib/libgssapi_krb5.so.2 (0x00007fa9a13c3000)
libzstd.so.1 => /nix/store/bamq0s7n2hqmsnf7hyspc1xxrpsiy8y9-zstd-1.5.5/lib/libzstd.so.1 (0x00007fa9a12f3000)
libbrotlidec.so.1 => /nix/store/a7scr3ghdq6fh27a2azs417nsny6m50s-brotli-1.1.0-lib/lib/libbrotlidec.so.1 (0x00007fa9a1a9c000)
libdl.so.2 => /nix/store/ksk3rnb0ljx8gngzk19jlmbjyvac4hw6-glibc-2.38-44/lib/libdl.so.2 (0x00007fa9a1a97000)
libpthread.so.0 => /nix/store/ksk3rnb0ljx8gngzk19jlmbjyvac4hw6-glibc-2.38-44/lib/libpthread.so.0 (0x00007fa9a1a90000)
/nix/store/ksk3rnb0ljx8gngzk19jlmbjyvac4hw6-glibc-2.38-44/lib/ld-linux-x86-64.so.2 => /nix/store/cyrrf49i2hm1w7vn2j945ic3rrzgxbqs-glibc-2.38-44/lib64/ld-linux-x86-64.so.2 (0x00007fa9a1cf5000)
libunistring.so.5 => /nix/store/vqvbn2z8wyrjwvayjb2vy5krhh1kis9b-libunistring-1.1/lib/libunistring.so.5 (0x00007fa9a1142000)
libkrb5.so.3 => /nix/store/mmccprkxbzn2iqn1rsj3lx32lcrgpg3j-libkrb5-1.21.2/lib/libkrb5.so.3 (0x00007fa9a106b000)
libk5crypto.so.3 => /nix/store/mmccprkxbzn2iqn1rsj3lx32lcrgpg3j-libkrb5-1.21.2/lib/libk5crypto.so.3 (0x00007fa9a103c000)
libcom_err.so.3 => /nix/store/mmccprkxbzn2iqn1rsj3lx32lcrgpg3j-libkrb5-1.21.2/lib/libcom_err.so.3 (0x00007fa9a1a87000)
libkrb5support.so.0 => /nix/store/mmccprkxbzn2iqn1rsj3lx32lcrgpg3j-libkrb5-1.21.2/lib/libkrb5support.so.0 (0x00007fa9a102e000)
libkeyutils.so.1 => /nix/store/fjb02lzkzribw57bk9a5c89xaznlm5p7-keyutils-1.6.3-lib/lib/libkeyutils.so.1 (0x00007fa9a1a80000)
libresolv.so.2 => /nix/store/ksk3rnb0ljx8gngzk19jlmbjyvac4hw6-glibc-2.38-44/lib/libresolv.so.2 (0x00007fa9a101d000)
libm.so.6 => /nix/store/ksk3rnb0ljx8gngzk19jlmbjyvac4hw6-glibc-2.38-44/lib/libm.so.6 (0x00007fa9a0f3b000)
libbrotlicommon.so.1 => /nix/store/a7scr3ghdq6fh27a2azs417nsny6m50s-brotli-1.1.0-lib/lib/libbrotlicommon.so.1 (0x00007fa9a0f16000)
```

なんと全てストアパスが指定されています。Nixは`/usr/bin`や`/usr/lib`といったグローバルなファイルパスを参照せず、個別で一意なストアパスを指定するようにしています。

Nixの開発元は、実行可能ファイルにリンクされている共有ライブラリの参照先を変更できる[patchelf](https://github.com/NixOS/patchelf)というパッチツールも提供しており、徹底ぶりが伺えます。

https://github.com/NixOS/patchelf

## トレードオフ

Nixストアはパッケージを厳密に区別するため、ストレージの消費量が多くなる傾向にあります。このように依存関係により、ストレージが圧迫されることも依存関係地獄の一種と見なされています。

ストレージの問題を完全に解決できるわけではありませんが、Nixは**ガベージコレクション**という不要なパッケージを自動的に削除する機構によって、この問題に対処しています。詳細は「ガベージコレクション」の章で説明します。
