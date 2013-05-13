#!/bin/bash

# viewbug.sh - CLI for reading Debian bug reports
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

G_VERSION=0.3
G_FILEKEY="$$$RANDOM"

F_CMD='mutt -f $FILE'
F_OUT_NAME='$BUGNO-$G_FILEKEY.mbox'
F_OUT_TEMP=1
F_OUT_COMBINE=0

declare -a NLIST
declare -a PLIST
declare -a XARGV

help () {
    echo '
    viewbugs.sh - Copyright (C) 2013 Jens Oliver John
    This program comes with ABSOLUTELY NO WARRANTY. This is free
    software, and you are welcome to redistribute it under certain
    conditions. Refer to the LICENSE file in the distribution for
    details.

    viewbugs.sh is a CLI for reading Debian bug reports.

    Usage:

        viewbugs.sh [OPTIONS] <BUGLIST>

        <BUGLIST> is a list of instances of the two options

            -n BUG#
            -p PKG[/version]

        which refer to a bug by number or to all bugs of a package
        respectively. BUG# has to be an integer. PKG is a package
        name, optionally refering to a specific package version.

    Options:

        -A ARG
            Add an extra argument ARG when calling apt-listbugs.
            May be specified multiple times.
            Refer to apt-listbugs(1) for more information.

        -c
            Combine all retrieved bug reports into a single MBOX file.

        -h   
            Print this short synopsis.
 
        -k
            Keep the MBOX files with the retrieved bug reports.

        -o NAME-TEMPLATE
            Set the template used for the generation of the output
            MBOX files. If $BUGNO or $G_FILEKEY occur, they will
            expand to the current bug number and an integer, the
            value of which is unique for each instance.
            NAME-TEMPLATE **MUST** contain at least one instance of
            $G_FILEKEY, because it is used for globbing.
            Defaults to "$BUGNO-$G_FILEKEY.mbox".

       
        -v  
            Print the version.

        -x COMMAND
            Use COMMAND as the MBOX reader. $FILE in COMMAND will
            be replaced with the path of the file to be displayed.
            Defaults to "mutt -f $FILE".'
}

while getopts "ctx:o:vhn:p:" OPT; do
    case $OPT in
        A)  XARGV=(${XARGV[@]} "$OPTARG") ;;
        c)  F_OUT_COMBINE=1 ;;
        h)  help; exit 0 ;;
        k)  F_OUT_TEMP=0 ;;
        n)  NLIST=(${NLIST[@]} "$OPTARG") ;;
        o)  F_OUT_NAME=$OPTARG ;;
        p)  PLIST=(${PLIST[@]} "$OPTARG") ;;
        v)  echo "$0 script version: $G_VERSION"; exit 0 ;;
        x)  if type "$OPTARG" &>/dev/null; then
                F_CMD=$OPTARG
            else
                echo "$0: error: $OPTARG is not in $PATH." 1>&2
                exit 1
            fi
            ;;
    esac
done

if [[ ${#NLIST[@]} -eq 0 && ${#PLIST[@]} -eq 0 ]]; then
    echo "No packages or bug#s specified. Specify -h for usage information."
    exit 0
fi

for n in ${NLIST[@]}; do
    BUGNO=$n
    OUTFILE=$(eval echo $F_OUT_NAME)
    wget -q -O "$OUTFILE" "http://bugs.debian.org/cgi-bin/bugreport.cgi?mbox=yes;bug=$n"
    if [[ $(wc -c < "$OUTFILE") -eq 0 ]]; then
        echo "Error: bug #$n does not exist or could not be retrieved."
        rm "$OUTFILE"
    fi
done

for p in ${PLIST[@]}; do
    BUGLIST=$(apt-listbugs -q ${XARGV[@]} list "$p" | grep -o '#[[:digit:]]\+' | tr -d '#')
    if [[ -z $BUGLIST ]]; then
        echo "No bugs for package $p with current apt-listbugs parameters."
    else
        for n in $BUGLIST; do
            BUGNO=$n
            OUTFILE=$(eval echo $F_OUT_NAME)
            wget -q -O "$OUTFILE" "http://bugs.debian.org/cgi-bin/bugreport.cgi?mbox=yes;bug=$n"
            if [[ $(wc -c < "$OUTFILE") -eq 0 ]]; then
                echo "Error: bug #$n from package $p could not be retrieved."
                rm $OUTFILE
            fi
        done
    fi
done

if [[ $F_OUT_COMBINE = 1 ]]; then
    CAB="combined-${G_FILEKEY}.mbox"
    cat *$G_FILEKEY* > $CAB
    if ! FILE=$CAB eval $F_CMD; then
        echo "Error: failed to execute $F_CMD on $CAB."
    fi
else
    for mbox in *$G_FILEKEY*; do
        if ! FILE=$mbox eval $F_CMD; then
            echo "Error failed to execute $F_CMD on $mbox:"
        fi
    done
fi

# clean up

[[ $F_OUT_TEMP = 1 ]] && rm ./*$G_FILEKEY*
