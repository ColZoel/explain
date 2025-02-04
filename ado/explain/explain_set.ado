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

    else if ("`param'" == "api_config") {
        global explain_api_config "`value'"
        display as text "API Config: " "`value'"
    }

	
	else if ("`param'" == "dofile") {
		global explain_dofile "`value'"
		display as text "Do-file set to: " "`value'"
		di "$explain_file"
	}

	else if ("`param'" == "python_env") {
        global python_env "`value'"
        display as text "Python Environment: " "`value'"
    }


	else {
		display as error "Unknown parameter: `param'"
		exit 198
	}
	exit 0
end 