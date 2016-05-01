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

##############################################################################

# Return codes used by line parser
EC_KW_FI=10
EC_KW_ELSE=11
EC_KW_ELIF=12

##############################################################################

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

compiler.get_keyword() {
    awk '{print $2;}' <<< "$1"
}

##############################################################################

compiler.get_line() {
    awk '{for (i=3; i<NF; i++) printf $i " "; print $NF}' <<<"$1"
}

##############################################################################

compiler.compile() {
    local file="$(path.abs_path "$1")"
    local file_name="$(basename "$file")"
    if [ -z "$file" ]; then
        msg.print "Please provide an input file"
        exit 1
    fi

    # Target defaults to "$file.out"
    local target="${2:-${file}.out}"

    #@TODO Compile to tmp file and replace if successful

    # Preserve leading whitespace by changing word separator
    IFS=$'\n'

    msg.bold "Compiling $file_name"
    echo "$EC_COMMENT Compiled by Ellipsis-Compiler on $(date)" > "$target"
    compiler.parse_file "$file"

    # Reset IFS to default
    unset IFS

    #@TODO Log if config changed
    msg.print "Successfully compiled $file_name"
}

##############################################################################

compiler.parse_file() {
    local file="$1"
    local raw="$2"

    # Keep pwd, line_nr and increment indent lvl
    local cwd="$(pwd)"
    local tmp_line_nr="$line_nr"
    #let ELLIPSIS_LVL=ELLIPSIS_LVL+1

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

    # Restore indent lvl, line_nr, and pwd
    #let ELLIPSIS_LVL=ELLIPSIS_LVL-1
    line_nr="$tmp_line_nr"
    cd "$cwd"
}

##############################################################################

compiler.get_condition() {
    local cmd="$1"
    local sed_string="s/^$EC_COMMENT$EC_PROMPT if//;\
                      s/^$EC_COMMENT$EC_PROMPT elif//;\
                      s/; then//"

    sed "$sed_string" <<< "$cmd"
}

##############################################################################

compiler.parse_if() {
    if eval "$1"; then
        output=true
    else
        output=false
    fi

    local ignore_else=false

    while read line; do
        compiler.parse_line "$line"
        local ret="$?"

        if [ "$ret" -eq "$EC_KW_FI" ]; then
            return
        elif [ "$ret" -eq "$EC_KW_ELSE" ] && ! "$ignore_else"; then
            if "$output"; then
                output=false
            else
                output=true
            fi
        elif [ "$ret" -eq "$EC_KW_ELIF" ]; then
            output=false
            ignore_else=true
        fi
    done

    compiler.print_error "'if' without matching 'fi'"
    exit 1
}

##############################################################################

compiler.parse_line() {
    # Count parsed lines
    let line_nr=line_nr+1

    if [ -z "$raw" ] && [[ "$line" =~ ^"$EC_COMMENT"[[:space:]]*"$EC_PROMPT".* ]]; then
        local raw_line="$line"
        local keyword="$(compiler.get_keyword "$raw_line")"
        local line="$(compiler.get_line "$raw_line")"

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
                return "$EC_KW_ELSE"
                ;;
            elif)
                # Return elif code to if parser and optionally parse own if
                if "$output"; then
                    return "$EC_KW_ELIF"
                else
                    compiler.parse_if "$(compiler.get_condition "$line")"
                    return "$EC_KW_FI"
                fi
                ;;
            fi)
                # Return fi code to if parser
                return "$EC_KW_FI"
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
                msg.print "$line"
                exit 1
                ;;
            *)
                compiler.print_error "unknown keyword '$keyword'"
                exit 1
                ;;
            esac
    elif [[ "$line" =~ ^[[:space:]]*"$EC_COMMENT".* ]] ||\
            [[ "$line" =~ ^$ ]]; then
        # Ignore commented and empty lines
        :
    elif "$output"; then
        echo "$line" >> "$target"
    fi
}

##############################################################################
