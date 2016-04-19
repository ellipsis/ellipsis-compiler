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
EC_OUTPUT="tmp.file"

##############################################################################

compiler.print_error() {
    msg.print "Syntax error in $file at line nr $line_nr:"
    msg.print "    '$line'"
}

##############################################################################

compiler.get_keyword() {
    local line="$1"
    cut -d ' ' -f2 <<< "$line"
}

##############################################################################

compiler.compile() {
    for file in $@; do
        msg.bold "Compiling $file"
        echo "$EC_COMMENT Compiled by Ellipsis-Compiler on $(date)" > "$EC_OUTPUT"
        compiler.parse_file "$file"
    done
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

compiler.parse_if() {
    output="$1"

    while read line; do
        compiler.parse_line "$line"
        local ret="$?"

        if [ "$ret" -eq 1 ]; then
            return
        elif [ "$ret" -eq 2 ]; then
            if [ "$output" -eq 1 ]; then
                output=0
            else
                output=1
            fi
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
            if)
                compiler.parse_if 1
                ;;
            else)
                return 2
                ;;
            fi)
                return 1
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
        echo "$line" >> "$EC_OUTPUT"
    fi
}

##############################################################################

compiler.include_raw() {
    cat "$1" >> "$EC_OUTPUT"
}

##############################################################################
