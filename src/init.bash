# init.bash
#
##############################################################################

# Utility to load other modules. Uses a tiny bit of black magic to ensure each
# module is only loaded once.
load() {
    # Use indirect expansion to reference dynamic variable which flags this
    # module as loaded.
    local loaded="__loaded_$1"

    # Only source modules once
    if [[ -z "${!loaded}" ]]; then
        # Mark this module as loaded, prevent infinite recursion, ya know...
        eval "$loaded=1"

        # Load extension specific sources if possible
        if [ -n "$ELLIPSIS_XSRC" -a -f "$ELLIPSIS_XSRC/$1.bash" ]; then
            source "$ELLIPSIS_XSRC/$1.bash"
        else
            source "$ELLIPSIS_SRC/$1.bash"
        fi
    fi
}

# Load variables
load vars

##############################################################################
