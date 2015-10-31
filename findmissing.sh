#!/bin/sh

<texlive.tlpdb awk -v year=$(./tlyear.sh) '
  $1 == "name" && $2 ~ /^00/ { pkgname = 0; next }
  $1 == "name" && $2 == "texlive.infra" { $2 = "texlive-infra" }
  $1 == "name" && $2 ~ /\./ && $2 !~ /(i386|x86_64)-linux$/ { pkgname = 0; next }
  $1 == "name" {
	sub("\\.infra", "-infra", $2)
	split($2, f, ".")
  	pkgname = tarname = f[1]
	arch = f[2]
	if (arch) {
		if (system("grep -qxF " pkgname " subpkgs") == 0) {
			pkgname = 0; next
		}
		if (system("grep -qxF " pkgname " linkpkgs") == 0) {
			pkgname = 0; next
		}
		pkgname = pkgname "-bin";
		tarname = $2
		gsub("i386", "i686", arch)
		gsub("-linux$", "", arch)
	} else {
		arch = varch = "noarch"
	}
  }
  $1 == "revision" { pkgver = $2 }
  /^$/ { 
    if (pkgname) {
	# print pkgname, pkgver, tarname, arch
	if (system("[ -f binpkgs/texlive-" pkgname "-" year "." pkgver "*." arch ".xbps ]")) {
		if (pkgname == "texlive-infra")
			tarname = "texlive.infra"
		print "archive/" tarname ".tar.xz"
	}
    }
  }
'
