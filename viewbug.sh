#!/bin/bash

# viewbug.sh - CLI reader for Debian bug reports
# Copyright (C) 2013 Jens Oliver John <asterisk@2ion.de>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

G_VERSION=0.1-rc
G_FILEKEY=$$
G_TMP=$(mktemp)

F_CMD='mutt -f $FILE'
F_OUT_NAME='$BUGNO-$G_FILEKEY.mbox'
F_OUT_TEMP=1
F_OUT_COMBINE=0

declare -a NLIST
declare -a PLIST

help () {
    echo "$0 [-kxcovh] -p PKG -n BUG#"
    echo "Development homepage: https://github.com/2ion/viewbug"
}

while getopts "ctx:o:vhn:p:" OPT; do
    case $OPT in
        h)
            help; exit 0 ;;
        v)
            echo "$0 script version: $G_VERSION" ;;
        k) F_OUT_TEMP=0 ;;
        x)
            if type "$OPTARG" &>/dev/null; then
                F_CMD=$OPTARG
            else
                echo "$0: error: $OPTARG is not in $PATH." 1>&2
                exit 1
            fi
            ;;
        o) F_OUT_NAME=$OPTARG ;;
        n) NLIST=(${NLIST[@]} "$OPTARG") ;;
        p) PLIST=(${PLIST[@]} "$OPTARG") ;;
        c) F_OUT_COMBINE=1 ;;
    esac
done

for n in ${NLIST[@]}; do
    BUGNO=$n
    wget -q -O "$(eval echo $F_OUT_NAME)" "http://bugs.debian.org/cgi-bin/bugreport.cgi?mbox=yes;bug=$n"
done

for p in ${PLIST[@]}; do
    for n in $(apt-listbugs -q list "$p" | grep -o '#[[:digit:]]\+' | tr -d '#'); do
        BUGNO=$n
        wget -q -O "$(eval echo $F_OUT_NAME)" "http://bugs.debian.org/cgi-bin/bugreport.cgi?mbox=yes;bug=$n"
    done
done

if [[ $F_OUT_COMBINE = 1 ]]; then
    CAB="combined-${G_FILEKEY}.mbox"
    cat *$G_FILEKEY* > $CAB
    FILE=$CAB eval $F_CMD
else
    for mbox in *$G_FILEKEY*; do
        FILE=$mbox eval $F_CMD
    done
fi

# clean up

[[ $F_OUT_TEMP = 1 ]] && rm ./*-$G_FILEKEY*
