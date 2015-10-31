#!/bin/bash

TEXMF=usr/share/texmf-dist
YEAR=$(./tlyear.sh)

set -e

archive=$(realpath "$1")

tmpdir=$(mktemp -d textmp.XXXXXXXX)
tmpdir=$(realpath "$tmpdir")

pushd $tmpdir
mkdir -p $TEXMF
cd $TEXMF
tar xvf "$archive"

arch=$(sed -n '/^binfiles/s/^binfiles arch=\([^ ]*\).*/\1/p' tlpkg/tlpobj/*.tlpobj)
pkgname=$(sed -n '/^name/{s/^[^ ]* //;s/\.infra/-infra/;p}' tlpkg/tlpobj/*.tlpobj)
case "$pkgname" in
	*.$arch) pkgname=${pkgname%.$arch}-bin ;;
esac
license=$(sed -n '/^catalogue-license/{s/^[^ ]* //;y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/;p}' tlpkg/tlpobj/*.tlpobj)
revision=$(sed -n '/^revision/s/^[^ ]* //p' tlpkg/tlpobj/*.tlpobj)
version=$(sed -n '/^catalogue-version/{s/^[^ ]* //;s/^\.//;s/[ -]//g;p}' tlpkg/tlpobj/*.tlpobj)
pkgver="${YEAR}.${revision}${version:+.}${version}"
homepage="https://www.ctan.org/tex-archive$(sed -n '/^catalogue-ctan/s/^[^ ]* //p' tlpkg/tlpobj/*.tlpobj)"
desc=$(sed -n '/^shortdesc/s/^[^ ]* //p' tlpkg/tlpobj/*.tlpobj)
: ${desc:=TexLive $pkgname package}
dependencies=$(sed -n '/^depend/{s/^[^ ]* /texlive-/;s/\.ARCH$/-bin/;/\.infra/d;s/$/>'=$YEAR'/;p}' tlpkg/tlpobj/*.tlpobj | tr '\n' ' ')
dependencies+=" texlive>=${YEAR}"

if [ -d bin ]; then
	mkdir -p $tmpdir/usr/bin
	for f in bin/*/*; do
		ln -srf $f $tmpdir/usr/bin
	done
fi

case "$arch" in
	i386-linux) arch=i686;;
	*-linux) arch=${arch%-linux};;
	'') arch=noarch;;
	*) echo "What should i do with arch $arch?"; exit 1;;
esac

[ -d texmf-dist ] && mv texmf-dist/* .

rm -rf tlpkg/tlpobj
rmdir tlpkg || true
if [ -d tlpkg ]; then
	mv tlpkg ..
fi
popd

mkdir -p binpkgs
cd binpkgs

xbps-create \
	-A "$arch" \
	-B texlive2xbps \
	-D "$dependencies" \
	-H "$homepage" \
	-l "$license" \
	-m "texlive2xbps <texlive2xbps@voidlinux.eu>" \
	-n "texlive-${pkgname}-${pkgver}_1" \
	-s "$desc" \
	"$tmpdir"

rm -rf "$tmpdir"
