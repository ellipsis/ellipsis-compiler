# compiler.bash
#
# Compiler functions
#
##############################################################################

load msg
load log

##############################################################################

EC_COMMENT="${EC_COMMENT:-"#"}"
EC_PROMPT="${EC_PROMPT:-"_>"}"

EC_FILE_MODE="${EC_FILE_MODE:-644}"

##############################################################################

# Return codes used by the line parser
EC_RETURN_FI=10
EC_RETURN_ELSE=11
EC_RETURN_ELIF=12

##############################################################################

compiler.cleanup() {
    # Reset IFS to default
    unset IFS

    # Remove buffer file if it exists
    if [ -f "$target" ] && ! utils.is_true "$EC_KEEP_BUF"; then
        rm "$target"
    fi
}
trap compiler.cleanup EXIT SIGINT SIGTERM

##############################################################################

# Outputs an error message
# expects $file, $line_nr and $raw_line or $line to be set
compiler.print_error() {
    local err_msg="$1"

    msg.print "Syntax error in '$file_name' at line nr $line_nr:"
    msg.print "| $file:$line_nr"
    msg.print "|    '${raw_line:-$line}'"
    if [ -n "$err_msg" ]; then
        msg.print "> $err_msg"
    fi
}

##############################################################################

# Extracts the keyword from a line
compiler.get_keyword() {
    awk '{print $2;}' <<< "$1"
}

##############################################################################

# Extracts all content behind the keyword
compiler.get_line() {
    awk '{for (i=3; i<NF; i++) printf $i " "; print $NF}' <<<"$1"
}

##############################################################################

#@TODO: refactor
# Compiles a file
compiler.compile() {
    if [ $# -lt 1 ]; then
        msg.print "Please provide an input file"
        exit 1
    fi
    local file="$(path.abs_path "$1")"
    local file_name="$(basename "$file")"
    local dest="${2:-${file}.out}"
    local target="$(mktemp "/tmp/ec_${file_name}-XXXXXX")"

    # Preserve leading whitespace by changing word separator
    IFS=$'\n'

    msg.bold "Compiling $file_name"
    if ! utils.is_true "$EC_NOHEADER"; then
        echo "$EC_COMMENT Compiled by Ellipsis-Compiler(v$ELLIPSIS_XVERSION) on $(date)" > "$target"
    fi
    compiler.parse_file "$file"

    # Move temp target to final destination
    cp "$target" "$dest"
    if [ ! "$?" -eq 0 ]; then
        log.fail "Could not write $dest"
        exit 1
    fi

    # Set correct file mode
    chmod "$EC_FILE_MODE" "$dest"

    log.ok "Successfully compiled $file_name"
    compiler.cleanup
}

##############################################################################

#@TODO: refactor
# Parse a file
compiler.parse_file() {
    local file="$1"
    local raw="$2"

    # Keep pwd and line_nr
    local cwd="$(pwd)"
    local tmp_line_nr="$line_nr"

    # Run in correct folder (relative file support)
    cd "$(dirname "$file")"

    # Start line nr's from zero for this file
    line_nr=0

    # Parse file
    while read line; do
        local output=true
        compiler.parse_line "$line"
        local ret="$?"
        if [ "$ret" -eq 1 -o "$ret" -eq 2 ]; then
            compiler.print_error "'if' without matching 'fi'"
            exit 1
        fi
    done < "$file"

    # Restore line_nr, and pwd
    line_nr="$tmp_line_nr"
    cd "$cwd"
}

##############################################################################

# Extract the condition from a line
compiler.get_condition() {
    local cmd="$1"
    local sed_string="s/^$EC_COMMENT$EC_PROMPT if //;\
                      s/^$EC_COMMENT$EC_PROMPT elif //;\
                      s/; then//;\
                      s/;then//"

    sed "$sed_string" <<< "$cmd"
}

##############################################################################

#@TODO: refactor
# Parse an IF structure (if, elif)
compiler.parse_if() {
    if eval "$1"; then
        output=true
    else
        output=false
    fi

    local ignore_else=false

    # Process the if statement
    while read line; do
        compiler.parse_line "$line"
        local ret="$?"

        # Handle relevant parser return codes
        if [ "$ret" -eq "$EC_RETURN_FI" ]; then
            return
        elif [ "$ret" -eq "$EC_RETURN_ELSE" ] && ! "$ignore_else"; then
            if "$output"; then
                output=false
            else
                output=true
            fi
        elif [ "$ret" -eq "$EC_RETURN_ELIF" ]; then
            output=false
            ignore_else=true
        fi
    done

    # Only reached if no FI was encountered
    compiler.print_error "'if' without matching 'fi'"
    exit 1
}

##############################################################################

#@TODO: refactor
compiler.parse_line() {
    # Count parsed lines
    let line_nr=line_nr+1

    # Parse line if raw is not set
    if [ -z "$raw" ] && [[ "$line" =~ ^"$EC_COMMENT"[[:space:]]*"$EC_PROMPT".* ]]; then
        local raw_line="$line"
        local keyword="$(compiler.get_keyword "$raw_line")"
        local line="$(compiler.get_line "$raw_line")"

        if "$output"; then
            case $keyword in
                include)
                    if [ -f "$line" ]; then
                        local file="$(path.abs_path "$line")"
                        compiler.parse_file "$file"
                    else
                        compiler.print_error "File not found : '$line'"
                        exit 1
                    fi
                    ;;
                include_raw)
                    if [ -f "$line" ]; then
                        local file="$(path.abs_path "$line")"
                        compiler.parse_file "$file" "raw"
                    else
                        compiler.print_error "File not found : '$line'"
                        exit 1
                    fi
                    ;;
                if)
                    # Get condition and parse if
                    compiler.parse_if "$(compiler.get_condition "$line")"
                    ;;
                else)
                    # Return else code to if parser
                    return "$EC_RETURN_ELSE"
                    ;;
                elif)
                    # Return elif code to if parser and optionally parse own if
                    if "$output"; then
                        return "$EC_RETURN_ELIF"
                    else
                        compiler.parse_if "$(compiler.get_condition "$line")"
                        return "$EC_RETURN_FI"
                    fi
                    ;;
                fi)
                    # Return fi code to if parser
                    return "$EC_RETURN_FI"
                    ;;
                raw)
                    # Do funky stuff
                    eval "$line"
                    ;;
                \>|write)
                    if "$output"; then
                        echo "$line" >> "$target"
                    fi
                    ;;
                msg)
                    msg.print "$file_name: $line"
                    ;;
                fail)
                    log.warn "Failed to compile: $line"
                    exit 1
                    ;;
                *)
                    compiler.print_error "Unknown keyword '$keyword'"
                    exit 1
                    ;;
                esac
        else
            case $keyword in
                else)
                    # Return else code to if parser
                    return "$EC_RETURN_ELSE"
                    ;;
                elif)
                    # Return elif code to if parser and optionally parse own if
                    if "$output"; then
                        return "$EC_RETURN_ELIF"
                    else
                        compiler.parse_if "$(compiler.get_condition "$line")"
                        return "$EC_RETURN_FI"
                    fi
                    ;;
                fi)
                    # Return fi code to if parser
                    return "$EC_RETURN_FI"
                    ;;
                *)
                    : # Nothing to be done
                    ;;
                esac
        fi
    # Remove commented lines
    elif [[ "$line" =~ ^[[:space:]]*"$EC_COMMENT".* ]] ||\
            [[ "$line" =~ ^$ ]]; then
        # Keep comments if configured
        if utils.is_true "$EC_KEEP_WS"; then
            echo "$line" >> "$target"
        fi
    # Add normal lines to the output
    elif "$output"; then
        echo "$line" >> "$target"
    fi
}

##############################################################################
