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
    version 16.0

	
	run "D:\Collin\explain\query.ado" // hardcoded: remember to remove!
	run "D:\Collin\explain\set.ado"
	

    // -----------------------------------------------------------
    // 	
    // 	DEFAULTS

    if ("$explain_temperature" == "") global explain_temperature "0.3"
    if ("$explain_max_tokens" == "") global explain_max_tokens "150"
	if ("$explain_max_lines" == "") global explain_maxlines "."
	if ("$explain_api" == "") global explain_api "."
	if ("$explain_secret" == "") global explain_secret "."
	if ("$explain_file" == "") global explain_file "."
    // -----------------------------------------------------------
	

	
    // Determine the mode by the first token.
    
	tokenize "`0'"
	local first_token = "`1'"

	
	// ================================================================
    // 0. QUERY MODE
	//	  Print LLM and function parameters. 
    //    Usage: explain query 
	//			for full list 
	
    //    Usage: explain query <parameter>		
	//			for the value of <parameter>
	// ================================================================	
	
	if ("`first_token'" == "query") {

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
 		
    }
	
	
	

//     // ================================================================
//     // 2. DO MODE
//     //    Usage: explain do "path/to/do-file.do" [rewrite]
//     // ================================================================
    else if ("`first_token'" == "do") {
        // The command accepts a file name and an optional "rewrite" flag.
        syntax anything(name=filename) [rewrite]
        local file_to_explain = "`filename'"
       
		
		
		
		
python:
import sys
dofile = r"""`file_to_explain'"""
try:
    with open(dofile, "r") as f:
        file_lines = f.readlines()
except Exception as e:
    print("Error reading do-file: " + str(e))
    sys.exit(1)
# If the file is too large, print a message and exit.
threshold = 200
if len(file_lines) > threshold:
    print("do-file too large. Consider checking smaller chunks instead.")
    sys.exit(0)
file_content = "".join(file_lines)
rewrite_flag = r"""`rewrite'"""
if rewrite_flag.strip():
    prompt = f"Please rewrite the following Stata do-file for improved optimization and clarity:\n{file_content}"
else:
    prompt = f"Please explain what the following Stata do-file achieves:\n{file_content}"
try:
    temperature = float("$explain_temperature") if "$explain_temperature" != "" else 0.3
except Exception:
    temperature = 0.3
try:
    max_tokens = int("$explain_max_tokens") if "$explain_max_tokens" != "" else 250
except Exception:
    max_tokens = 250
api_key = "$explain_secret" if "$explain_secret" != "" else "YOUR_DEFAULT_API_KEY"
import openai
openai.api_key = api_key
try:
    response = openai.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
    explanation = response.choices[0].text.strip()
    print(explanation)
except Exception as e:
    print("Error calling OpenAI API: " + str(e))
    sys.exit(1)
        end
        exit 0
    }





//     // ================================================================
//     // 3. CODE MODE
//     //    Usage:
//     //       a) explain code "your code snippet"
//     //       b) explain code, lines(10)         (extracts line 10)
//     //       c) explain code, lines(10-20) or lines(10,20)
//     //          (extracts that range from the file set previously)
//     // ================================================================
//     else if ("`first_token'" == "code") {
//         // Accept an optional code snippet and/or a lines() option.
//         syntax [anything(name=code_text)] [ , lines(string) ]
//         if ("`lines'" != "") {
//             if ("$explain_file" == "") {
//                 display as error "No do-file set. Use: explain set file \"path/to/dofile.do\""
//                 exit 198
//             }
//             local line_spec = "`lines'"
//             local start_line = ""
//             local end_line = ""
//             if (strpos("`line_spec'", ",") > 0) {
//                 local start_line : word 1 of "`line_spec'", ","
//                 local end_line : word 2 of "`line_spec'", ","
//             }
//             else if (strpos("`line_spec'", "-") > 0) {
//                 local start_line : word 1 of "`line_spec'", "-"
//                 local end_line : word 2 of "`line_spec'", "-"
//             }
//             else {
//                 local start_line = "`line_spec'"
//                 local end_line = "`line_spec'"
//             }
//             python:
// import sys
// dofile = r"""$explain_file"""
// try:
//     with open(dofile, "r") as f:
//         file_lines = f.readlines()
// except Exception as e:
//     print("Error reading file: " + str(e))
//     sys.exit(1)
// try:
//     start_line = int(r"""`start_line'""")
//     end_line = int(r"""`end_line'""")
// except Exception as e:
//     print("Error converting line numbers: " + str(e))
//     sys.exit(1)
// if start_line < 1 or end_line > len(file_lines) or start_line > end_line:
//     print("Invalid line range specified.")
//     sys.exit(1)
// extracted_code = "".join(file_lines[start_line-1:end_line])
// print("Extracted code (lines {}-{}):".format(start_line, end_line))
// print(extracted_code)
// prompt = f"Please explain what the following Stata code (from lines {start_line} to {end_line} of {dofile}) achieves:\n{extracted_code}"
// try:
//     temperature = float("$explain_temperature") if "$explain_temperature" != "" else 0.3
// except Exception:
//     temperature = 0.3
// try:
//     max_tokens = int("$explain_max_tokens") if "$explain_max_tokens" != "" else 250
// except Exception:
//     max_tokens = 250
// api_key = "$explain_secret" if "$explain_secret" != "" else "YOUR_DEFAULT_API_KEY"
// import openai
// openai.api_key = api_key
// try:
//     response = openai.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
//     explanation = response.choices[0].text.strip()
//     print("Explanation:")
//     print(explanation)
// except Exception as e:
//     print("Error calling OpenAI API: " + str(e))
//     sys.exit(1)
//             end
//             exit 0
//         }
//         else {
//             if ("`code_text'" == "") {
//                 display as error "No code snippet provided."
//                 exit 198
//             }
//             python:
// import sys
// import openai
// code_snippet = r"""`code_text'"""
// prompt = f"Please explain the following Stata code:\n{code_snippet}"
// try:
//     temperature = float("$explain_temperature") if "$explain_temperature" != "" else 0.3
// except Exception:
//     temperature = 0.3
// try:
//     max_tokens = int("$explain_max_tokens") if "$explain_max_tokens" != "" else 250
// except Exception:
//     max_tokens = 250
// api_key = "$explain_secret" if "$explain_secret" != "" else "YOUR_DEFAULT_API_KEY"
// openai.api_key = api_key
// try:
//     response = openai.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
//     explanation = response.choices[0].text.strip()
//     print(explanation)
// except Exception as e:
//     print("Error calling OpenAI API: " + str(e))
//     sys.exit(1)
//             end
//             exit 0
//         }
//     }
//



//     // ================================================================
//     // 4. ERROR MODE
//     //    Usage options:
//     //      a) explain error  
//     //         – If no explicit error code is given, the program checks:
//     //              • If global last_error_msg is empty then it uses _rc (even if _rc==0)
//     //         – The user may supply context options:
//     //              • lines(10)         -> use line 10
//     //              • lines(10,20)      -> use lines 10 to 20
//     //              • previous(10)      -> use the 10 lines preceding the error
//     //
//     //      b) explain error r(198)  or  explain error 198  
//     //         – Explains that specific error code.
//     // After processing, global last_error_msg is reset.
//     // ================================================================
//     else if ("`first_token'" == "error") {
//         // Check if a second token is provided (explicit error code).
//         local token2 : word 2 of "`0'"
//         if ("`token2'" != "" & substr("`token2'",1,1) != ",") {
//             local errorcode = "`token2'"
//             if (substr("`errorcode'",1,2)=="r(" & substr("`errorcode'",-1,1)==")") {
//                 local errorcode = substr("`errorcode'",3,strlen("`errorcode'")-3)
//             }
//             quietly confirm number `errorcode'
//             if (_rc) {
//                 display as error "Invalid error code."
//                 exit 198
//             }
//             python:
// import sys
// import openai
// error_code = "`errorcode'"
// prompt = f"I encountered the following Stata error code: r({error_code}).\nPlease explain what this error code means and suggest potential solutions."
// try:
//     temperature = float("$explain_temperature") if "$explain_temperature" != "" else 0.3
// except Exception:
//     temperature = 0.3
// try:
//     max_tokens = int("$explain_max_tokens") if "$explain_max_tokens" != "" else 250
// except Exception:
//     max_tokens = 250
// api_key = "$explain_secret" if "$explain_secret" != "" else "YOUR_DEFAULT_API_KEY"
// import openai
// openai.api_key = api_key
// try:
//     response = openai.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
//     explanation = response.choices[0].text.strip()
//     print(explanation)
// except Exception as e:
//     print("Error calling OpenAI API: " + str(e))
//     sys.exit(1)
//             end
//             global last_error_msg ""
//             exit 0
//         }
//         else {
//             // No explicit error code was provided.
//             syntax , [lines(string)] [previous(integer)] [suggestfix]
//             if ("$last_error_msg" == "") {
//                 local error_code = c(rc)
//                 local error_message = "Stata error code: " + "`error_code'"
//             }
//             else {
//                 local error_message = "$last_error_msg"
//             }
//             // Determine the context extraction method.
//             if ("`previous'" != "") {
//                 if ("$explain_file" == "") {
//                     display as error "No do-file set. Use: explain set file \"path/to/dofile.do\""
//                     exit 198
//                 }
//                 python:
// import sys
// dofile = r"""$explain_file"""
// try:
//     with open(dofile, "r") as f:
//         file_lines = f.readlines()
// except Exception as e:
//     print("Error reading file: " + str(e))
//     sys.exit(1)
// prev_num_str = r"""`previous'"""
// try:
//     prev_num = int(prev_num_str)
// except Exception as e:
//     print("Error converting previous parameter: " + str(e))
//     sys.exit(1)
// error_line_str = r"""$last_error_line"""
// if error_line_str.strip() == "":
//     error_line = len(file_lines)
// else:
//     try:
//         error_line = int(error_line_str)
//     except Exception:
//         error_line = len(file_lines)
// start_line = max(0, error_line - prev_num - 1)
// context_lines = "".join(file_lines[start_line:error_line-1])
// print("Extracted previous lines (lines {} to {}):".format(start_line+1, error_line-1))
// print(context_lines)
// prompt = f"I encountered an error in my Stata code.\nError message:\n{r"""`error_message'"""}\nHere are the {prev_num} lines preceding the error (from {dofile}):\n{context_lines}"
// suggestfix_flag = r"""`suggestfix'"""
// if suggestfix_flag.strip():
//     prompt += "\nPlease also suggest a possible fix for the error."
// else:
//     prompt += "\nPlease explain what the error means."
// try:
//     temperature = float("$explain_temperature") if "$explain_temperature" != "" else 0.3
// except Exception:
//     temperature = 0.3
// try:
//     max_tokens = int("$explain_max_tokens") if "$explain_max_tokens" != "" else 250
// except Exception:
//     max_tokens = 250
// api_key = "$explain_secret" if "$explain_secret" != "" else "YOUR_DEFAULT_API_KEY"
// import openai
// openai.api_key = api_key
// try:
//     response = openai.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
//     explanation = response.choices[0].text.strip()
//     print(explanation)
// except Exception as e:
//     print("Error calling OpenAI API: " + str(e))
//     sys.exit(1)
//                 end
//             }
//             else if ("`lines'" != "") {
//                 if ("$explain_file" == "") {
//                     display as error "No do-file set. Use: explain set file \"path/to/dofile.do\""
//                     exit 198
//                 }
//                 local line_spec = "`lines'"
//                 local start_line = ""
//                 local end_line = ""
//                 if (strpos("`line_spec'", ",") > 0) {
//                     local start_line : word 1 of "`line_spec'", ","
//                     local end_line : word 2 of "`line_spec'", ","
//                 }
//                 else if (strpos("`line_spec'", "-") > 0) {
//                     local start_line : word 1 of "`line_spec'", "-"
//                     local end_line : word 2 of "`line_spec'", "-"
//                 }
//                 else {
//                     local start_line = "`line_spec'"
//                     local end_line = "`line_spec'"
//                 }
//                 python:
// import sys
// dofile = r"""$explain_file"""
// try:
//     with open(dofile, "r") as f:
//         file_lines = f.readlines()
// except Exception as e:
//     print("Error reading file: " + str(e))
//     sys.exit(1)
// try:
//     start_line = int(r"""`start_line'""")
//     end_line = int(r"""`end_line'""")
// except Exception as e:
//     print("Error converting line numbers: " + str(e))
//     sys.exit(1)
// if start_line < 1 or end_line > len(file_lines) or start_line > end_line:
//     print("Invalid line range specified.")
//     sys.exit(1)
// extracted_code = "".join(file_lines[start_line-1:end_line])
// print("Extracted code (lines {}-{}):".format(start_line, end_line))
// print(extracted_code)
// prompt = f"I encountered an error in my Stata code.\nError message:\n{r"""`error_message'"""}\nHere is the code from lines {start_line} to {end_line} of {dofile}:\n{extracted_code}"
// suggestfix_flag = r"""`suggestfix'"""
// if suggestfix_flag.strip():
//     prompt += "\nPlease also suggest a possible fix for the error."
// else:
//     prompt += "\nPlease explain what the error means."
// try:
//     temperature = float("$explain_temperature") if "$explain_temperature" != "" else 0.3
// except Exception:
//     temperature = 0.3
// try:
//     max_tokens = int("$explain_max_tokens") if "$explain_max_tokens" != "" else 250
// except Exception:
//     max_tokens = 250
// api_key = "$explain_secret" if "$explain_secret" != "" else "YOUR_DEFAULT_API_KEY"
// import openai
// openai.api_key = api_key
// try:
//     response = openai.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
//     explanation = response.choices[0].text.strip()
//     print(explanation)
// except Exception as e:
//     print("Error calling OpenAI API: " + str(e))
//     sys.exit(1)
//                 end
//             }
//             else {
//                 // If no context options were provided, simply explain the error message.
//                 python:
// import sys
// import openai
// prompt = f"I encountered an error in my Stata code.\nError message:\n{r"""`error_message'"""}\nPlease explain what the error means."
// try:
//     temperature = float("$explain_temperature") if "$explain_temperature" != "" else 0.3
// except Exception:
//     temperature = 0.3
// try:
//     max_tokens = int("$explain_max_tokens") if "$explain_max_tokens" != "" else 250
// except Exception:
//     max_tokens = 250
// api_key = "$explain_secret" if "$explain_secret" != "" else "YOUR_DEFAULT_API_KEY"
// import openai
// openai.api_key = api_key
// try:
//     response = openai.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
//     explanation = response.choices[0].text.strip()
//     print(explanation)
// except Exception as e:
//     print("Error calling OpenAI API: " + str(e))
//     sys.exit(1)
//                 end
//             }
//             // Reset the global error message.
//             global last_error_msg ""
//             exit 0
//         }
//     }
//     else {
//         display as error "Unknown command. Use one of:
//    explain set <parameter> <value>
//    explain do \"path/to/do-file.do\" [rewrite]
//    explain error [r(errorcode)|errorcode] [, lines(<n>|<n>,<m>) | previous(<n>)] [suggestfix]
//    explain code [\"your code snippet\"] [, lines(<n>|<n>,<m>)]"
//         exit 198
//     }
end