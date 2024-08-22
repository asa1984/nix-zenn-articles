---
title: "　§3. devShellで開発環境構築"
---

いよいよ本格的なNixの使い方を学びます。**devShell**を使って開発環境を構築しましょう。

## devShellを使ってみる

`flake.nix`を作成します。今回はoutputsの`devShells` attributeを使います。

```nix :flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.cowsay ];
        };
      }
    );
}
```

`nix develop`で起動しましょう。

```bash :devShellの起動
$ cowsay
cowsay: command not found

$ nix develop

[Nixシェル]$ cowsay meow
 ______
< meow >
 ------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

[Nixシェル]$ exit

$ cowsay
cowsay: command not found
```

`cowsay`がPATHに追加されたbashが起動します。

`nix shell`がコマンドラインからパッケージを指定していたのに対し、`nix develop`では`flake.nix`に記述したパッケージをNixシェルに導入します。つまり、宣言的に開発環境を構築できるということです。

## mkShell関数

`pkgs.mkShell`は、Nixシェルの設定を行う関数です。

```nix
mkShell {
  packages = <導入したいパッケージのList>;
  shellHook = <シェル起動時に実行したいスクリプト>;
}
```

Bash以外を使っている場合、`SHELL`環境変数を使って普段使っているシェルを起動するようにできます。

```diff nix :flake.nixより抜粋
devShells.default = pkgs.mkShell {
  packages = with pkgs; [ cowsay ];
+ shellHook = ''
+   $SHELL
+ '';
};
```

また、mkShell関数はDerivation型を返します。`devShells`を`packages`に置き換えてビルドしてみましょう。

```diff nix :flake.nixより抜粋
-devShells.default = pkgs.mkShell {
+packages.default = pkgs.mkShell {
   # 省略
 };
```

```bash :ビルド
$ nix build
$ cat result
# シェルスクリプトが表示される
```

:::details `result`の内容

```bash
------------------------------------------------------------
 WARNING: the existence of this path is not guaranteed.
 It is an internal implementation detail for pkgs.mkShell.
------------------------------------------------------------

declare -x AR="ar"
declare -x AS="as"
declare -x CC="gcc"
declare -x CONFIG_SHELL="/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin/bash"
declare -x CXX="g++"
declare -x GZIP_NO_TIMESTAMPS="1"
declare -x HOME="/homeless-shelter"
declare -x HOST_PATH="/nix/store/w1iq3315z63558j04gnlzdd2yk1v1hfz-coreutils-9.5/bin:/nix/store/ajymwgc23snyw48wvkapw4qjggsi2vbw-findutils-4.10.0/bin:/nix/store/frx30r9405q0d4jfxnf969mgq4q8rjk2-diffutils-3.10/bin:/nix/store/d58flzaagmfb5pyvmknly4cnws45nc80-gnused-4.9/bin:/nix/store/7adzfq6lz76h928gmws5sn6nkli14ml6-gnugrep-3.11/bin:/nix/store/wab5wlc7rrn58z6ay4ls42av4n8rlqia-gawk-5.2.2/bin:/nix/store/k11rxbj9mvpgfk15rriqjn97by18r2xk-gnutar-1.35/bin:/nix/store/ybpxfq146szbqv8xxlc7ixnj9k6l1y5d-gzip-1.13/bin:/nix/store/07lm36zpghw8i9spwbcgkwzisw22k1kn-bzip2-1.0.8-bin/bin:/nix/store/nkza13k6khbmm7z2j6vj40k7081w6c9q-gnumake-4.4.1/bin:/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin:/nix/store/rr31bwb0jym6mgspqp54wdydr94skqvc-patch-2.7.6/bin:/nix/store/1idcyg3ldcggjzfznb5klr7b2wa1vznf-xz-5.6.2-bin/bin:/nix/store/2cqhdkxl71p1afk02g34hm3mbzwb8h1a-file-5.45/bin"
declare -x LD="ld"
declare -x NIX_BINTOOLS="/nix/store/qrw9mznq4p1135k53aa5g9saz229srf4-binutils-wrapper-2.42"
declare -x NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu="1"
declare -x NIX_BUILD_CORES="12"
declare -x NIX_BUILD_TOP="/build"
declare -x NIX_CC="/nix/store/lbk30k56awz9vz9qpid93fkjns0xwlhd-gcc-wrapper-13.3.0"
declare -x NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu="1"
declare -x NIX_CFLAGS_COMPILE=" -frandom-seed=lr31gfg9m5"
declare -x NIX_ENFORCE_NO_NATIVE="1"
declare -x NIX_ENFORCE_PURITY="1"
declare -x NIX_HARDENING_ENABLE="bindnow format fortify fortify3 pic relro stackprotector strictoverflow zerocallusedregs"
declare -x NIX_LDFLAGS="-rpath /nix/store/lr31gfg9m5r8a3xmxwqw4sdv5kyyysl0-nix-shell/lib "
declare -x NIX_LOG_FD="2"
declare -x NIX_SSL_CERT_FILE="/no-cert-file.crt"
declare -x NIX_STORE="/nix/store"
declare -x NM="nm"
declare -x OBJCOPY="objcopy"
declare -x OBJDUMP="objdump"
declare -x OLDPWD
declare -x PATH="/nix/store/5y7yj7x2cfhn1062zimp57m1hyz701yx-cowsay-3.7.0/bin:/nix/store/ywz6s6bzap4x6yhg2lrx3ibqcnv051c7-patchelf-0.15.0/bin:/nix/store/lbk30k56awz9vz9qpid93fkjns0xwlhd-gcc-wrapper-13.3.0/bin:/nix/store/wl7xs26116sswgw18pnc3yw9r5gxr6hx-gcc-13.3.0/bin:/nix/store/mg27y4zq8j0m8dn83azqmq02xvfmsd9i-glibc-2.39-52-bin/bin:/nix/store/w1iq3315z63558j04gnlzdd2yk1v1hfz-coreutils-9.5/bin:/nix/store/qrw9mznq4p1135k53aa5g9saz229srf4-binutils-wrapper-2.42/bin:/nix/store/x7yyxvwy1f9hlx72rzrgx069jyf7hxwr-binutils-2.42/bin:/nix/store/w1iq3315z63558j04gnlzdd2yk1v1hfz-coreutils-9.5/bin:/nix/store/ajymwgc23snyw48wvkapw4qjggsi2vbw-findutils-4.10.0/bin:/nix/store/frx30r9405q0d4jfxnf969mgq4q8rjk2-diffutils-3.10/bin:/nix/store/d58flzaagmfb5pyvmknly4cnws45nc80-gnused-4.9/bin:/nix/store/7adzfq6lz76h928gmws5sn6nkli14ml6-gnugrep-3.11/bin:/nix/store/wab5wlc7rrn58z6ay4ls42av4n8rlqia-gawk-5.2.2/bin:/nix/store/k11rxbj9mvpgfk15rriqjn97by18r2xk-gnutar-1.35/bin:/nix/store/ybpxfq146szbqv8xxlc7ixnj9k6l1y5d-gzip-1.13/bin:/nix/store/07lm36zpghw8i9spwbcgkwzisw22k1kn-bzip2-1.0.8-bin/bin:/nix/store/nkza13k6khbmm7z2j6vj40k7081w6c9q-gnumake-4.4.1/bin:/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin:/nix/store/rr31bwb0jym6mgspqp54wdydr94skqvc-patch-2.7.6/bin:/nix/store/1idcyg3ldcggjzfznb5klr7b2wa1vznf-xz-5.6.2-bin/bin:/nix/store/2cqhdkxl71p1afk02g34hm3mbzwb8h1a-file-5.45/bin"
declare -x PWD="/build"
declare -x RANLIB="ranlib"
declare -x READELF="readelf"
declare -x SHELL="/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin/bash"
declare -x SHLVL="1"
declare -x SIZE="size"
declare -x SOURCE_DATE_EPOCH="315532800"
declare -x SSL_CERT_FILE="/no-cert-file.crt"
declare -x STRINGS="strings"
declare -x STRIP="strip"
declare -x TEMP="/build"
declare -x TEMPDIR="/build"
declare -x TERM="xterm-256color"
declare -x TMP="/build"
declare -x TMPDIR="/build"
declare -x TZ="UTC"
declare -x XDG_DATA_DIRS="/nix/store/5y7yj7x2cfhn1062zimp57m1hyz701yx-cowsay-3.7.0/share:/nix/store/ywz6s6bzap4x6yhg2lrx3ibqcnv051c7-patchelf-0.15.0/share"
declare -x __structuredAttrs=""
declare -x buildInputs=""
declare -x buildPhase=$'{ echo "------------------------------------------------------------";\n  echo " WARNING: the existence of this path is not guaranteed.";\n  echo " It is an internal implementation detail for pkgs.mkShell.";\n  echo "------------------------------------------------------------";\n  echo;\n  # Record all build inputs as runtime dependencies\n  export;\n} >> "$out"\n'
declare -x builder="/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin/bash"
declare -x cmakeFlags=""
declare -x configureFlags=""
declare -x depsBuildBuild=""
declare -x depsBuildBuildPropagated=""
declare -x depsBuildTarget=""
declare -x depsBuildTargetPropagated=""
declare -x depsHostHost=""
declare -x depsHostHostPropagated=""
declare -x depsTargetTarget=""
declare -x depsTargetTargetPropagated=""
declare -x doCheck=""
declare -x doInstallCheck=""
declare -x mesonFlags=""
declare -x name="nix-shell"
declare -x nativeBuildInputs="/nix/store/5y7yj7x2cfhn1062zimp57m1hyz701yx-cowsay-3.7.0"
declare -x out="/nix/store/lr31gfg9m5r8a3xmxwqw4sdv5kyyysl0-nix-shell"
declare -x outputs="out"
declare -x patches=""
declare -x phases="buildPhase"
declare -x preferLocalBuild="1"
declare -x propagatedBuildInputs=""
declare -x propagatedNativeBuildInputs=""
declare -x shell="/nix/store/4bj2kxdm1462fzcc2i2s4dn33g2angcc-bash-5.2p32/bin/bash"
declare -x shellHook=$'$SHELL\n'
declare -x stdenv="/nix/store/hix7sl0wxajb5aq14afjdvzc3w0i8b14-stdenv-linux"
declare -x strictDeps=""
declare -x system="x86_64-linux"
```

:::

`result`はシェルスクリプトになっています。`nix develop`は何も設定されていない純粋なbashを起動し、起動時にこのシェルスクリプトを実行します。

## devShellの利点

### オーバーヘッドがない

devShellはただのシェルを起動するだけなのでオーバーヘッドが発生しません。

### 既存のツールをそのまま利用できる

`PATH`はdevShell起動前のものがそのまま引き継がれるため、既にインストールされているツールをそのまま使用できるのはdevcontainerなどでは得られない利点です。

### 開発環境の再現性

Nixの再現性をそのまま享受できるのも大きな利点です。`flake.lock`とセットで共有すれば、複数人で開発する場合もツールが完全に同一であることが保証されます。また、CIでdevShellを使えば、開発環境とCI環境の差異をなくすことができます。

### 実行環境のバージョン管理

実行環境をバージョン管理したくなったとき、通常は各実行環境ごとの専用ツールを使う必要がありますが、devShellを利用すればNixだけで簡潔します。例としてNode.jsのバージョン管理を行ってみます。

```nix :Node.js 20を使う
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_20
            corepack
          ];
        };
      }
    );
}
```

バージョン管理といっても、mkShell関数で利用したいバージョンのパッケージを指定するだけです。Nixストアでは複数バージョンのパッケージが同時に存在できるため、このようなことが簡単に実現できます。

## direnv

[direnv](https://github.com/direnv/direnv)を使うと最高の開発者体験を得ることができます。

https://github.com/direnv/direnv

direnv自体はNixとは関係のないツールです。direnvは`.envrc`というファイルが配置されているディレクトリを監視し、そのディレクトリに入ると`.envrc`に書かれた環境変数を自動で読み込んでくれます。

```bash :direnvの使い方
$ mkdir ~/my-project
$ cd ~/my-project

$ echo 'export FOO=foo' > .envrc
.envrc is not allowed

$ direnv allow
direnv: loading ~/path/to/my-project/.envrc
direnv: export +FOO

$ echo $FOO
foo

$ cd ..
direnv: unloading

$ echo $FOO
# 何も表示されない
```

[nix-direnv](https://github.com/nix-community/nix-direnv)というアダプターを使うと、devShellをdirenvで管理できるようになります。

https://github.com/nix-community/nix-direnv

`.envrc`を作成し、`use flake`と記述します。

```bash :nix-direnvの使い方
$ echo 'use flake' > .envrc

$ direnv allow
direnv: loading ~/path/to/flake/.envrc
direnv: using flake
direnv: nix-direnv: Renewed cache
direnv: export +AR +AS +CC +CONFIG_SHELL +CXX +HOST_PATH +IN_NIX_SHELL +LD +NIX_BINTOOLS +NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu +NIX_BUILD_CORES +NIX_CC +NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu +NIX_CFL
AGS_COMPILE +NIX_ENFORCE_NO_NATIVE +NIX_HARDENING_ENABLE +NIX_LDFLAGS +NIX_STORE +NM +NODE_PATH +OBJCOPY +OBJDUMP +RANLIB +READELF +SIZE +SOURCE_DATE_EPOCH +STRINGS +STRIP +__structuredAttrs +buildInputs +buildPhase +builder +cmakeFla
gs +configureFlags +depsBuildBuild +depsBuildBuildPropagated +depsBuildTarget +depsBuildTargetPropagated +depsHostHost +depsHostHostPropagated +depsTargetTarget +depsTargetTargetPropagated +doCheck +doInstallCheck +dontAddDisableDepTr
ack +mesonFlags +name +nativeBuildInputs +out +outputs +patches +phases +preferLocalBuild +propagatedBuildInputs +propagatedNativeBuildInputs +shell +shellHook +stdenv +strictDeps +system ~PATH ~XDG_DATA_DIRS

[Nixシェル]$ cowsay meow
 ______
< meow >
 ------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

[Nixシェル]$ cd ..
direnv: unloading

$ cowsay
cowsay: command not found
```

nix-direnvを利用することで、ディレクトリに入るだけでdevShellが自動で起動されるようになります。一度設定してしまえば開発環境の切り替えを意識する必要がなくなるのでとても便利です。
