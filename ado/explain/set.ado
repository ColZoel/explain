	// ================================================================
    // 1. SET MODE
	//	  Set LLM and function parameters. 
    //    Usage: explain set <parameter> <value>
	//	  	
	//	  Parameters include:
	//	  - temperature
	//	  - max_tokens
	//	  - max_lines
	//	  - model
	//	  - secret containing API key, if necessary
    // ================================================================
	
capture program drop explain_set
program define explain_set
	
	args param value
	
	
	if ("`value'" == "") {
				display as error "Missing value for `param'. See ' explain query '"
				exit 198
			} 
			
	if ("`param'" == "temperature") {
		
		if (`value'==0 | `value'>=1) {
			
			display as error "temperature must be (0, 1)"
			exit 198
		} 
		
		global explain_temperature "`value'"
		display as text "Temperature set to " "`value'"
	}
	
	else if ("`param'" == "max_tokens") {
		global explain_max_tokens "`value'"
		display as text "Max tokens set to " "`value'"
	}
	
	else if ("`param'" == "max_lines") {
		global explain_max_lines "`value'"
		display as text "Max lines set to " "`value'"
	}
	
	else if ("`param'" == "model") {
		global explain_model "`value'"
		display as text "Model: " "`value'"
	}
	
	else if ("`param'" == "secret") {
		// Read the secret (API key) from the given file.
		file open fsecret using "`value'", read text
		file read fsecret line
		local secret ""
		while r(eof)==0 {
			local secret "`secret'" + "`line'" + " "
			file read fsecret line
		}
		file close fsecret
		global explain_secret "`secret'"
		display as text "Secret loaded from: " "`value'"
	}
	
	else if ("`param'" == "file") {
		global explain_file "`value'"
		display as text "Do-file set to: " "`value'"
	}
	
	else {
		display as error "Unknown parameter: `param'. Allowed: temperature, max_tokens, max_lines, model, secret, file."
		exit 198
	}
	exit 0
end 