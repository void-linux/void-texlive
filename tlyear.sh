#!/bin/sh
awk -F/ '$1 == "depend release" {print $2; exit}' texlive.tlpdb
