# compiler.bash
#
# Compiler functions
#
##############################################################################

load msg
load log

##############################################################################

EC_COMMENT="${EC_COMMENT:-"#"}"
EC_PROMPT="${EC_PROMPT:-"->$"}"

##############################################################################

# Return codes used by line parser
EC_KW_FI=10
EC_KW_ELSE=11
EC_KW_ELIF=12

##############################################################################

compiler.print_error() {
    local err_msg="$1"

    msg.print "Syntax error in $file at line nr $line_nr:"
    msg.print ">    '${raw_line:-$line}'"
    if [ -n "$err_msg" ]; then
        msg.print ">    $err_msg"
    fi
}

##############################################################################

compiler.get_keyword() {
    cut -d ' ' -f2 <<< "$1"
}

##############################################################################

compiler.get_line() {
    cut -d ' ' -f3- <<< "$1"
}

##############################################################################

compiler.compile() {
    local file="$1"
    if [ -z "$file" ]; then
        msg.print "Please provide an input file"
        exit 1
    fi

    #@TODO Compile to tmp file and replace if successfull

    local target="${2:-${file}.out}"
    msg.bold "Compiling $file"
    echo "$EC_COMMENT Compiled by Ellipsis-Compiler on $(date)" > "$target"
    compiler.parse_file "$file"

    #@TODO Log if config changed
    msg.print "Successfully compiled $file"
}

##############################################################################

compiler.parse_file() {
    local file="$1"
    local raw="$2"

    # Reset line number before parsing file
    line_nr=0

    # Parse file
    while read line; do
        local output=1
        compiler.parse_line "$line"
        if [ "$?" -eq 1 -o "$?" -eq 2 ]; then
            compiler.print_error "'if' without matching 'fi'"
            exit 1
        fi
    done < "$file"
}

##############################################################################

compiler.get_var() {
    local cmd="$1"
    local sed_string="s/^$EC_COMMENT$EC_PROMPT def_var//"

    sed "$sed_string" <<< "$cmd"
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

compiler.eval_condition() {
    eval "$1"
    echo "$?"
}

##############################################################################

compiler.parse_if() {
    output="$1"
    local ignore_else=0

    while read line; do
        compiler.parse_line "$line"
        local ret="$?"

        if [ "$ret" -eq "$EC_KW_FI" ]; then
            return
        elif [ "$ret" -eq "$EC_KW_ELSE" -a "$ignore_else" -eq 0 ]; then
            if [ "$output" -eq 1 ]; then
                output=0
            else
                output=1
            fi
        elif [ "$ret" -eq "$EC_KW_ELIF" ]; then
            output=0
            ignore_else=1
        fi
    done

    compiler.print_error "'if' without matching 'fi'"
    exit 1
}

##############################################################################

compiler.parse_line() {
    # Count parsed lines
    let line_nr=line_nr+1

    if [ -z "$raw" ] && [[ "$line" =~ ^"$EC_COMMENT$EC_PROMPT".* ]]; then
        local raw_line="$line"
        local keyword="$(compiler.get_keyword "$raw_line")"
        local line="$(compiler.get_line "$raw_line")"

        #tmp debug output
        #msg.print "keyword : $keyword"
        #msg.print "line : $line"

        case $keyword in
            include)
                msg.print "Including $line"
                # Keep line_nr in current file and process include
                local tmp_line_nr="$line_nr"
                let ELLIPSIS_LVL=ELLIPSIS_LVL+1
                msg.bold "$line"
                compiler.parse_file "$line"
                let ELLIPSIS_LVL=ELLIPSIS_LVL-1
                line_nr="$tmp_line_nr"
                ;;
            include_raw)
                msg.print "Including $line (raw)"
                compiler.parse_file "$line" "raw"
                ;;
            if)
                local condition="$(compiler.get_condition "$line")"
                compiler.parse_if "$(compiler.eval_condition "$condition")"
                ;;
            else)
                return "$EC_KW_ELSE"
                ;;
            elif)
                if [ "$output" -eq 1 ]; then
                    return "$EC_KW_ELIF"
                else
                    local condition="$(compiler.get_condition "$line")"
                    compiler.parse_if "$(compiler.eval_condition "$condition")"
                    return "$EC_KW_FI"
                fi
                ;;
            fi)
                return "$EC_KW_FI"
                ;;
            raw)
                eval "$line"
                ;;
            write)
                echo "$line" >> "$target"
                ;;
            msg)
                msg.print "$file : $line"
                ;;
            log|log_ok)
                log.ok "$file : $line"
                ;;
            log_warn)
                log.warn "$file : $line"
                ;;
            log_err)
                log.error "$file : $line"
                ;;
            exit)
                exit "$line"
                ;;
            prompt)
                #@TODO
                compiler.print_error "'$keyword' not implemented"
                exit 1
                ;;
            *)
                compiler.print_error "unknown keyword '$keyword'"
                exit 1
                ;;
            esac
    elif [[ "$line" =~ ^"$EC_COMMENT".* ]] ||\
            [[ "$line" =~ ^$ ]]; then
        # Ignore commented and empty lines
        :
    elif [ "$output" -eq 1 ]; then
        echo "$line" >> "$target"
    fi
}

##############################################################################
