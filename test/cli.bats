#!/usr/bin/env bats
##############################################################################

load _helper
load cli

##############################################################################

@test "cli.run without command prints usage" {
    run cli.run
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <input_file> <output_file>" ]
}

@test "cli.run help prints usage" {
    run cli.run help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <input_file> <output_file>" ]
}

@test "cli.run --help prints usage" {
    run cli.run --help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <input_file> <output_file>" ]
}

@test "cli.run -h prints usage" {
    run cli.run -h
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-$ELLIPSIS_XNAME_L <input_file> <output_file>" ]
}

@test "cli.run version prints version" {
    run cli.run version
    [ "$status" -eq 0 ]
    [ $(expr "$output" : "v[0-9][0-9.]*") -ne 0 ]
}

@test "cli.run --version prints version" {
    run cli.run --version
    [ "$status" -eq 0 ]
    [ $(expr "$output" : "v[0-9][0-9.]*") -ne 0 ]
}

@test "cli.run -v prints version" {
    run cli.run -v
    [ "$status" -eq 0 ]
    [ $(expr "$output" : "v[0-9][0-9.]*") -ne 0 ]
}

@test "cli.run fails if Ellipsis version is not sufficient" {
    ELLIPSIS_VERSION="1.4.7"\
    run cli.run
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "[FAIL] Ellipsis-$ELLIPSIS_XNAME v$ELLIPSIS_XVERSION needs at least Ellipsis v$ELLIPSIS_VERSION_DEP" ]
    [ "${lines[1]}" = "Please update Ellipsis!" ]
}

##############################################################################
