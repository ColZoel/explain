/*  version 1.0.2  -- Explain Stata code/errors/do-files using an LLM with advanced options

This file attempts to better integrate AI (specifically generative text) into \
Stata. Rather than an "autocomplete" feature like that of GitHub Copilot, 
this is essentially an integration of the chatbot itself into the Stata console. 

The chatbot does not at anypoint see the data or associated metadata (size, 
variable names, etc.), but only reads strings of errors or code either inputted
by the user or read from the do file. 


*** Dependencies:
	- Python 3.xx
	- Stata 16+

*** other 
Additionally, network access is required to access hosted models.
Ollama is necessary to access local models.

Author: Collin Zoeller
		Github: @colzoel
		Carnegie Mellon University


This .ado file was partially created using generative text (gpt-03-mini-high). 


*/


capture program drop explain
program define explain
    version 18.0

    // ================================================================
    // 	                    INITIALIZATION
    // 	                       DEFAULTS
    // -----------------------------------------------------------
    //                          STATA
    if ("$python_env" == "")                global python_env ""

    // -----------------------------------------------------------
    //                          API
    if ("$explain_api_config" == "")        global explain_api_config ""
    if ("$explain_model" == "")             global explain_model "."


    // -----------------------------------------------------------
    //                          MODEL
    ***  While these are all empty, having them here helps keep track of what we have

    if ("$explain_system_role_msg" == "")   global explain_system_role_msg
    if ("$explain_user_role_msg" == "")     global explain_user_role_msg


    if ("$explain_temperature" == "")       global explain_temperature
    if ("$explain_max_tokens" == "")        global explain_max_tokens
	if ("$explain_max_p" == "")             global explain_max_p
	if ("$explain_top_k" == "")             global explain_top_k
	if ("$explain_frequency_penalty" == "") global explain_frequency_penalty
	if ("$explain_presence_penalty" == "")  global explain_presence_penalty
	if ("$explain_stop_sequence" == "")     global explain_stop_sequence

    // -----------------------------------------------------------

	quietly findfile explain_modules.py
    global modules_path "`r(fn)'"

	// -----------------------------------------------------------
	//                    PROGRAM STARTS HERE



    // Determine the mode by the first token.

    syntax anything [using] [, *]
    tokenize `anything'
	local subcmd = "`1'"

    // ================================================================
    // 0. INIT MODE -- for initializing the Python environment upon import failure
	//	 initialize the Python environment, install dependencies to current environment
	//  Usage: explain init
	// ================================================================

    if ("`subcmd'" == "init") {
        python script $modules_path, args("init")
        exit 0
    }


	// ================================================================
    // 1. QUERY MODE
	//	  Print LLM and function parameters. 
    //    Usage: explain query 
	//			for full list 
	
    //    Usage: explain query <parameter>		
	//			for the value of <parameter>
	// ================================================================	
	
	else if ("`subcmd'" == "query") {
		explain_query "`2'"
		exit 0
	}
	
	
	// ================================================================
    // 2. SET MODE
	//	  Set LLM and function parameters. 
    //    Usage: explain set <parameter> <value>
    // ================================================================
    
	else if "`subcmd'" == "set" {

        local param = "`2'"
		local path = "`3'"
		explain_set "`param'" "`path'"
 		exit 0
    }
	
    // ================================================================
    // 3. DO MODE
    //    Usage: explain do using "path/to/do-file.do" [, rewrite suggestfix lines(integer[-integer]) verbose]
    // ================================================================

    else if ("`subcmd'" == "do") {
        syntax anything using/ [, rewrite suggestfix lines(string) verbose]

        if "`lines'" != "" {

        // validate string ranges from lines
        if (strpos("`lines'", "-") == 0 & missing(real("`lines'"))) {
            display as error "Invalid line range specified."
            exit 198
            }
        }
	}



    // ================================================================
    // 4. CODE MODE
    //    Usage:
    //       (a) explain code "your code snippet"
    // ================================================================
    else if ("`subcmd'" == "code") {
        syntax anything [ , rewrite suggestfix verbose]

        tokenize `anything'

        local input = "`2'"
        di "snippet: `input'"
        // Code snippet not provided
        if ("`input'" == "") {
            display as error "No code provided. Use: 'explain code \"your code snippet\"'"
            exit 198
        }

    }



    // ================================================================
    // 5. ERROR MODE
    //    Usage options:
    //    (a) explain error r(#)
    //         - Explains that specific error code generally.
    //
    //    (b) explain error "r(#)" ["snippet"] [using] [,  suggestfix capture lines(integer[-integer]) verbose]
    //          - If error code provided, it explains that specific error code
    //
    // ================================================================

    else if ("`subcmd'" == "error") {

        syntax anything [using/] [, suggestfix capture lines(string) verbose]

        local errorcode = _rc


        tokenize `anything'
        // input can be either code or error code
        local input = "`2'"
        di "input: `input'"
        if ("`input'" == "" & "`using'" == "") {
            display as error "No error code or code snippet provided. Use: 'explain error r(#)' or 'explain error \"your code snippet\"'"
            exit 198
        }

        // Error code
        if (substr("`input'",1,2)=="r(" & substr("`input'",-1,1)==")") {

            local errorcode = substr("`input'",3,strlen("`input'")-3)

            quietly confirm number `errorcode'
                if (_rc) {
                    display as error "Invalid error code."
                    exit 198
                }
            if "`capture'" != "" & "`using'" == ""{
                display as error "Nothing to capture."
                }
            local input = "error: `errorcode'"
            }



        // Code snippet
        else if "`input'" != "" {
            if "`using'" != "" {
                display as error "using not available for code snippets."
            }
            if "`lines'" != "" {
                display as error "lines not available for code snippets."
            }

            if "`capture'" != "" {
                capture noisily `input'
                local errorcode = _rc

                local input = "error: `errorcode' code: `input'"
            }
        }


        // Read do-file (or lines) and capture the error
        else if "`using'" != "" {

            local first_line = .
            local last_line = .

            if "`lines'" !=""{
                local dash = strpos("`lines'", "-")
                if `dash' > 0 & `dash' !="" {
                    // If there is a hyphen, extract start and end numbers
                    local first_line = substr("`lines'", 1, `dash' - 1)
                    local last_line = substr("`lines'", `dash' + 1, .)
                }
                else {
                    // Single line case
                    local first_line = "`lines'"
                    local last_line = "`lines'"
                }


                // Convert strings to numbers
                local first_line = real("`first_line'")
                local last_line = real("`last_line'")

                if missing(`first_line') | missing(`last_line') {
                    di as error "Invalid line numbers."
                    exit
                }

                // Ensure correct ordering
                if `first_line' > `last_line' {
                    di as error "Invalid range: First number must be smaller or equal to the second."
                    exit
                }
            }

            // Open and read file
            file open myfile using "`using'", read
            file read myfile line
            local i = 1

            local extracted_lines ""  // Initialize empty macro

            // Loop through lines and store only those in the range
            while r(eof) == 0 {
                if "`lines'" == "" | (`i' >= `first_line' & `i' <= `last_line') {
                    if "`extracted_lines'" == "" {
                        local extracted_lines "`line'"
                    }
                    else {
                        local extracted_lines "`extracted_lines' \\n `line'"
                    }
                    if "`capture'" != "" {
                        capture noisily {
                        qui: `line'
                        }
                        if _rc != 0 {
                            local errorcode = _rc
                            break
                        }
                    }

                }
                local ++i
                file read myfile line
            }

            file close myfile

        local input = "error: r(`errorcode') \\n do-file: `extracted_lines'"
        }


        else{
            display as error "No error code or code snippet provided. Use: 'explain error r(#)' or 'explain error \"your code snippet\"'"
            exit 198
            }
    }


// --------------  EXIT CASE -- UNKNOWN COMMAND --------------
// -----------------------------------------------------------

     else {
        display as error "Unknown sub command. Use one of:"
        display as error "explain set <parameter> <value>"
        display as error "explain do 'path/to/do-file.do' [rewrite]"
        display as error "explain error [r(errorcode)|errorcode] [, lines(<n>|<n>,<m>) | previous(<n>)] [suggestfix]"
        display as error "explain code [your code snippet] [, lines(<n>|<n>,<m>)]"
        exit 198
    }


//    RUN PYTHON SCRIPT
// ================================================================

   local options = "`rewrite' `suggestfix' `capture' `verbose' lines:`lines'"

   #delimit ;
     python script $modules_path, args(
    "`subcmd'"
    "`input'"
    "$explain_model"
    "$explain_api_config"
    "`using'"
    "`options'"
    "$explain_max_p"
    "$explain_top_k"
    "$explain_max_tokens"
    "$explain_temperature"
    "$explain_frequency_penalty"
    "$explain_presence_penalty"
    "$explain_stop_sequence"
    )
    ;
#delimit cr





end