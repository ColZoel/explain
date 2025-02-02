 // ================================================================
 // 2. DO MODE
 //    Usage: explain do "path/to/do-file.do" [rewrite]
 // ================================================================

capture program drop explain_do
program define explain_do

    args file rewrite temperature max_tokens api_config

    python:
    import sys
    import modules

    dofile = r"""`file'"""
    dofile = modules.read_file(dofile).strip()

    rewrite_flag = r"""`rewrite'"""

    if rewrite_flag.strip():
        prompt = f"Please rewrite the following Stata do-file for improved optimization and clarity:\n{file_content}"
    else:
        prompt = f"Please explain what the following Stata do-file achieves:\n{file_content}"

    modules.call_api(prompt, temperature, max_tokens, api_config)
    end
    exit 0
end