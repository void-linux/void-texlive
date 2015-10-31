YEAR=$(./tlyear.sh)
true > linkpkgs
for p in archive/*.x86_64-linux.*; do
	bsdtar tvf $p | grep -v tlpkg/tlpobj >list
	if [ "$(grep -c ' -> ' list)" -eq "$(wc -l <list)" ] || [ "$p" = archive/texlive.infra.x86_64-linux.tar.xz ]; then
		pkg=${p#archive/}
		pkg=${pkg%.*.*.*}
		pkg=$(printf %s "$pkg" | tr . -)
		echo "provides+=' texlive-$pkg-bin-${YEAR}_1'"
		echo "replaces+=' texlive-$pkg-bin>=0'"
		echo $pkg >> linkpkgs
	fi
done
