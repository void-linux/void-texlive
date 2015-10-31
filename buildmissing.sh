#!/bin/sh

mkdir -p binpkgs
./findmissing.sh | xargs -d'\n' -l -n1 -P $(nproc) ${DRYRUN:+echo} ./texlive2xbps.sh
XBPS_ARCH=i686 xbps-rindex -f -a binpkgs/*.xbps
XBPS_ARCH=x86_64 xbps-rindex -f -a binpkgs/*.xbps
