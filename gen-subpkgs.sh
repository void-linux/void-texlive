#!/bin/sh

YEAR=$(./tlyear.sh)

echo "#!/bin/sh" >mklinks.sh
for f in $(cat subpkgs); do
	echo "ln -s texlive texlive-$f-bin" >>mklinks.sh
	bsdtar tvf archive/$f.x86_64-linux.tar.xz |
	awk -v pkgname=$f '
BEGIN {
	print "texlive-" pkgname "-bin_package() {"
	print "	short_desc+=\" - " pkgname " binaries\""
	print "	depends=\"${sourcepkg}>=${version}_${revision}\""
	print "	pkg_install() {"
}
END {
	print "	}"
	print "}"
}
/tlpkg\/tlpobj/ { next }
{
	sub(".*/", "", $9)
	print "		vmove usr/bin/" $9	
}
#lrwxrwxrwx  0 root   root        0 Aug 14  2014 bin/x86_64-linux/dviluatex -> luatex
#-rwxr-xr-x  0 root   root 11101488 May 11 11:25 bin/x86_64-linux/luajittex
'
done
