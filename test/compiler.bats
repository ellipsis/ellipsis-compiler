#!/usr/bin/env bats
##############################################################################

load _helper
load compiler

##############################################################################

setup() {
    EC_TMP="/tmp/ellipsis-compiler-test"
    mkdir -p "$EC_TMP"
}

teardown() {
    rm -rf "$EC_TMP"
}

##############################################################################

@test "compiler.cleanup cleans up after compile" {
    local target="$EC_TMP/testfile"
    touch "$target"
    IFS='test'
    run compiler.cleanup
    [ "$status" -eq 0 ]
    [ ! "$IFS" = $'\n' ]
    [ ! -f "$target" ]
}

@test "compiler.cleanup keeps buffer if \$EC_KEEP_BUF is set" {
    local target="$EC_TMP/testfile"
    touch "$target"
    EC_KEEP_BUF=1\
        run compiler.cleanup
    [ "$status" -eq 0 ]
    [ -f "$target" ]
}

@test "compiler.print_error prints error" {
    local file="test/file-name"
    local file_name="file-name"
    local line_nr=1
    local line="the troubled line"
    run compiler.print_error "Error message"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Syntax error in 'file-name' at line nr 1:" ]
    [ "${lines[1]}" = "| test/file-name:1" ]
    [ "${lines[2]}" = "|    'the troubled line'" ]
    [ "${lines[3]}" = "> Error message" ]
}

@test "compiler.print_error prints error (raw_line)" {
    local file="test/file-name"
    local file_name="file-name"
    local line_nr=1
    local raw_line="the troubled line"
    run compiler.print_error "Error message"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Syntax error in 'file-name' at line nr 1:" ]
    [ "${lines[1]}" = "| test/file-name:1" ]
    [ "${lines[2]}" = "|    'the troubled line'" ]
    [ "${lines[3]}" = "> Error message" ]
}

@test "compiler.get_keyword gets keyword" {
    run compiler.get_keyword "comment key_word other stuff here"
    [ "$status" -eq 0 ]
    [ "$output" = "key_word" ]
}

@test "compiler.get_line gets line (strips keyword)" {
    run compiler.get_line "comment key_word other stuff here"
    [ "$status" -eq 0 ]
    [ "$output" = "other stuff here" ]
}

@test "compiler.parse_file fails on a non existing file" {
    run compiler.parse_file "$EC_TMP/doesnotexist.econf"
    [ "$status" -eq 1 ]
    [ "${lines[3]}" = "> File not found : '/tmp/ellipsis-compiler-test/doesnotexist.econf'" ]
}

@test "compiler.compile compiles a file" {
    skip "No test implementation"
}

@test "compiler.parse_file parses a file" {
    skip "No test implementation"
}

@test "compiler.parse_file parses a raw file" {
    skip "No test implementation"
}

@test "compiler.get_condition gets if/elif condition" {
    run compiler.get_condition "#_> if [ if ]"
    [ "$status" -eq 0 ]
    [ "$output" = "[ if ]" ]

    run compiler.get_condition "#_> if if"
    [ "$status" -eq 0 ]
    [ "$output" = "if" ]

    run compiler.get_condition "#_> elif [ elif ]"
    [ "$status" -eq 0 ]
    [ "$output" = "[ elif ]" ]

    run compiler.get_condition "#_> if [ then ]; then"
    [ "$status" -eq 0 ]
    [ "$output" = "[ then ]" ]
}

@test "compiler.parse_if parses if/elif" {
    skip "No test implementation"
}

@test "compiler.parse_line parses a line" {
    skip "No test implementation"
}

# Test by compiling a file with known output
@test "compiler input-output test 1 (empty file)" {
    EC_NOHEADER=true \
        run compiler.compile "$TESTS_DIR/fixtures/input1.econf" "$EC_TMP/output1"
    [ "$status" -eq 0 ]
    [ "$(diff "$TESTS_DIR/fixtures/output1" "$EC_TMP/output1")" = "" ]
}

@test "compiler input-output test 2 (if/elif/else statements)" {
    EC_NOHEADER=true \
        run compiler.compile "$TESTS_DIR/fixtures/input2.econf" "$EC_TMP/output2"
    [ "$status" -eq 0 ]
    [ "$(diff "$TESTS_DIR/fixtures/output2" "$EC_TMP/output2")" = "" ]
}

@test "compiler input-output test 3 (include/include_raw)" {
    cp "$TESTS_DIR/fixtures/input3.p3.econf" "$EC_TMP"
    EC_NOHEADER=true \
        run compiler.compile "$TESTS_DIR/fixtures/input3.econf" "$EC_TMP/output3"
    [ "$status" -eq 0 ]
    [ "$(diff "$TESTS_DIR/fixtures/output3" "$EC_TMP/output3")" = "" ]
}

@test "compiler input-output test 4 (raw)" {
    EC_NOHEADER=true \
        run compiler.compile "$TESTS_DIR/fixtures/input4.econf" "$EC_TMP/output4"
    [ "$status" -eq 0 ]
    [ "$(diff "$TESTS_DIR/fixtures/output4" "$EC_TMP/output4")" = "" ]
}

@test "compiler input-output test 5 (write)" {
    EC_NOHEADER=true \
        run compiler.compile "$TESTS_DIR/fixtures/input5.econf" "$EC_TMP/output5"
    [ "$status" -eq 0 ]
    [ "$(diff "$TESTS_DIR/fixtures/output5" "$EC_TMP/output5")" = "" ]
}

@test "compiler input-output test 6 (compiler control)" {
    EC_NOHEADER=true \
        run compiler.compile "$TESTS_DIR/fixtures/input6.econf" "$EC_TMP/output6"
    [ "$status" -eq 0 ]
    [ "$(diff "$TESTS_DIR/fixtures/output6" "$EC_TMP/output6")" = "" ]
}

##############################################################################
