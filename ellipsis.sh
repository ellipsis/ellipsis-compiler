#!/usr/bin/env bash
##############################################################################

pkg.link() {
    fs.link_file "$PKG_PATH/bin/ellipsis-compiler" "$ELLIPSIS_PATH/bin/ellipsis-compiler"
    fs.link_file "$PKG_PATH/bin/ellipsis-compiler" "$ELLIPSIS_PATH/bin/ellipsis-compile"
}

##############################################################################

pkg.unlink() {
    rm "$ELLIPSIS_PATH/bin/ellipsis-compiler"
    rm "$ELLIPSIS_PATH/bin/ellipsis-compile"
}

##############################################################################
