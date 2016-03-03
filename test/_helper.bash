#!/usr/bin/env bash
##############################################################################
# _helper.bash
#
# Helper file for running tests
#
##############################################################################

export TESTS_DIR="$BATS_TEST_DIRNAME"
export ELLIPSIS_PATH="$(cd "$TESTS_DIR/../deps/ellipsis" && pwd)"
export ELLIPSIS_SRC="$ELLIPSIS_PATH/src"
export ELLIPSIS_XPATH="$(cd "$TESTS_DIR/.." && pwd)"
export ELLIPSIS_XSRC="$ELLIPSIS_XPATH/src"
export PATH="$ELLIPSIS_XPATH/bin:$PATH"

export ELLIPSIS_LOGFILE="/dev/null"

##############################################################################

# Initialize ellipsis-__name_l__, which replaces bat's `load` function with ours.
load ../src/init

##############################################################################

load vars
load extension

# Updated ellipsis version if not sufficient (make can't auto update)
if ! extension.is_compatible; then
    ./deps/ellipsis/bin/ellipsis update ellipsis > /dev/null 2>&1
fi

##############################################################################
