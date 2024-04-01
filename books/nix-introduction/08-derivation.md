---
title: "Derivation"
---

Nixはパッケージをビルドするために**Derivation**と呼ばれるものを使用します。

Derivationとは、簡単に言うとパッケージのビルド手順を説明する超厳密なレシピです。ビルドシステムに与える入力や出力先のストアパスなどが情報として含まれています。この章では、Derivationの低レベル表現である**store derivation**について見ていきます。

## store derivation

store derivationとはNixストアに格納された`.drv`ファイルのことです^[[11. Glossary - Nix Reference Manual](https://nixos.org/manual/nix/stable/glossary.html?highlight=store%20derivation#glossary)]。store derivationも通常のパッケージと同様に、ストアオブジェクトとして一意なストアパスが与えられています。

`hello`パッケージのstore derivationを見てみましょう。`hello`コマンドは標準出力に`Hello, world!`と出力するだけのシンプルなプログラムで、C言語で書かれています。
以下は筆者の環境における`hello`パッケージのstore derivationをJSON形式にpretty printしたものです^[`nix derivation show nixpkgs#hello`の実行結果]。

```diff json :/nix/store/c92qcxlqc33fkwwbj4hdpi18wh9wmim3-hello-2.12.1.drv
 {
   "/nix/store/c92qcxlqc33fkwwbj4hdpi18wh9wmim3-hello-2.12.1.drv": {
     "args": [
       "-e",
       "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
     ],
+    "builder": "/nix/store/4vzal97iq3dmrgycj8r0gflrh51p8w1s-bash-5.2p26/bin/bash",
     "env": {
       "__structuredAttrs": "",
       "buildInputs": "",
       "builder": "/nix/store/4vzal97iq3dmrgycj8r0gflrh51p8w1s-bash-5.2p26/bin/bash",
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
       "doInstallCheck": "",
       "mesonFlags": "",
       "name": "hello-2.12.1",
       "nativeBuildInputs": "",
       "out": "/nix/store/7bl684y3qpxrv01ird085rpf5kl6rk6f-hello-2.12.1",
       "outputs": "out",
       "patches": "",
       "pname": "hello",
       "propagatedBuildInputs": "",
       "propagatedNativeBuildInputs": "",
       "src": "/nix/store/pa10z4ngm0g83kx9mssrqzz30s84vq7k-hello-2.12.1.tar.gz",
       "stdenv": "/nix/store/v099hqvw5z87423p4hz1vfhzaqa07dii-stdenv-linux",
       "strictDeps": "",
       "system": "x86_64-linux",
       "version": "2.12.1"
     },
+    "inputDrvs": {
+      "/nix/store/8brdx72cmmmjrap80d8x4k58f69h4247-stdenv-linux.drv": {
+        "dynamicOutputs": {},
+        "outputs": ["out"]
+      },
+      "/nix/store/y1j406svnfr5i2i78z4ybg8rg30ngmkj-bash-5.2p26.drv": {
+        "dynamicOutputs": {},
+        "outputs": ["out"]
+      },
+      "/nix/store/zm481qv2gsm86pb6c7k1sjhvhj3790kv-hello-2.12.1.tar.gz.drv": {
+        "dynamicOutputs": {},
+        "outputs": ["out"]
+      }
+    },
     "inputSrcs": [
       "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
     ],
     "name": "hello-2.12.1",
+    "outputs": {
+      "out": {
+        "path": "/nix/store/7bl684y3qpxrv01ird085rpf5kl6rk6f-hello-2.12.1"
+      }
     },
     "system": "x86_64-linux"
   }
 }
```

強調した箇所に注目してください。ストアパスが記述されています。

### inputDrvs

`inputDrvs`はビルド入力のDerivationです。ここで指定されたDerivationからビルドされた成果物だけがサンドボックス環境で利用可能になります。

`/nix/store/8brdx72cmmmjrap80d8x4k58f69h4247-stdenv-linux.drv`は**stdenv**という特別なパッケージのDerivationです。stdenvはStandard Environment（直訳: 標準環境）の略であり、`gcc`や`coreutils`など一般的な環境なら必ずインストールされているような基本的なパッケージが複数同包されています。

`/nix/store/y1j406svnfr5i2i78z4ybg8rg30ngmkj-bash-5.2p26.drv`は`bash`のDerivationです。サンドボックス環境でビルドを実行する際のシェルとして利用されます。

`/nix/store/zm481qv2gsm86pb6c7k1sjhvhj3790kv-hello-2.12.1.tar.gz.drv`はhelloの**ソースコード**のDerivationです。実は、ストアオブジェクトはいわゆる「パッケージ」だけではありません。ソースコードや設定ファイルなど、ビルドシステムに導入される全てのファイルはストアオブジェクトとしてNixストアに格納されます。そして、それらも通常のパッケージと同様にDerivationから生成されます。NixのビルドシステムはDerivationを基本単位としているのです。

### outputs

`outputs`はビルド成果物の出力先です。このようにストアパスはDerivationにあらかじめ指定されています。

### builder

`builder`はビルドを実行するシェルの実行可能ファイルのファイルパスです。ここでは`inputDrvs`で指定されている`bash`のDerivationからビルドされた実行可能ファイルが指定されています。このように`inputDrvs`として指定されたものがビルドで使用されていることが分かります。

:::details bashのDerivation
以下はbashのstore derivationの`/nix/store/y1j406svnfr5i2i78z4ybg8rg30ngmkj-bash-5.2p26.drv`をJSONにpretty printしたもの。強調した箇所に注目。`hello`の`builder`である`/nix/store/4vzal97iq3dmrgycj8r0gflrh51p8w1s-bash-5.2p26/bin/bash`と以下の`bash`の`outputs`のストアパスが一致している。

```diff json
 {
   "/nix/store/y1j406svnfr5i2i78z4ybg8rg30ngmkj-bash-5.2p26.drv": {
     "args": [
       "-e",
       "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh"
     ],
     "builder": "/nix/store/4w85zw8hd3j2y89fm1j40wgh4kpjgxy7-bootstrap-tools/bin/bash",
     "env": {
       "NIX_CFLAGS_COMPILE": "-DSYS_BASHRC=\"/etc/bashrc\"\n-DSYS_BASH_LOGOUT=\"/etc/bash_logout\"\n-DDEFAULT_PATH_VALUE=\"/no-such-path\"\n-DSTANDARD_UTILS_PATH=\"/no-such-path\"\n-DNON_INTERACTIVE_LOGIN_SHELLS\n-DSSH_SOURCE_BASHRC\n",
       "NIX_HARDENING_ENABLE": "bindnow fortify fortify3 pic relro stackprotector strictoverflow",
       "__structuredAttrs": "",
       "buildInputs": "",
       "builder": "/nix/store/4w85zw8hd3j2y89fm1j40wgh4kpjgxy7-bootstrap-tools/bin/bash",
       "cmakeFlags": "",
       "configureFlags": "--without-bash-malloc --disable-readline",
       "debug": "/nix/store/kaf5d1vylp6m33l0rk2k7rqlywzfs0za-bash-5.2p26-debug",
       "depsBuildBuild": "/nix/store/nnvd4131xmnxnbqv6a53v04fzfiafdq3-bootstrap-stage4-gcc-wrapper-13.2.0",
       "depsBuildBuildPropagated": "",
       "depsBuildTarget": "",
       "depsBuildTargetPropagated": "",
       "depsHostHost": "",
       "depsHostHostPropagated": "",
       "depsTargetTarget": "",
       "depsTargetTargetPropagated": "",
       "dev": "/nix/store/iicickw53hmgj8rf96yqgjrgsv4hlkj1-bash-5.2p26-dev",
       "doCheck": "",
       "doInstallCheck": "",
       "doc": "/nix/store/5jp51iwz6cjfyq6zhwg8m0fivsd8hlij-bash-5.2p26-doc",
       "enableParallelBuilding": "1",
       "enableParallelChecking": "1",
       "enableParallelInstalling": "1",
       "hardeningDisable": "format",
       "info": "/nix/store/g9vcfisvnmms8wlv5j7xalkhjrvfljqa-bash-5.2p26-info",
       "makeFlags": "",
       "man": "/nix/store/77j4sqnw0fimixqxay7vry15z1090vvr-bash-5.2p26-man",
       "mesonFlags": "",
       "name": "bash-5.2p26",
       "nativeBuildInputs": "/nix/store/gfs99irk2vapgyaj4yjcw0b67sfj1p9p-bison-3.8.2 /nix/store/12l2v3kmacnpmx14p2345kk41fpv31rw-separate-debug-info.sh",
       "out": "/nix/store/4vzal97iq3dmrgycj8r0gflrh51p8w1s-bash-5.2p26",
       "outputs": "out dev man doc info debug",
       "patchFlags": "-p0",
       "patch_suffix": "p26",
       "patches": "/nix/store/a73wzcks7h2y814qxa1z3kv1hg205mpm-bash52-001 /nix/store/xc3h9isl5566i6a4pvdsgin26rchijrq-bash52-002 /nix/store/sxc8xmi7caxaiywzh15za9crpk3bw98z-bash52-003 /nix/store/2ynclzrdl0hy9miy6k8gcwgzw4mhsmd0-bash52-004 /nix/store/z76vsdh69cvwkwhwg69k7d1znwjmx6hf-bash52-005 /nix/store/1fw5fcsjz9wcbf13a5xs4i2cjfircp3x-bash52-006 /nix/store/rs1qdpy1nb3x07g4vqvb4s774qhq9f0w-bash52-007 /nix/store/jn9f2mr2jdm9yn5hi0pws44nbfrah8d3-bash52-008 /nix/store/j8vipdfzslz4aa7aj0amwd4msxa9hhpl-bash52-009 /nix/store/24ygbbc9k6vjc4vhz2j6a9dkdgmqgc6n-bash52-010 /nix/store/sim601rd1y3hsap9qkn25cwprsa9aipp-bash52-011 /nix/store/x1sqwqn02c5mnpi8hbqlxpbm3rahq5dm-bash52-012 /nix/store/wcpqrbsljh2x04qccs6jv9z8c9y1c3cd-bash52-013 /nix/store/cddj9qpc4l62qjy6vvf7gp50mfqaf506-bash52-014 /nix/store/pjp935kxwai47zyx1wpwadls00m9nmib-bash52-015 /nix/store/0cr4hvmwbfablyhn58ba0lrfb44igq5y-bash52-016 /nix/store/in24890k6ybij0b63jisfmrwmmc6x7pv-bash52-017 /nix/store/nffxsaniz7irz07z79cxwkhz97vgqwrx-bash52-018 /nix/store/d5qpl3kqrmv99fbw1cd09qj9jr7kb2rr-bash52-019 /nix/store/pcdlxsb3mxfjnclg8rn8xy2ywbb5ra36-bash52-020 /nix/store/gnx16vs69p7fggsslnbg6v818497vvxl-bash52-021 /nix/store/a55mbgicwbpl17n7a4wklg214xbcgj3f-bash52-022 /nix/store/kwf1fq1xvc5x883gjqsp439ayqffkx1f-bash52-023 /nix/store/rihy7jn15hxaifb33v5p8w62gmw62k97-bash52-024 /nix/store/m9x6023c6a7wi91fm0624da2lww2wm5p-bash52-025 /nix/store/yzd1kmz6qlk3dxa82lwfbgqqxy2c4m1x-bash52-026 /nix/store/yq0lz1byj4v2rym2ng23a3nj4n6pvqdj-pgrp-pipe-5.patch /nix/store/1dydp86d00qzjbncpi80sdsndf33lc5j-fix-static.patch /nix/store/j7yk5caljxg94g6kn285hz5ysiyv1bmi-parallel.patch",
       "pname": "bash",
       "postFixup": "rm -rf \"$out/share\" \"$out/bin/bashbug\"\n",
       "postInstall": "ln -s bash \"$out/bin/sh\"\nrm -f $out/lib/bash/Makefile.inc\n",
       "propagatedBuildInputs": "",
       "propagatedNativeBuildInputs": "",
       "separateDebugInfo": "1",
       "src": "/nix/store/v28dv6l0qk3j382kp40bksa1v6h7dx9p-bash-5.2.tar.gz",
       "stdenv": "/nix/store/ch7q4vf76b9x309fjlw1z083qvlx5d4w-bootstrap-stage4-stdenv-linux",
       "strictDeps": "1",
       "system": "x86_64-linux",
       "version": "5.2p26"
     },
     "inputDrvs": {
       "/nix/store/1rfn1ylygzdbca5b54qjs6n4vnnsx85f-bash52-006.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/5jrd75v747s76s16zxk59384xfcjqn58-bash-5.2.tar.gz.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/6k05dfl68y2m382xd5hanfvj7j8c73p1-bash52-003.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/6xwbrn3wdxwyphpj64rphhms41vxvqxb-bash52-009.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/7j0r588ymbv6dq8c98wvzklcsk42wvpb-bash52-014.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/8y6nd0hmkkq8yfalynzh4s6h46sgsan6-bash52-017.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/a68j9bys24cr3m1bixy4bz92q27bmx7k-bash52-005.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/ag9cnvb4pcgcj0rbkzva6qdz54fnr8fg-bash52-012.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/ah8jsm934168mfnmkf54fh0ms38k6nsm-bash52-015.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/dwnaalvf1ch2b37si1hcxx3x3v0ybnck-bash52-024.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/f9hs49y4q8bvg4ffdiycbafd5r1gb13r-bash52-008.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/fib3fbbmchxr3qjrnk28n7i75pppf81z-bison-3.8.2.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/fnrgd1ca2cs2mzy1x95z5c3yi8nsyw2s-bash52-019.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/h3nkdqxk105rmz1i7ckj2swnj77h8fmr-bootstrap-tools.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/hv81fnwf06mhffinfzln6a8rdfl7kg5n-bash52-020.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/j2zlvksmwzs79zvsqmz45jn39zsyr31f-bash52-002.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/kssqadrh4044p2na6fclnyh6pv3r9l5s-bash52-013.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/l81h2pb34h1hrgf8hgayzl28zzmqnfm0-bash52-010.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/lqxznznzm6v8r2z4k8jsdph11l6970nc-bash52-022.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/lrxrk69f3d3rpxf43sfibv3cfwwlc2ra-bash52-026.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/nayxpac1fisgp2xf519mcjch70dwxrah-bash52-018.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/nb8wd3xgfp34vic7xw7rkb186pq7hwfh-bash52-001.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/nsw82ybp208qkgs87s5b2h74978lrgd8-bash52-011.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/pk6bdyws4n421ak7mwvk5nkg0li7cvq2-bash52-004.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/qsr1742cyyh6mdq98n90w0dq5782m2b8-bash52-023.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/rz74q7y5r38in9zdzq9r2brf5yh6lpy5-bash52-007.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/sjlm8agj6m3cpglc5v11d40cj7j6kin2-fix-static.patch.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/v7zbdi2mv0i7h0y06bsb3g8i45bxqxbq-bash52-016.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/vxh1nm9l9q2vsb6akkj5pj5zkrp9gipm-bootstrap-stage4-gcc-wrapper-13.2.0.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/w6gibnw6js9pxsa8n3fiq0hly0pvkm4p-bash52-025.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/yaqyhbrk9dj9315h4srmfzws5w04gx7i-bootstrap-stage4-stdenv-linux.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       },
       "/nix/store/ymnhhrx4aqn1gw5w43bqdr7bkma6b5xa-bash52-021.drv": {
         "dynamicOutputs": {},
         "outputs": ["out"]
       }
     },
     "inputSrcs": [
       "/nix/store/12l2v3kmacnpmx14p2345kk41fpv31rw-separate-debug-info.sh",
       "/nix/store/j7yk5caljxg94g6kn285hz5ysiyv1bmi-parallel.patch",
       "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh",
       "/nix/store/yq0lz1byj4v2rym2ng23a3nj4n6pvqdj-pgrp-pipe-5.patch"
     ],
     "name": "bash-5.2p26",
     "outputs": {
       "debug": {
         "path": "/nix/store/kaf5d1vylp6m33l0rk2k7rqlywzfs0za-bash-5.2p26-debug"
       },
       "dev": {
         "path": "/nix/store/iicickw53hmgj8rf96yqgjrgsv4hlkj1-bash-5.2p26-dev"
       },
       "doc": {
         "path": "/nix/store/5jp51iwz6cjfyq6zhwg8m0fivsd8hlij-bash-5.2p26-doc"
       },
       "info": {
         "path": "/nix/store/g9vcfisvnmms8wlv5j7xalkhjrvfljqa-bash-5.2p26-info"
       },
       "man": {
         "path": "/nix/store/77j4sqnw0fimixqxay7vry15z1090vvr-bash-5.2p26-man"
       },
+      "out": {
+        "path": "/nix/store/4vzal97iq3dmrgycj8r0gflrh51p8w1s-bash-5.2p26"
+      }
     },
     "system": "x86_64-linux"
   }
 }
```

:::

### env

`env`にはサンドボックス環境に与えられる環境変数が指定されています。サンドボックスの章でも述べたように、ビルド環境では指定された環境変数のみが有効になります。

## Closures^[[3.6. Closures - Nix Pills](https://nixos.org/guides/nix-pills/enter-environment#id1356)]

**Closures**とは、ストアパスから直接/間接的に到達可能なストアパスの集合です。

ここでも`hello`を例にとりましょう。
`hello`のstore derivationのClosuresはビルド時依存と等価です。

:::details helloのstore derivationのClosures
`nix-store --query --requisites /nix/store/y1j406svnfr5i2i78z4ybg8rg30ngmkj-bash-5.2p26.drv`の実行結果。`bash`や`pkg-config`といったビルド時にしか使わないパッケージのDerivationが含まれている。

```
/nix/store/001gp43bjqzx60cg345n2slzg7131za8-nix-nss-open-files.patch
/nix/store/00qr10y7z2fcvrp9b2m46710nkjvj55z-update-autotools-gnu-config-scripts.sh
/nix/store/3dl59vc3fzy2ld67jqh12xi63z9684vf-cc-wrapper.sh
/nix/store/5yzw0vhkyszf2d179m0qfkgxmp5wjjx4-move-docs.sh
/nix/store/6g5nwrf0jhrqmwf9nmqmaldhy5h03v14-setup.sh
/nix/store/cickvswrvann041nqxb0rxilc46svw1n-prune-libtool-files.sh
/nix/store/ckzrg0f0bdyx8rf703nc61r3hz5yys9q-builder.sh
/nix/store/fyaryjvghbkpfnsyw97hb3lyb37s1pd6-move-lib64.sh
/nix/store/0m4y3j4pnivlhhpr5yqdvlly86p93fwc-busybox.drv
/nix/store/i9nx0dp1khrgikqr95ryy2jkigr4c5yv-unpack-bootstrap-tools.sh
/nix/store/xjkydxc0n24mwxp8kh4wn5jq0fppga9k-bootstrap-tools.tar.xz.drv
/nix/store/h3nkdqxk105rmz1i7ckj2swnj77h8fmr-bootstrap-tools.drv
/nix/store/h9lc1dpi14z7is86ffhl3ld569138595-audit-tmpdir.sh
/nix/store/ilaf1w22bxi6jsi45alhmvvdgy4ly3zs-patch-shebangs.sh
/nix/store/jivxp510zxakaaic7qkrb7v1dd2rdbw9-multiple-outputs.sh
/nix/store/kd4xwxjpjxi71jkm6ka0np72if9rm3y0-move-sbin.sh
/nix/store/m54bmrhj6fqz8nds5zcj97w9s9bckc9v-compress-man-pages.sh
/nix/store/ngg1cv31c8c7bcm2n8ww4g06nq7s4zhm-set-source-date-epoch-to-latest.sh
/nix/store/pag6l61paj1dc9sv15l7bm5c17xn5kyk-move-systemd-user-units.sh
/nix/store/wgrbkkaldkrlrni33ccvm3b6vbxzb656-make-symlinks-relative.sh
/nix/store/wmknncrif06fqxa16hpdldhixk95nds0-strip.sh
/nix/store/xyff06pkhki3qy1ls77w10s0v79c9il0-reproducible-builds.sh
/nix/store/b3h9l5c2nbaxlld41d7ckn0kmlfikzqf-bootstrap-stage0-stdenv-linux.drv
/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh
/nix/store/4kz6hwl1a2nr5vb6almsz2msp94gk9p3-bootstrap-stage0-glibc-bootstrapFiles.drv
/nix/store/ckjykyfw30zj1n3lcca9lwm2lzd7azdb-setup-hook.sh
/nix/store/i60i6xvvywyk7h9wrjff7zmlksqw348p-add-hardening.sh
/nix/store/ji2yrl1na00bwav65hh1vr0nc0s1xzvz-add-flags.sh
/nix/store/kgcmpr4i443sdyszl1b7i4k86ddxbrwi-utils.bash
/nix/store/0zmg36dmrb9v7bc7b7igmi434nhi1qp9-setup-hook.sh
/nix/store/9rq2ab2wl3ia1ism6zjvdxcnpv9s9rgn-add-hardening.sh
/nix/store/m9qvr6m0bylrjqb5ind6hfzsax14xys9-gnu-binutils-strip-wrapper.sh
/nix/store/mrzpfh0ml9k07sw019ydagbb2z1q4sxz-add-flags.sh
/nix/store/p2ynpdqzm8lfdq6xywa8igkjp56b8q65-ld-wrapper.sh
/nix/store/v9034cqc4h5bm10z4vz3n1q2n55grv5y-role.bash
/nix/store/syvf5z2z92lfn4gyqi2sb8xr2w8idj2a-bootstrap-stage0-binutils-wrapper-.drv
/nix/store/jik02mkz72r2f6hhxnlhp6h5f0fi89gw-expand-response-params.c
/nix/store/h11pn2l5rszzgjrl84qw2ifr33rdkjcq-config.sub-28ea239.drv
/nix/store/p0gj1mzg99qc4bnql0299yiadn026jc3-config.guess-28ea239.drv
/nix/store/5dxwfzhnkkfxlriq36qs75v8xr8m6p57-gnu-config-2023-09-19.drv
/nix/store/2icywpz274djh4pq5m01zb7z6skj3v26-update-autotools-gnu-config-scripts-hook.drv
/nix/store/j5dahfbx1m2pl6j8s67dxil0b77skn0w-bootstrap-stage1-gcc-wrapper-.drv
/nix/store/kjbsvc527ki9b8qsz3hwcraxn0w62ywp-bootstrap-stage1-stdenv-linux.drv
/nix/store/yz7v5n3xy4irpyqwb728y4rxzsr7w9qi-expand-response-params.drv
/nix/store/07m06jsa56c3ybmcpmxicsqzah8nsaz7-bootstrap-stage-xgcc-gcc-wrapper-.drv
/nix/store/2zsw6v5l9zzhslrrdqpljnb425njg1pf-perl-5.38.2.tar.gz.drv
/nix/store/55lbvcqz3z97jcqf2zxqwav58wq52z8l-no-sys-dirs-5.38.0.patch
/nix/store/dm81j9qdcdr4c458pqbc9wvq9ymgzk4m-setup-hook.sh
/nix/store/gyks6vvl7x0gq214ldjhi3w4rg37nh8i-zlib-1.3.1.tar.gz.drv
/nix/store/k9xhv9dia871b78v0qka4ccfng2f9llx-zlib-1.3.1.drv
/nix/store/0a2444q1gpvyy8xwnx88w0b7x72pxy3r-perl-5.38.2.drv
/nix/store/0df8rz15sp4ai6md99q5qy9lf0srji5z-0001-Revert-libtool.m4-fix-nm-BSD-flag-detection.patch
/nix/store/12l2v3kmacnpmx14p2345kk41fpv31rw-separate-debug-info.sh
/nix/store/ky6v299i06z6046nxh69dipiyg4r2ks3-bootstrap-stage1-stdenv-linux.drv
/nix/store/pqjw5anwhihqdvq4h37mzybq74rp66sc-gnu-config-2023-09-19.drv
/nix/store/d5vi0s4199f0q981b924yr5p8gm7nqgi-update-autotools-gnu-config-scripts-hook.drv
/nix/store/2picrpz340qsh547c0pwf8y8w8r811zj-bootstrap-stage-xgcc-stdenv-linux.drv
/nix/store/33xyavnchhblrv9zi3zdyc0v2aiwldhj-bootstrap-stage-xgcc-stdenv-linux.drv
/nix/store/dkax3qzl0m26pi8nljnh7nfv3fp964n2-gnu-config-2023-09-19.drv
/nix/store/5zfmjwr5yznvcasibyw11jdyqywgs0bj-update-autotools-gnu-config-scripts-hook.drv
/nix/store/5jg0ijqb29ibsnmkc1sz6fbjh9zsqz6m-gold-powerpc-for-llvm.patch
/nix/store/2c90gp52cvdprpj314d86qii9qil4fkb-gettext-0.21.1.tar.gz.drv
/nix/store/1rfn1ylygzdbca5b54qjs6n4vnnsx85f-bash52-006.drv
/nix/store/5jrd75v747s76s16zxk59384xfcjqn58-bash-5.2.tar.gz.drv
/nix/store/6k05dfl68y2m382xd5hanfvj7j8c73p1-bash52-003.drv
/nix/store/6xwbrn3wdxwyphpj64rphhms41vxvqxb-bash52-009.drv
/nix/store/7j0r588ymbv6dq8c98wvzklcsk42wvpb-bash52-014.drv
/nix/store/8y6nd0hmkkq8yfalynzh4s6h46sgsan6-bash52-017.drv
/nix/store/a68j9bys24cr3m1bixy4bz92q27bmx7k-bash52-005.drv
/nix/store/ag9cnvb4pcgcj0rbkzva6qdz54fnr8fg-bash52-012.drv
/nix/store/ah8jsm934168mfnmkf54fh0ms38k6nsm-bash52-015.drv
/nix/store/dwnaalvf1ch2b37si1hcxx3x3v0ybnck-bash52-024.drv
/nix/store/f9hs49y4q8bvg4ffdiycbafd5r1gb13r-bash52-008.drv
/nix/store/rr4cpsx1w84h2l1h71ch8spcp221kzkr-m4-1.4.19.tar.bz2.drv
/nix/store/ksfh7jvbjrxhvh25jln6hrnqkkssihq6-gnum4-1.4.19.drv
/nix/store/vgjfnqbxgxa8a5575bhq07nm35b2l31m-bison-3.8.2.tar.gz.drv
/nix/store/fib3fbbmchxr3qjrnk28n7i75pppf81z-bison-3.8.2.drv
/nix/store/fnrgd1ca2cs2mzy1x95z5c3yi8nsyw2s-bash52-019.drv
/nix/store/hv81fnwf06mhffinfzln6a8rdfl7kg5n-bash52-020.drv
/nix/store/j2zlvksmwzs79zvsqmz45jn39zsyr31f-bash52-002.drv
/nix/store/j7yk5caljxg94g6kn285hz5ysiyv1bmi-parallel.patch
/nix/store/kssqadrh4044p2na6fclnyh6pv3r9l5s-bash52-013.drv
/nix/store/l81h2pb34h1hrgf8hgayzl28zzmqnfm0-bash52-010.drv
/nix/store/lqxznznzm6v8r2z4k8jsdph11l6970nc-bash52-022.drv
/nix/store/lrxrk69f3d3rpxf43sfibv3cfwwlc2ra-bash52-026.drv
/nix/store/nayxpac1fisgp2xf519mcjch70dwxrah-bash52-018.drv
/nix/store/nb8wd3xgfp34vic7xw7rkb186pq7hwfh-bash52-001.drv
/nix/store/nsw82ybp208qkgs87s5b2h74978lrgd8-bash52-011.drv
/nix/store/pk6bdyws4n421ak7mwvk5nkg0li7cvq2-bash52-004.drv
/nix/store/qsr1742cyyh6mdq98n90w0dq5782m2b8-bash52-023.drv
/nix/store/rz74q7y5r38in9zdzq9r2brf5yh6lpy5-bash52-007.drv
/nix/store/sjlm8agj6m3cpglc5v11d40cj7j6kin2-fix-static.patch.drv
/nix/store/v7zbdi2mv0i7h0y06bsb3g8i45bxqxbq-bash52-016.drv
/nix/store/w6gibnw6js9pxsa8n3fiq0hly0pvkm4p-bash52-025.drv
/nix/store/ymnhhrx4aqn1gw5w43bqdr7bkma6b5xa-bash52-021.drv
/nix/store/yq0lz1byj4v2rym2ng23a3nj4n6pvqdj-pgrp-pipe-5.patch
/nix/store/31zl8krq3v12lyxa420knpqjs1dw4cjp-bash-5.2p26.drv
/nix/store/dyhmf8nc29s0ghb7ij4i39ff5hm4nzff-xz-5.6.0.tar.bz2.drv
/nix/store/fi6yj0ipv9cn5f1xll11y0dsn8rgmd8f-xz-5.6.0.drv
/nix/store/ny42y6hs4p294rvnrwbmrpwzqghw2816-gettext-setup-hook.sh
/nix/store/p2fp6i7hjx9af1wbwr32k217wp2dxmiw-absolute-paths.diff
/nix/store/yqwx9yln5i68nw61mmp9gz066yz3ri99-0001-msginit-Do-not-use-POT-Creation-Date.patch
/nix/store/fg6r3xs0bsqrr9xdlb295z5abpml5rj2-gettext-0.21.1.drv
/nix/store/lgniihp1bk6mkd5nn9y5ikfim2ignr52-0001-libtool.m4-update-macos-version-detection-block.patch
/nix/store/pa83jbilxjpv5d4f62l3as4wg2fri7r7-always-search-rpath.patch
/nix/store/rf3kjgy7pbvymp55hxw28dg5g937lmcv-plugins-no-BINDIR.patch
/nix/store/sqbhaaayam0xw3a3164ks1vvbrdhl9vq-deterministic.patch
/nix/store/xgjmhfz2pl0fdsrpiz8hiabqzfrqbx9b-binutils-2.41.tar.bz2.drv
/nix/store/xrw086zw3xqsvy9injgil8n2qdkvkpff-0001-Revert-libtool.m4-fix-the-NM-nm-over-here-B-option-w.patch
/nix/store/c4dl6kcalbg7sil6w7g75i1bm9agbkcn-binutils-2.41.drv
/nix/store/hmgvnyhhkpdjm03g69axcpaigfskr3ga-expand-response-params.drv
/nix/store/a5g5vaabr2wfsxjvcxcr6y6vlh54mp5g-binutils-wrapper-2.41.drv
/nix/store/9m54l1bi5814x9cqznwlga7yfs5ipi6h-nuke-refs.sh
/nix/store/1y13cg6l20alnp8plnrrfynvjzz68jn1-nuke-references.drv
/nix/store/fd7x6bw5gp22rbin304hg75h6ik84j93-texinfo-7.0.3.tar.xz.drv
/nix/store/2wgdca0r6nmd3svsa5lf1b253gmgsibm-texinfo-7.0.3.drv
/nix/store/632b0y5mkcdwbsw2g3xh5qznw2vv5axr-ppc-musl.patch
/nix/store/6lasfbjdsklajij59mclz0y7biyafxgb-bash-5.2p26.drv
/nix/store/z4x4wa4ahsc6xn40j847dsrnagxd41w0-gmp-6.3.0.tar.bz2.drv
/nix/store/6lbyp2klvw426srgr3ny7b0xzb6z09bb-gmp-6.3.0.drv
/nix/store/156yvnw4g1h0gv1s8p7bray6hyn43f8q-mpc-1.3.1.tar.gz.drv
/nix/store/m7cyv7yrqlazp2jbpc2k53xyhrczz0af-mpfr-4.2.1.tar.xz.drv
/nix/store/drvz1bl4v8ifi19kpxkf3bnykvxbdq7k-mpfr-4.2.1.drv
/nix/store/7w1d4sp3hs4i6jmrmwn0q2ahmjl4gp52-libmpc-1.3.1.drv
/nix/store/7x6bimj6ipi6ag859gi2fc6by87x37j7-no-sys-dirs-riscv.patch
/nix/store/9577hmdlmhki67cg8ar85cvidyg7xr7p-gcc-12-no-sys-dirs.patch
/nix/store/g1sn1rmgwdl4s2xymw7zxflzx6y9y0fm-ICE-PR110280.patch
/nix/store/iz6i2a83s2cb8wdfmcbm11jpdq01p8cg-which-2.21.tar.gz.drv
/nix/store/hbvydflpm13bf794sgl9q8camp9mdpyx-which-2.21.drv
/nix/store/qxz8v1gxrrw9j138k2ajl36vcajra8mb-isl-0.20.tar.xz.drv
/nix/store/icwibkkrk8ppidiii662nzh2p29yqiz4-isl-0.20.drv
/nix/store/j0j9yl69hnf9q51w9qpr24lscsq7k81c-gcc-13.2.0.tar.xz.drv
/nix/store/q5lq5b7c0i31zxjgm6j5zhp8pg76mwi1-patchelf-0.15.0.tar.bz2.drv
/nix/store/v7ihfx32zv7bdha6i9dd6a3r0knzs8j3-setup-hook.sh
/nix/store/nj5k9751idl47d1v6ddvby7811lkxx4v-patchelf-0.15.0.drv
/nix/store/xpplvxiwb4li2qd5nvhyd2mngrpna0ya-mangle-NIX_STORE-in-__FILE__.patch
/nix/store/ly4bk0mxr1d956f21w30idkvhhkkxlvf-libxcrypt-4.4.36.tar.xz.drv
/nix/store/zigzcydpgaw60mn5qffmb4ip16crckyc-libxcrypt-4.4.36.drv
/nix/store/c4i0ghzgjskzvcl77jg36dwysx3dfj56-xgcc-13.2.0.drv
/nix/store/9c9nrlzh7v3xwiclv5p5fk21mrcfycq2-bootstrap-stage2-gcc-wrapper-13.2.0.drv
/nix/store/6v0kl7mf3cwi251s42jsmfkxc48h6i3l-bootstrap-stage2-stdenv-linux.drv
/nix/store/29zzfw0ncr1bar8333fjaakfyfzzmva5-libxcrypt-4.4.36.drv
/nix/store/57kclla9vza2n87xgwg1ap54d20cz6lb-fix-finding-headers-when-cross-compiling.patch
/nix/store/7f26mgj9vx5izbkbfirkd4m0dyxlrkvv-platform-triplet-detection.patch
/nix/store/jszqnha7xnmjkn7x4bh18g03r6kg8bsl-bootstrap-stage2-stdenv-linux.drv
/nix/store/zi0m9pfmvy5lw89x7a8x674rm99i8qiq-setup-hook.sh
/nix/store/9r3qbf0sy64idhmfvcgjhg6v2i26rvar-python-setup-hook.sh.drv
/nix/store/czgzq4viby3xkqf6lp0xi19msls8vja5-mpdecimal-4.0.0.tar.gz.drv
/nix/store/aspxd41m0ij5y44z4qik5hpwl5ri164w-mpdecimal-4.0.0.drv
/nix/store/cv1ynpzvjjr0s72jkbblbzz3ymr87lpi-0001-On-all-posix-systems-not-just-Darwin-set-LDSHARED-if.patch
/nix/store/1kvr4k6xs8v1h2x6vclfwkjg64zrlfxn-bzip2-1.0.6.2-autoconfiscated.patch.drv
/nix/store/mhrxc5w6drwi4m5ykbdrayz7869i9mx9-bzip2-1.0.8.tar.gz.drv
/nix/store/3yar2pnvz7ll79z3jlzx09qnhrsi7zj5-automake-1.16.5.tar.xz.drv
/nix/store/4cmjzk8yr6i5vls5d2050p653zzdvmvp-setup-hook.sh
/nix/store/i2pfgljh1az3v0xga8s4kvn7l1kb1nj4-autoconf-2.72.tar.xz.drv
/nix/store/yzhpqxlg0459cagah8had9v1bzga3nzd-autoconf-2.72.drv
/nix/store/dkgral31imgn3053601d14nfkxqbnidf-automake-1.16.5.drv
/nix/store/ghdamd4hl6yi7jysh1x3436fj1v9yvjb-autoreconf.sh
/nix/store/kf7fzzm4nz10qaxv9lpjwqqxxgbrz50m-32-bit-time_t.patch
/nix/store/klfl82nqgac8fyl7z83q1i7rngka20d3-file-5.45.tar.gz.drv
/nix/store/vg797hy0lb19pxf88khrlqp7zy734ax2-zlib-1.3.1.drv
/nix/store/6yak0qiwrdjl2n4afb9j3qvvd64ivag6-file-5.45.drv
/nix/store/rwvhsf6hna1j3sgw20f1b4gl9mp5w9vr-libtool-2.4.7.tar.gz.drv
/nix/store/vha2xrmvfs6bpy4qq23m7lnll455nvmb-bash-5.2p26.drv
/nix/store/rla2japfqcl0n6ffkb7mv84iij6ay9r1-libtool-2.4.7.drv
/nix/store/qxa292f80gzvb3352ma7wydkcn032zdz-autoreconf-hook.drv
/nix/store/gl9faygwciknbg5qnr69l3gq5kl28a3y-bzip2-1.0.8.drv
/nix/store/jqin2kzvzrvi30cxda5zp7qz1fanmz7v-no-ldconfig.patch
/nix/store/khmchk8i5bkzlfghl98g3f0g240cslj9-loongarch-support.patch
/nix/store/klc6p9hshi1xr9pxhrsv1xadmh28gsys-nuke-references.drv
/nix/store/9hia04573d2n427n12wxjgkgm0r8l2nk-libffi-3.4.6.tar.gz.drv
/nix/store/l2c83kqjmpkby4zmain9f905f0kwkq2k-libffi-3.4.6.drv
/nix/store/qy6yc7y93ljb5ad8a0f8q5nv652lycah-darwin-libutil.patch
/nix/store/r112dk8w7zvdjipki58ch00m825li7fq-virtualenv-permissions.patch
/nix/store/r630qqlar8i7rrm585pkxfiiy53g1k0m-xz-5.6.0.drv
/nix/store/wmhjl7ls2r898956l3agpqgmy4wbq25y-autoconf-archive-2023.02.20.tar.xz.drv
/nix/store/v1czpb5wzvhpjqprcxs43ji53bm912h4-autoconf-archive-2023.02.20.drv
/nix/store/yzajlq2vp1hkqgyfqz3nxhsviqk7b06v-2.6.0-fix-tests-flakiness.patch
/nix/store/zmlgwj611867bzvpsd3sd2fyzrp84b78-expat-2.6.0.tar.xz.drv
/nix/store/xkafll8dp8gw4vcb7w0i9idrb8bz0mar-expat-2.6.0.drv
/nix/store/zydgl5fyyrq2vqyg081qx0xsjgyg8ayv-Python-3.11.8.tar.xz.drv
/nix/store/1ksmnsr3m6paw8gs7jp9b623agzdrqi2-add-flags.sh
/nix/store/6b29gjz7rj4mw0ch0vy2m6qrqipz2bbb-pkg-config-0.29.2.tar.gz.drv
/nix/store/f4bvwqvj0y3z6blvh0knz71a8yq1c45p-requires-private.patch
/nix/store/fsi7wh9h5cpnmp89x67ns4hfvpbd4k1l-bootstrap-stage0-glibc-iconv-bootstrapFiles.drv
/nix/store/7rh4gimc073l9a7pn56108lz8b2vwzbh-pkg-config-0.29.2.drv
/nix/store/c4akajrb4jg50k72jw7zfbyv8z139ri0-setup-hook.sh
/nix/store/lypyhrdqir7lhwhsvrr1cp85ywh3dhas-pkg-config-wrapper.sh
/nix/store/zz7b0q8vfc20mqd73fa32yg228jszbl6-pkg-config-wrapper-0.29.2.drv
/nix/store/0zwyz5is7qhy2b6q8h3p3g89rqsikws7-python3-minimal-3.11.8.drv
/nix/store/43fp9i8ramrgp0l5kjxr0ic85lymz9m0-patchelf-0.15.0.drv
/nix/store/asx202v34fqgy5rraw2zwa3jayw6dcz0-expand-response-params.drv
/nix/store/5m4lx0qjdac14zarya9gcfpjl9klxvdc-local-qsort-memory-corruption.patch
/nix/store/7kw224hdyxd7115lrqh9a4dv2x8msq2s-fix-x64-abi.patch
/nix/store/8haph3ng4mgsqr6p4024vj8k6kg3mqc4-nix-locale-archive.patch
/nix/store/b1w7zbvm39ff1i52iyjggyvw2rdxz104-dont-use-system-ld-so-cache.patch
/nix/store/69lyjyca86317hdsc1rwf3ahn7s5kiyn-no-relocs.patch
/nix/store/wjljrvzz4vz8xyl49adibwqqyzyyqnjf-linux-6.7.tar.xz.drv
/nix/store/irvx95m6kgcgfy1axb7f3f9ggiccsqh7-linux-headers-6.7.drv
/nix/store/jmmspsnl1b2040bfz76ha68hdnvb4nfs-glibc-2.38.tar.xz.drv
/nix/store/k06glk8f3dxj3k0m9b9y7ph2nbnd1ns0-0001-Revert-Remove-all-usage-of-BASH-or-BASH-in-installed.patch
/nix/store/jnfrr555w6xpqvwyvcav4r86yi4dyb10-libidn2-2.3.7.tar.gz.drv
/nix/store/x026yqw2ch0lhcyd548qra2i6gxi2whp-libunistring-1.1.tar.gz.drv
/nix/store/rvqpzzagmpryi22ciwaqh4ya8mg6baa3-libunistring-1.1.drv
/nix/store/kx9dsjpc2x0kagp43k9qnx1r2bihgsxz-libidn2-2.3.7.drv
/nix/store/mnglr8rr7nl444h7p50ysyq8qd0fm1lm-dont-use-system-ld-so-preload.patch
/nix/store/sj0qllprnrmk1cqnnk57vvn2cqgjynbx-reenable_DT_HASH.patch
/nix/store/wqm26gr75k0nczn3mydr5dqny0ybncfa-2.38-master.patch.gz
/nix/store/za0pg7fmysrcwrqcal26fnmzw6vycgdn-fix_path_attribute_in_getconf.patch
/nix/store/zrz5m473ms415lw13k6a1min9jfq5chk-glibc-2.38-44.drv
/nix/store/8grzj3d5jvm3gh14pl8ycyh73j43nh22-binutils-patchelfed-ld-2.41.drv
/nix/store/xls8zackf9dpvy6v4sdrz9djaqxwixgp-binutils-patchelfed-ld-wrapper-2.41.drv
/nix/store/bzn6082a12n9ji67v8irdhc2xjyzg09r-bootstrap-stage3-gcc-wrapper-13.2.0.drv
/nix/store/jqwdhyva9zkb72gyic4s2pghmj1c5w5s-gnu-config-2023-09-19.drv
/nix/store/rvspyz9l9kh92mi9ic19i1maazj96pyh-update-autotools-gnu-config-scripts-hook.drv
/nix/store/capkc357bbdd0hv5zvbf9k38hfgmq046-bootstrap-stage3-stdenv-linux.drv
/nix/store/pc91d6k9nr31k27qqvfwc8jlnqy3kb5s-gmp-6.3.0.drv
/nix/store/4icg06amw4d88af01b1k8n89lrz9zzbh-isl-0.20.drv
/nix/store/9xqk2gzbw0ghg4dm9w7zhgcswjpvk680-bash-5.2p26.drv
/nix/store/zhb5wvm7rgm2vrjhn01chzkxgwjj9ik9-xz-5.6.0.drv
/nix/store/7zwfmhc9i5s1hcibyjkdyf9143fggk8d-texinfo-7.0.3.drv
/nix/store/ix9yi806p9h4nwabgb0il205j4s3b12s-mpfr-4.2.1.drv
/nix/store/a8w9nd5jjrvb1939i9jxb45wrja9dc66-libmpc-1.3.1.drv
/nix/store/xyzagnllb9419j6c2ck33apyb7yh7gh3-bootstrap-stage3-stdenv-linux.drv
/nix/store/g4kgq90vmz1gnrp7dc9pc8qnrqajsx93-nuke-references.drv
/nix/store/ha2jqykyvnszwdd40x58bpswfqlp956b-zlib-1.3.1.drv
/nix/store/22j5p12grznk64vx4dldvjvazwys0wi6-gcc-13.2.0.drv
/nix/store/4nmilaqcwafzfqbdi9icx09fd0g3y2qv-gnu-config-2023-09-19.drv
/nix/store/51fhcdhpklqz64f9byyc8ks77k01s2j3-update-autotools-gnu-config-scripts-hook.drv
/nix/store/f79lmpx6hhi8a0qx1p4myknj8f2r4wcj-expand-response-params.drv
/nix/store/vxh1nm9l9q2vsb6akkj5pj5zkrp9gipm-bootstrap-stage4-gcc-wrapper-13.2.0.drv
/nix/store/yaqyhbrk9dj9315h4srmfzws5w04gx7i-bootstrap-stage4-stdenv-linux.drv
/nix/store/y1j406svnfr5i2i78z4ybg8rg30ngmkj-bash-5.2p26.drv
```

:::

対して、`hello`のDerivationの出力パス、即ちstore derivationからビルドされた`hello`パッケージのClosuresは実行時の依存関係と等価です。

:::details 出力のパスのClosures

`nix-store --query --requisites /nix/store/7bl684y3qpxrv01ird085rpf5kl6rk6f-hello-2.12.1/bin/hello`の実行結果。`glibc`といった`hello`実行時に動的リンクされる共有ライブラリが含まれている。

```
/nix/store/d8w5qfswmgxcjqwnmqw2v9r8amrvdlpb-xgcc-13.2.0-libgcc
/nix/store/vqvbn2z8wyrjwvayjb2vy5krhh1kis9b-libunistring-1.1
/nix/store/krqp9wj3rgalmqv04y0sqw987mxsnddn-libidn2-2.3.7
/nix/store/ksk3rnb0ljx8gngzk19jlmbjyvac4hw6-glibc-2.38-44
/nix/store/7bl684y3qpxrv01ird085rpf5kl6rk6f-hello-2.12.1
```

:::

つまり、Closuresはパッケージの「完全な依存関係ツリー」を表します。

## Realisation^[[Realisation - Zero to Nix](https://zero-to-nix.com/concepts/realisation)]

store derivationからパッケージをビルドするプロセスを**Realisation**（実体化）と言います。

Realisationの手順は次の通りです。

1. `.drv`を読み取る
2. そのClosures内のストアオブジェクトが存在するか確認
   1. Substituterからストアオブジェクトを探す
   2. 存在しなければ、そのストアオブジェクトのstore derivationをRealise
3. ビルド実行
4. ビルド成果物をNixストアに配置

Closuresが全てrealiseされるまで、Realisationは再帰的に続けられます。

## Nix式

store derivationはあくまで低レベル表現です。実際にNixでパッケージをビルドする際は、Derivationの高レベル表現である**Nix式**（**Nix expression**）からstore derivationを生成します。次章ではNix式を記述するためのプログラミング言語、**Nix言語**について解説します。
