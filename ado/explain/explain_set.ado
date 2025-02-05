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
	
	
	if ("`value'" == "" & "`param'" != "reset") {
				display as error "Missing value for `param'. See ' explain query '. 'set reset ' to reset all parameters."
				exit 198
			} 
			
	if ("`param'" == "python_env") {
        capture{
            if ("`value'" != "") {
                    quietly set python_exec "$python_env\python.exe"
                    di in red "Python env set:" "$python_env"
                    di in red "Reset Stata to use this environment."
                }
           }
    }

	else if ("`param'" == "dofile") {
		global explain_dofile "`value'"
		display as text "Do-file set to: " "`value'"
		di "$explain_file"
	}

    else if ("`param'" == "max_lines") {
		global explain_max_lines "`value'"
		display as text "Max lines set to " "`value'"
	}

    else if ("`param'" == "api_config") {
        global explain_api_config "`value'"
        display as text "API Config: " "`value'"
    }

    else if ("`param'" == "model") {
		global explain_model "`value'"
		display as text "Model: " "`value'"
	}

    else if ("`param'" == "sys_msg") {
        global explain_sys_msg "`value'"
        display as text "System role set: " "`value'"
    }

    else if ("`param'" == "user_msg") {
	            global explain_user_msg "`value'"
        display as text "User role set: " "`value'"
    }

	else if ("`param'" == "temperature") {
		
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

	else if ("`param'" == "max_p") {
        global explain_max_p "`value'"
        display as text "Max p set to " "`value'"
    }

    else if ("`param'" == "top_k") {
        global explain_top_k "`value'"
        display as text "Top k set to " "`value'"
    }

    else if ("`param'" == "frequency_penalty") {
        global explain_frequency_penalty "`value'"
        display as text "Frequency penalty set to " "`value'"
    }

    else if ("`param'" == "presence_penalty") {
        global explain_presence_penalty "`value'"
        display as text "Presence penalty set to " "`value'"
    }

    else if ("`param'" == "stop_sequence") {
        global explain_stop_sequence "`value'"
        display as text "Stop sequence set to " "`value'"
    }

    else if ("`param'" == "reset") {
        global explain_temperature ""
        global explain_max_tokens ""
        global explain_max_p ""
        global explain_top_k ""
        global explain_frequency_penalty ""
        global explain_presence_penalty ""
        global explain_stop_sequence ""
        global explain_model ""
        global explain_api_config ""
        global explain_dofile ""
        display as text "All parameters reset. to missing. "
    }


	else {
		display as error "Unknown parameter: `param'"
		exit 198
	}
	exit 0
end 