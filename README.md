# Explain

**Explain** is a stateful, LLM‐assisted tool for Stata that helps you diagnose errors, understand code snippets, 
and even optimize entire do‑files by leveraging a large language model (LLM) of the user's choice such as OpenAI’s GPT-3/4.

## Features

- **Set Global Parameters:**  
  Configure key settings such as `temperature`, `max_tokens`, `max_lines`, API endpoint, secret key file, and the primary do‑file. For example:  
  ```stata
  explain set temperature 0.6
  explain set max_tokens 200
  explain set file "C:\MyProjects\analysis.do"
  
Error Explanation:
When an error occurs, capture the error message (or use the Stata error code) and ask the LLM to explain it. You can also extract context from your do‑file:
	•	General explanation:
