#!/usr/bin/env bash
##############################################################################

pkg.link() {
    fs.link_file "$PKG_PATH/bin/ellipsis-compiler" "$ELLIPSIS_PATH/bin/ellipsis-compiler"
}

##############################################################################

pkg.unlink() {
    rm "$ELLIPSIS_PATH/bin/ellipsis-compiler"
}

##############################################################################
