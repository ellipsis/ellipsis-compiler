#!/usr/bin/env bash
##############################################################################
# init.sh
#
# Initializes an official ellipsis extension.
#
##############################################################################

if [ "$#" -ne 1 ]; then
    echo "Usage: ./init.sh <extension_name>"
    exit 1
fi

name="$1"
name_upper="$(tr '[a-z]' '[A-Z]' <<< "$name")"
name_lower="$(tr '[A-Z]' '[a-z]' <<< "$name")"
name_capital="${name_upper:0:1}${name_lower:1}"

##############################################################################
# Replace all place holders

sed_string="s/__name__/$name/g;\
    s/__name_u__/$name_upper/g;\
    s/__name_l__/$name_lower/g;\
    s/__name_c__/$name_capital/g;"

sed -i "$sed_string" ellipsis.sh README.md Makefile docs/* bin/* src/* test/*

##############################################################################
# File setup and cleanup

mv bin/ellipsis-extension "bin/ellipsis-$name_lower"

rm "${BASH_SOURCE[0]}"

##############################################################################
