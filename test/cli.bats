#!/usr/bin/env bats
##############################################################################

load _helper
load cli

##############################################################################

@test "cli.run without command prints usage" {
    run cli.run
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Usage: ellipsis-__name_l__ <command>" ]
}

@test "cli.run with invalid command prints usage" {
    run cli.run invalid_command
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Usage: ellipsis-__name_l__ <command>" ]
}

@test "cli.run help prints usage" {
    run cli.run help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-__name_l__ <command>" ]
}

@test "cli.run --help prints usage" {
    run cli.run --help
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-__name_l__ <command>" ]
}

@test "cli.run -h prints usage" {
    run cli.run -h
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Usage: ellipsis-__name_l__ <command>" ]
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

##############################################################################
