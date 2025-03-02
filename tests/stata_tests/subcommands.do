capture program drop test_subcommands
program define test_subcommands
    syntax anything [using] [, *]
    tokenize `anything'
    local subcmd = "`1'"

    if ("`subcmd'" == "init") {
    di "init"
    }
    else if ("`subcmd'" == "query") {
    di "query"
    }
    else if ("`subcmd'" == "set") {
    di "set"
    }
    else if ("`subcmd'" == "code") {
    di "code"
    }
    else if ("`subcmd'" == "error") {
    di "error"
    }
    else {
        display as error "Unknown sub command. Use one of:"
        display as error "explain set <parameter> <value>"
        display as error "explain do 'path/to/do-file.do' [rewrite]"
        display as error "explain error [r(errorcode)|errorcode] [, lines(<n>|<n>,<m>) | previous(<n>)] [suggestfix]"
        display as error "explain code [your code snippet] [, lines(<n>|<n>,<m>)]"
        exit 198
    }

test_subcommands query
test_subcommands set
test_subcommands code
test_subcommands error
test_subcommands init
test_subcommands invalid
