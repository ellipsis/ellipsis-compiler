# cli.bash
#
# CLI functions
#
##############################################################################

load extension
load msg
load log
load git

##############################################################################

# prints usage
cli.usage() {
msg.print "\
Usage: ellipsis-__name_l__ <command>
  Options:
    -h, --help     show help
    -v, --version  show version

  Commands:
"
}

##############################################################################

# prints version
cli.version() {
    local cwd="$(pwd)"
    cd "$ELLIPSIS_XPATH"

    local sha1="$(git.sha1)"
    msg.print "\033[1mv$ELLIPSIS_XVERSION\033[0m ($sha1)"

    cd "$cwd"
}

##############################################################################

cli.run() {
    # Check if Ellipsis version is sufficient
    if ! extension.is_compatible; then
        log.fail "Ellipsis-__name__ v$ELLIPSIS_XVERSION needs at least Ellipsis v$ELLIPSIS_VERSION_DEP"
        msg.print "Please update Ellipsis!"
        exit 1
    fi

    case "$1" in
        help|--help|-h)
            cli.usage
            ;;
        version|--version|-v)
            cli.version
            ;;
        *)
            if [ $# -gt 0 ]; then
                msg.print "ellipsis-__name_l__: invalid command -- $1"
            fi
            cli.usage
            return 1
            ;;
    esac
}

##############################################################################
