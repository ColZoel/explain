// ================================================================
// 3. CODE MODE
//    Usage:
//       a) explain code "your code snippet"
//       b) explain code, lines(10)         (extracts line 10)
//       c) explain code, lines(10-20) or lines(10,20)
//          (extracts that range from the file set previously)
// ================================================================

capture program drop explain_code
program define explain_code
    syntax [anything(name=code_text)] [ , lines(string) ]

    args code_text lines

    if ("`lines'" != "") {
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


        if start_line < 1 or end_line > len(file_lines) or start_line > end_line:
            print("Invalid line range specified.")
            sys.exit(1)
        extracted_code = "".join(file_lines[start_line-1:end_line])
        print("Extracted code (lines {}-{}):".format(start_line, end_line))
        print(extracted_code)

        prompt = f"Please explain what the following Stata code (from lines {start_line} to {end_line} of {dofile}) achieves:\n{extracted_code}"
        modules.call_api(api_config, model, prompt, max_tokens, temperature)

        end
        exit 0
    }

    else {
        if ("`code_text'" == "") {
            display as error "No code snippet provided."
            exit 198
        }

        python:
        import sys
        import openai
        code_snippet = r"""`code_text'"""
        prompt = f"Please explain the following Stata code:\n{code_snippet}"
        modules.call_api(api_config, model, prompt, max_tokens, temperature)
        end
        exit 0
    }

end