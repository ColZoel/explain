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
    version 17.0

    syntax namelist(min=1 max=3) [using] [, rewrite suggestfix lines(string) previous(numlist)]
	
	di "name: `namelist'"



    // ================================================================
    // 	                    INITIALIZATION
    // 	DEFAULTS
    if ("$explain_temperature" == "")       global explain_temperature "0.3"
    if ("$explain_max_tokens" == "")        global explain_max_tokens "150"
	if ("$explain_max_lines" == "")         global explain_maxlines "."
	if ("$explain_model" == "")             global explain_model "."
	if ("$explain_api_config" == "")        global explain_api_config ""
	if ("$explain_dofile" == "")              global explain_dofile "."
    if ("$python_env" == "")                global python_env ""

    if ("$python_env" != "") {
                quietly set python_exec "`python_env'python.exe"
            }

    // test model "huggingface:meta-llama/Llama-3.2-1B"
    global explain_model "huggingface:meta-llama/Llama-3.2-1B"

    // test api config
    global explain_api_config "D:\Collin\explain\ado\explain\pkg\api_config.txt"

	quietly findfile modules.py
    global modules_path "`r(fn)'"

	// -----------------------------------------------------------
	//                    PROGRAM STARTS HERE



    // Determine the mode by the first token.
    tokenize "`namelist'"
	local first_token = "`1'"
    display as text "First token: `first_token'"


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
        local value = "`3'"
		explain_set "`param'" "`value'"
 		exit 0
    }
	
    // ================================================================
    // 2. DO MODE
    //    Usage: explain do using "path/to/do-file.do" [rewrite]
    // ================================================================

    else if ("`first_token'" == "do") {
        syntax namelist(min=1 max=3) [using/] [, rewrite suggestfix lines(string) previous(numlist)]
        // The command accepts a file name and an optional "rewrite" flag.
        // test file: "D:\Collin\female_entr\Industry_Betas\Industry_Betas\construct_industry_betas.do"

        global explain_dofile "D:\Collin\female_entr\Industry_Betas\Industry_Betas\construct_industry_betas.do"

        if "`using'" == "" {

            if ("$explain_dofile" == ".") {
                display as error "No do-file set and no file specified. Use: 'explain set dofile \path/to/dofile.do\'"
                exit 198
            }

            local file "$explain_dofile"
        }
        else {
            local file "`using'"
        }

        #delimit ;
        python script $modules_path, args("do"
        "`file'"
        "$explain_model"
        "$explain_api_config"
        "`rewrite'"
        "$explain_max_tokens"
        "$explain_temperature")
        ;
        #delimit cr
        exit 0
	}



// ================================================================
// 3. CODE MODE
//    Usage:
//       (a) explain code "your code snippet"
//       (b) explain code, lines(10)         (extracts line 10)
//       (c) explain code, lines(10-20) or lines(10,20)
//          (extracts that range from the file set previously)
// ================================================================
else if ("`first_token'" == "code") {
// Accept an optional code snippet and/or a lines() option.

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