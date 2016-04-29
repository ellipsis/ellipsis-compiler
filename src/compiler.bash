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
    msg.print "Syntax error in $file at line nr $line_nr:"
    msg.print "    '$line'"
}

##############################################################################

compiler.get_keyword() {
    cut -d ' ' -f2 <<< "$1"
}

##############################################################################

compiler.compile() {
    local file="$1"
    if [ -z "$file" ]; then
        msg.print "Please provide an input file"
        exit 1
    fi

    local target="${2:-${file}.out}"
    msg.bold "Compiling $file"
    echo "$EC_COMMENT Compiled by Ellipsis-Compiler on $(date)" > "$target"
    compiler.parse_file "$file"
}

##############################################################################

compiler.parse_file() {
    local file="$1"

    # Reset line number before parsing file
    line_nr=0

    # Parse file
    while read line; do
        local output=1
        compiler.parse_line "$line"
        if [ "$?" -eq 1 -o "$?" -eq 2 ]; then
            compiler.print_error
            msg.print "    'fi' without matching 'if'"
            exit 1
        fi
    done < "$file"
}

##############################################################################

#@TODO optionaly strip comments (toglable for all output)
compiler.include_raw() {
    cat "$1" >> "$target"
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

    msg.print "Syntax error in $file, missing 'fi'"
    exit 1
}

##############################################################################

compiler.parse_line() {
    # Count parsed lines
    let line_nr=line_nr+1

    if [[ "$line" =~ ^"$EC_COMMENT$EC_PROMPT".* ]]; then
        local keyword="$(compiler.get_keyword "$line")"
        msg.print "keyword : $keyword"
        case $keyword in
            include)
                # Get file name
                local inc_file="$(cut -d ' ' -f3 <<< "$line")"

                # Keep line_nr in current file and process include
                local tmp_line_nr="$line_nr"
                compiler.parse_file "$inc_file"
                line_nr="$tmp_line_nr"
                ;;
            include_raw)
                # Get file name
                local inc_file="$(cut -d ' ' -f3 <<< "$line")"

                compiler.include_raw "$inc_file"
                ;;
            def_var)
                local var="$(compiler.get_var "$line")"
                eval "$var"
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
            export)
                #@TODO
                msg.print "NOT IMPLEMENTED"
                compiler.print_error
                ;;
            exec)
                msg.print "NOT IMPLEMENTED"
                compiler.print_error
                ;;
            print_out)
                msg.print "NOT IMPLEMENTED"
                compiler.print_error
                ;;
            print_err)
                msg.print "NOT IMPLEMENTED"
                compiler.print_error
                ;;
            log)
                msg.print "NOT IMPLEMENTED"
                compiler.print_error
                ;;
            prompt)
                msg.print "NOT IMPLEMENTED"
                compiler.print_error
                ;;
            *)
                compiler.print_error
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
