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

    # Flags
    local output=true

    local line_nr=0
    while read line; do
        let line_nr=line_nr+1
        if [[ "$line" =~ ^"$EC_COMMENT$EC_PROMPT".* ]]; then
            local keyword="$(compiler.get_keyword "$line")"
            msg.print "keyword : $keyword"
            case $keyword in
                include)
                    local inc_file="$(cut -d ' ' -f3 <<< "$line")"
                    compiler.parse_file "$inc_file"
                    ;;
                include_raw)
                    local inc_file="$(cut -d ' ' -f3 <<< "$line")"
                    compiler.include_raw "$inc_file"
                    ;;
                *)
                    msg.print "Syntax error in $file at line nr $line_nr:"
                    msg.print "    '$line'"
                    ;;
                esac
        elif [[ "$line" =~ ^"$EC_COMMENT".* ]] ||\
             [[ "$line" =~ ^$ ]]; then
            # Ignore commented and empty lines
            :
        elif [ "$output" ]; then
            echo "$line" >> "$EC_OUTPUT"
        fi
    done < "$file"
}

##############################################################################

compiler.include_raw() {
    cat "$1" >> "$EC_OUTPUT"
}

##############################################################################
