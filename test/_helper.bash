#!/usr/bin/env bash
##############################################################################
# _helper.bash
#
# Helper file for running tests
#
##############################################################################

# Provide extension name
export ELLIPSIS_XNAME="__name__"
export ELLIPSIS_XNAME_U="$(tr '[a-z]' '[A-Z]' <<< "$ELLIPSIS_XNAME")"
export ELLIPSIS_XNAME_L="$(tr '[A-Z]' '[a-z]' <<< "$ELLIPSIS_XNAME")"

# Set path vars
export TESTS_DIR="$BATS_TEST_DIRNAME"
export ELLIPSIS_PATH="$(cd "$TESTS_DIR/../deps/ellipsis" && pwd)"
export ELLIPSIS_SRC="$ELLIPSIS_PATH/src"
export ELLIPSIS_XPATH="$(cd "$TESTS_DIR/.." && pwd)"
export ELLIPSIS_XSRC="$ELLIPSIS_XPATH/src"
export PATH="$ELLIPSIS_PATH/bin:$PATH"

# Don't log tests
export ELLIPSIS_LOGFILE="/dev/null"

# Reset nesting level
export ELLIPSIS_LVL=0

##############################################################################

# Init ellipsis, which replaces bat's `load` function with ours.
load "$ELLIPSIS_SRC/init.bash"

##############################################################################

load version
load extension

# Updated ellipsis version if not sufficient (make can't auto update)
if ! extension.is_compatible; then
    ./deps/ellipsis/bin/ellipsis update ellipsis > /dev/null 2>&1
fi

##############################################################################
