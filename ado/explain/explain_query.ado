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

	local header "-----------------------------------------------------------------"
	local header_row " Parameter      |             "


	// Display all parameters.
	display as text "`header'"
	display as text "`header_row'"
	display as text "`header'"


    if ("`value'"== "python_env" | "`value'"== ""){
	    display as text " python environ | $python_env"
	}

	if ("`value'"== "dofile" | "`value'"== ""){
	    display as text " do-file        | $explain_dofile"
	}

    if ("`value'"== "max_lines" | "`value'"== ""){
        display as text " max_lines      | $explain_max_lines"
    }
    if ( "`value'"== ""){
        display as text "`header'"
    }

    if ("`value'"== "api_config" | "`value'"== ""){
        display as text " api_config     | $explain_api_config"
    }

    if ("`value'"== "model" | "`value'"== ""){
        display as text " model*         | $explain_model"
	}

	if ("`value'"== ""){
	    display as text "`header'"
	}
	if ("`value'"== "sys_msg" | "`value'"== ""){
	    display as text " system message | (view or set in global explain_system_role_msg)"
	}
	if ("`value'"== "user_msg" | "`value'"== ""){
	    display as text " user message   | (view or set in global explain_user_role_msg)"
	}
	if ("`value'"== "temperature" | "`value'"== ""){
	    display as text " temperature**  | $explain_temperature"
	}
	if ("`value'"== "max_tokens" | "`value'"== ""){
	    display as text " max_tokens     | $explain_max_tokens"
	}
	if ("`value'"== "max_p" | "`value'"== ""){
	    display as text " max_p          | $explain_max_p"
	}
	if ("`value'"== "top_k" | "`value'"== ""){
	    display as text " top_k          | $explain_top_k"
	}
	if ("`value'"== "freq_penalty" | "`value'"== ""){
	    display as text " freq_penalty   | $explain_frequency_penalty"
	}
	if ("`value'"== "pres_penalty" | "`value'"== ""){
	    display as text " pres_penalty   | $explain_presence_penalty"
	}
	if ("`value'"== "stop_sequence" | "`value'"== ""){
	    display as text " stop_sequence  | $explain_stop_sequence"
	}
	if ("`value'"== ""){
	    display as text "`header'"
    }
    di "* Language models are experimental and may return unexpected results."
    di "** Be sure to check provider documentation. An error 403 occurs"
    di "   if the model does not accept that parameter."
exit 0
	
end