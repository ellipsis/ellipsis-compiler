# compiler.bash
#
# Compiler functions
#
##############################################################################

load msg
load log
load path

##############################################################################

EC_COMMENT="${EC_COMMENT:-"#"}"
EC_PROMPT="${EC_PROMPT:-"_>"}"

# Default mode, overwritten by 'mode' option and EC_MODE variable
EC_DMODE="644"

##############################################################################

# Return codes used by the line parser
EC_RETURN_FI=10
EC_RETURN_ELSE=11
EC_RETURN_ELIF=12

##############################################################################

# Keep current IFS for cleanup
EC_CIFS="$IFS"

compiler.cleanup() {
    # Restore original IFS
    IFS="$EC_CIFS"

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
    local err_type="${2:-"Syntax error"}"

    msg.print "$err_type in '$file_name' at line nr $line_nr:"
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

# Compiles a file
compiler.compile() {
    if [ $# -lt 1 ]; then
        msg.print "Please provide an input file"
        exit 1
    fi
    local file="$(path.expand "$1")"
    file="$(path.abs_path "$file")"
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
    chmod "${EC_MODE:-$EC_DMODE}" "$dest"

    log.ok "Successfully compiled $file_name"
    compiler.cleanup
}

##############################################################################

# Parse a file
compiler.parse_file() {
    local file="$1"
    local raw="$2"

    # Keep pwd and line_nr
    local cwd="$(pwd)"
    local tmp_line_nr="$line_nr"

    # Expand '~' and '$HOME'
    file="$(path.expand "$file")"

    if [ ! -f "$file" ]; then
        compiler.print_error "File not found : '$file'" "File error"
        exit 1
    fi

    # Expand to full file path
    file="$(path.abs_path "$file")"

    # Run in correct folder (relative file support)
    cd "$(dirname "$file")"

    # Start line nr's from zero for this file
    line_nr=0

    # Parse file
    while read line; do
        local output=true
        compiler.parse_line "$line"
        local ret="$?"
        # else, elif and fi not returned unles an if statement is missing
        if [ "$ret" -eq "$EC_RETURN_FI" -o "$ret" -eq $EC_RETURN_ELSE -o \
             "$ret" -eq $EC_RETURN_ELIF ]; then
            compiler.print_error "Missing 'if' statement"
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
            output=true
            return 0
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

compiler.parse_line() {
    # Count parsed lines
    let line_nr=line_nr+1

    # Parse line if raw is not set
    if [ -z "$raw" ] && [[ "$line" =~ ^[[:space:]]*"$EC_COMMENT"[[:space:]]*"$EC_PROMPT".* ]]; then
        # Also strip leading whitespace
        local raw_line="$(echo -e "$line" | sed -e 's/^[[:space:]]*//')"
        local keyword="$(compiler.get_keyword "$raw_line")"
        local line="$(compiler.get_line "$raw_line")"

        if "$output"; then
            case $keyword in
                include)
                    compiler.parse_file "$line"
                    ;;
                include_raw)
                    compiler.parse_file "$line" "raw"
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
                    log.fail "$line"
                    exit 1
                    ;;
                warn)
                    log.warn "$line"
                    ;;
                mode)
                    # Set the file mode
                    EC_DMODE="$line"
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
