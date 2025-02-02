*** Query the explain parameters


	// ================================================================
    // 0. QUERY MODE
	//	  Print LLM and function parameters. 
    //    Usage: explain query 
	//			for full list 
	
    //    Usage: explain query <parameter>		
	//			for the value of <parameter>
	// ================================================================	

capture program drop explain_query
program define explain_query
		
	args value

	local header "--------------------------------------------------------------"
	local header_row " Parameter   | Current Value  (Possible)"

	if ("`value'" != "") {
	
		// display individual parameters

		local param = lower("`value'")
		if ("`param'" == "temperature") {
			display as text "`header'"
			display as text "`header_row'"
			display as text "`header'"
			display as text " temperature | $explain_temperature 		Any integer (0, 1) "

		}
		else if ("`param'" == "maxtokens") {
			display as text "`header'"
			display as text "`header_row'"
			display as text "`header'"
			display as text "| maxtokens  | $explain_max_tokens 		model specific, usually around 4000"

		}
		else if ("`param'" == "maxlines") {
			display as text "`header'"
			display as text "`header_row'"
			display as text "`header'"
			display as text "| maxlines   | $explain_max_lines  any integer, or . for whole file "
			display as text "`header'"
		}
		else if ("`param'" == "model") {
			display as text "`header'"
			display as text "`header_row'"
			display as text "`header'"
			display as text "| model         | $explain_model "

		}
		else if ("`param'" == "secret") {
			display as text "`header'"
			display as text "`header_row'"
			display as text "`header'"
			display as text "| secret      | $explain_secret "

		}
		else if ("`param'" == "file") {
			display as text "`header'"
			display as text "`header_row'"
			display as text "`header'"
			display as text "| file        | $explain_file "

	}
	else {
		display as error "Unknown parameter: `param'. Allowed: temperature, max_tokens, max_lines, api, secret, file."
	}
}
else {
	// Display all parameters.
	display as text "`header'"
	display as text "`header_row'"
	display as text "`header'"
	display as text " temperature | $explain_temperature		(n in range (0, 1))"
	display as text " max_tokens  | $explain_max_tokens		(model specific, usually around 4000)"
	display as text " max_lines   | $explain_max_lines		(any integer, or . for whole file)"
	display as text " api         | $explain_model		"
	display as text " secret      | $explain_secret		"
	display as text " file        | $explain_file		"
	display as text "`header'"
}
exit 0
	
end