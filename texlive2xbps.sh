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

if [ -d bin ]; then
	mkdir -p $tmpdir/usr/bin
	for f in bin/*/*; do
		ln -srf $f $tmpdir/usr/bin
	done
fi

[ -d texmf-dist ] && mv texmf-dist/* .

if [ -d tlpkg ]; then
	mv tlpkg ..
fi
popd

mkdir -p binpkgs
cd binpkgs

awk -v year=$YEAR -v tmpdir=$tmpdir <$tmpdir/$TEXMF/../tlpkg/tlpobj/*.tlpobj '
function q(s) {
	gsub("\047", "\047\\\047\047", s)
	return "\047" s "\047"
}
BEGIN {
	arch = "noarch"
	depends = "texlive>=" year
	homepage = "https://www.tug.org/texlive/"
}
$1 == "binfiles" {
	arch = $2  
	sub("arch=", "", arch)
	sub("\\." arch, "-bin", pkgname)
}
$1 == "name" {
	pkgname = $2
	sub("\\.infra", "-infra", pkgname)
}
$1 == "catalogue-license" { license = toupper($2) }
$1 == "revision" { revision = $2 }
$1 == "catalogue-version" { version = $2; gsub("^\\.|[ -]", "", version) }
$1 == "catalogue-ctan" { homepage = "https://www.ctan.org/tex-archive" $2 }
$1 == "shortdesc" { desc = $0; sub("^shortdesc *", "", desc) }
$1 == "depend" {
	dep = "$2"
	sub("\\.infra", "-infra", dep)
	sub("\\." arch, "-bin", dep)
	depends = depends " " dep ">=" year
}

END {
	pkgver = year "." revision (version ? "." version : "")
	if (!desc) desc = "TeXLive " pkgname " package"
	if (arch == "i386-linux") arch="i686"
	sub("-linux$", "", arch)

	system("xbps-create "\
	"-A "q(arch)" "\
	"-B texlive2xbps "\
	"-D "q(depends)" "\
	"-H "q(homepage)" "\
	"-l "q(license)" "\
	"-m \"texlive2xbps <texlive2xbps@voidlinux.eu>\" "\
	"-n texlive-"q(pkgname)"-"q(pkgver)"_1 "\
	"-s "q(desc)" "\
	tmpdir)
}'

rm -rf "$tmpdir"
