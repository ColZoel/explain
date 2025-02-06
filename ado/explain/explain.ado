/*  version 1.0.2  -- Explain Stata code/errors/do-files using an LLM with advanced options

This file attempts to better integrate AI (specifically generative text) into \
Stata. Rather than an "autocomplete" feature like that of GitHub Copilot, 
this is essentially an integration of the chatbot itself into the Stata console. 

The chatbot does not at anypoint see the data or associated metadata (size, 
variable names, etc.), but only reads strings of errors or code either inputted
by the user or read from the do file. 

As of now, only API access to any hosted LLM is supported. Local LLM integration
is a little more involved, but if you privately host your model on a server it will
work here as well. 


*** Dependencies:
	- Python 3.xx
	- Stata 16+

*** other 
Additionally, network access is required to access 


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
    if ("$explain_dofile" == "")            global explain_dofile "."
    if ("$explain_max_lines" == "")         global explain_maxlines "."


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

	quietly findfile modules.py
    global modules_path "`r(fn)'"

	// -----------------------------------------------------------
	//                    PROGRAM STARTS HERE



    // Determine the mode by the first token.

    syntax anything [, *]
    tokenize `anything'
	local first_token = "`1'"
    //display as text "First token: `first_token'"


    // ================================================================
    // 0. INIT MODE -- for initializing the Python environment upon import failure
	//	 initialize the Python environment, install dependencies to current environment
	//  Usage: explain init
	// ================================================================

    if ("`first_token'" == "init") {
        python script $modules_path, args("init")
        exit 0
    }


	// ================================================================
    // 0. QUERY MODE
	//	  Print LLM and function parameters. 
    //    Usage: explain query 
	//			for full list 
	
    //    Usage: explain query <parameter>		
	//			for the value of <parameter>
	// ================================================================	
	
	else if ("`first_token'" == "query") {
		explain_query "`2'"
		exit 0
	}
	
	
	// ================================================================
    // 1. SET MODE
	//	  Set LLM and function parameters. 
    //    Usage: explain set <parameter> <value>
	//	  	
	//	  Parameters include:
	//	  - temperature
	//	  - max_tokens
	//	  - max_lines
	//	  - api endpoint
	//	  - secret containing API key, if necessary
    // ================================================================
    
	else if "`first_token'" == "set" {

        local param = "`2'"
		local path = "`3'"
		explain_set "`param'" "`path'"
 		exit 0
    }
	
    // ================================================================
    // 2. DO MODE
    //    Usage: explain do using "path/to/do-file.do" [rewrite]
    // ================================================================

    else if ("`first_token'" == "do") {
        syntax namelist(min=1 max=3) [using/] [, rewrite suggestfix detail verbose]

        local options = "`rewrite' `suggestfix' `detail' `verbose'"

        if "`using'" == "" {

            if ("$explain_dofile" == "."| "$explain_dofile" == "") {
                display as error "No do-file set and no file specified. Use: 'explain set dofile path/to/dofile.do'"
                exit 198
            }

            local file "$explain_dofile"
        }
        else {
            local file "`using'"
        }


        #delimit ;
        python script $modules_path, args(
        "do"
        "`input'"
        "$explain_model"
        "$explain_api_config"
        "`file'"
        "`options'"
        "$explain_max_tokens"
        "$explain_temperature"
        "$explain_max_p"
        "$explain_top_k"
        "$explain_frequency_penalty"
        "$explain_presence_penalty"
        "$explain_stop_sequence"
        )
        ;
        #delimit cr
        exit 0
	}



    // ================================================================
    // 3. CODE MODE
    //    Usage:
    //       (a) explain code "your code snippet"
    //       (b) explain code, lines(10)         (extracts line 10)
    //       (c) explain code, lines(10-20)
    //          (extracts that range from the file set previously)
    // ================================================================
    else if ("`first_token'" == "code") {
    di "`2'"
    syntax anything [using/] [ , rewrite suggestfix detail lines(string) verbose]

    tokenize `anything'

    local snippet = "`2'"

    // Case 1: Code snippet not provided, line ID not provided
    if ("`snippet'" == "" & "`lines'" == "") {
        display as error "No code or line numbers provided. Use: 'explain code \"your code snippet\"'"
        exit 198
    }

    // Case 2: Code snippet provided, (line ID is irrelevant)
    else if ("`snippet'" != "") {

        if ("`using'" != "") {
            display in green "(using is not necessary for code snippets. Ignoring.)"
            }

    }

    // case 3: Line ID provided
    else {

         // prioritize using file
         if ("`using'" != "") {
            local file = "`using'"
            }

         else if ("$explain_dofile" != "") {
            local file = "$explain_dofile"
            }

         else {
            display as error "No do-file set."
            exit 198
         }

        // validate string ranges from lines

        if (strpos("`lines'", "-") == 0 & missing(real("`lines'"))) {
            display as error "Invalid line range specified."
            exit 198
        }
    }

    local options = "`rewrite' `suggestfix' `detail' `verbose' lines:`lines'"

    #delimit ;
    python script $modules_path, args(
        "code"
        "`snippet'"
        "$explain_model"
        "$explain_api_config"
        "`file'"
        "`options'"
        "$explain_max_tokens"
        "$explain_temperature"
        "$explain_max_p"
        "$explain_top_k"
        "$explain_frequency_penalty"
        "$explain_presence_penalty"
        "$explain_stop_sequence"
        )
        ;
    #delimit cr
    exit 0
    }



    // ================================================================
    // 4. ERROR MODE
    //    Usage options:
    //      (a) explain error
    //          If no explicit error code is given, the program checks:
    //              - If global last_error_msg is empty then it uses _rc (even if _rc==0)
    //          The user may supply context options:
    //              - lines(10)         -> use line 10
    //              - lines(10,20)      -> use lines 10 to 20
    //              - previous(10)      -> use the 10 lines preceding the error
    //
    //      (b) explain error r(198)  or  explain error 198
    //         - Explains that specific error code.
    // After processing, global last_error_msg is reset.
    // ================================================================


    else if ("`first_token'" == "error") {

        exit 0
    }



// ================================================================

     else {
        display as error "Unknown sub command. Use one of:"
        display as error "explain set <parameter> <value>"
        display as error "explain do 'path/to/do-file.do' [rewrite]"
        display as error "explain error [r(errorcode)|errorcode] [, lines(<n>|<n>,<m>) | previous(<n>)] [suggestfix]"
        display as error "explain code [your code snippet] [, lines(<n>|<n>,<m>)]"
        exit 198
    }

end