// ================================================================
// 4. ERROR MODE
//    Usage options:
//      a) explain error
//         – If no explicit error code is given, the program checks:
//              • If global last_error_msg is empty then it uses _rc (even if _rc==0)
//         – The user may supply context options:
//              • lines(10)         -> use line 10
//              • lines(10,20)      -> use lines 10 to 20
//              • previous(10)      -> use the 10 lines preceding the error
//
//      b) explain error r(198)  or  explain error 198
//         – Explains that specific error code.
// After processing, global last_error_msg is reset.
// ================================================================

capture program drop explain_error
program define explain_error
    args 0

    // Check if a second token is provided (explicit error code).
    local token2 : word 2 of "`0'"
    if ("`token2'" != "" & substr("`token2'",1,1) != ",") {
        local errorcode = "`token2'"

        if (substr("`errorcode'",1,2)=="r(" & substr("`errorcode'",-1,1)==")") {
            local errorcode = substr("`errorcode'",3,strlen("`errorcode'")-3)
        }
        quietly confirm number `errorcode'
        if (_rc) {
            display as error "Invalid error code."
            exit 198
        }

        python:
        import sys
        import modules
        error_code = "`errorcode'"
        prompt = f"I encountered the following Stata error code: r({error_code}).\nPlease explain what this error code means and suggest potential solutions."

        modules.call_api(prompt, temperature, max_tokens, api_config)

        end
        global last_error_msg ""
        exit 0
    }

    else {
        // No explicit error code was provided.
        syntax , [lines(string)] [previous(integer)] [suggestfix]
        if ("$last_error_msg" == "") {
            local error_code = c(rc)
            local error_message = "Stata error code: " + "`error_code'"
        }
        else {
            local error_message = "$last_error_msg"
        }
        // Determine the context extraction method.
        if ("`previous'" != "") {
            if ("$explain_file" == "") {
                display as error "No do-file set. Use: explain set file \"path/to/dofile.do\""
                exit 198
                }

            python:
            import sys
            import modules

            dofile = r"""$explain_file"""
            dofile = modules.read_file(dofile)

            prev_num_str = r"""`previous'"""
            try:
                prev_num = int(prev_num_str)
            except Exception as e:
                print("Error converting previous parameter: " + str(e))
                sys.exit(1)
            error_line_str = r"""$last_error_line"""
            if error_line_str.strip() == "":
                error_line = len(file_lines)
            else:
                try:
                    error_line = int(error_line_str)
                except Exception:
                    error_line = len(file_lines)
            start_line = max(0, error_line - prev_num - 1)
            context_lines = "".join(file_lines[start_line:error_line-1])
            print("Extracted previous lines (lines {} to {}):".format(start_line+1, error_line-1))
            print(context_lines)
            prompt = f"I encountered an error in my Stata code.\nError message:\n{r"""`error_message'"""}\nHere are the {prev_num} lines preceding the error (from {dofile}):\n{context_lines}"


            suggestfix_flag = r"""`suggestfix'"""

            if suggestfix_flag.strip():
                prompt += "\nPlease also suggest a possible fix for the error."
            else:
                prompt += "\nPlease explain what the error means."

            modules.call_api(prompt, temperature, max_tokens, api_config)

            end
        }

        else if ("`lines'" != "") {
            if ("$explain_file" == "") {
                display as error "No do-file set. Use: explain set file \"path/to/dofile.do\""
                exit 198
            }
            local line_spec = "`lines'"
            local start_line = ""
            local end_line = ""

            if (strpos("`line_spec'", ",") > 0) {
                local start_line : word 1 of "`line_spec'", ","
                local end_line : word 2 of "`line_spec'", ","
            }
            else if (strpos("`line_spec'", "-") > 0) {
                local start_line : word 1 of "`line_spec'", "-"
                local end_line : word 2 of "`line_spec'", "-"
            }
            else {
                local start_line = "`line_spec'"
                local end_line = "`line_spec'"
            }

            python:
            import sys
            import modules

            dofile = r"""$explain_file"""
            dofile = modules.read_file(dofile)

            try:
                start_line = int(r"""`start_line'""")
                end_line = int(r"""`end_line'""")
            except Exception as e:
                print("Error converting line numbers: " + str(e))
                sys.exit(1)
            if start_line < 1 or end_line > len(file_lines) or start_line > end_line:
                print("Invalid line range specified.")
                sys.exit(1)
            extracted_code = "".join(file_lines[start_line-1:end_line])
            print("Extracted code (lines {}-{}):".format(start_line, end_line))
            print(extracted_code)
            prompt = f"I encountered an error in my Stata code.\nError message:\n{r"""`error_message'"""}\nHere is the code from lines {start_line} to {end_line} of {dofile}:\n{extracted_code}"
            suggestfix_flag = r"""`suggestfix'"""

            if suggestfix_flag.strip():
                prompt += "\nPlease also suggest a possible fix for the error."
            else:
                prompt += "\nPlease explain what the error means."

            modules.call_api(prompt, temperature, max_tokens, api_config)

             end
        }

        else {

            // If no context options were provided, simply explain the error message.
            python:
            import sys
            import modules
            prompt = f"I encountered an error in my Stata code.\nError message:\n{r"""`error_message'"""}\nPlease explain what the error means."
            module.call_api(prompt, temperature, max_tokens, api_config)
            end
        }

        // Reset the global error message.
        global last_error_msg ""
        exit 0
    }

end