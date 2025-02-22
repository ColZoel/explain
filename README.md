# Explain

---
**Explain** is a stateful, LLM‐assisted tool for Stata that helps you diagnose errors, understand code snippets, 
and even optimize entire do‑files by leveraging a large language model (LLM) of the user's choice. Built
ontop of Andrew Ng's `aisuite` [package](https://github.com/andrewyng/aisuite) for model interfacing,
`explain` provides a simple interface to interact with a wide variety
of hosted and local LLMs in a Stata instance.

# Installation

---
To install the latest version of `explain`, use the following command in Stata:
```stata
net install explain, from("https://raw.githubusercontent.com/colzoel/explain/main/src/")
```


## Requirements
- Stata 16.1 or higher
- Python 3.6 or higher
- `aisuite` package (automatically installed with `explain`)


Interfacing directly with LLMs across providers is generally very tedious due to nuances in syntax and other specifications, 
which makes direct `curl` calls from Stata difficult between providers. 
`aisuite` is designed to standardize the interface to a wide variety of LLMs, so you can easily switch between providers 
without changing your code.

### Hosted LLM Requirements
- Network access
- API key from a supported LLM provider (e.g., OpenAI)

You can find a complete list of supported providers in the `aisuite`[documentation](https://github.com/andrewyng/aisuite/tree/main/aisuite/providers).


### Local LLM Requirements
- Either the application or CLI tools from [Ollama](https://ollama.com)
- A local model installed and running (e.g. listening on port 1234), either custom-built or downloaded from the Ollama repository



## Syntax
```stata
explain [subcommand] [using] [, rewrite suggestfix detail capture lines(integer[-integer]) verbose]
```

### Subcommands
| Subcommand | Description                                         |
|------------|-----------------------------------------------------|
| `init`     | Initialize Python and install the `aisuite` package |
| `query`    | Display the current settings                        |
| `set`      | Set a parameter to a value                          |
| `do`       | Run `explain` using a do-file as context            |
| `code`     | Run  `explain` using inputted code lines as context |
| `error`    | Run  `explain` on an error message                  |
"Context" is used here in the LLM sense, where a given string of text is used to generate a response for a 
particular prompt: "Using this text, do this."

### Options
| Option                     | Description                                           |
|----------------------------|-------------------------------------------------------|
| `rewrite`                  | rewrite the code for efficiency (extensive revision)  |
| `suggestfix`               | Suggest a fix for the error (minimal revision)        |
| `detail`                   | provide a more detailed explanation                   |
| `capture`                  | capture the output in a local macro                   |
| `lines(integer[-integer])` | specify line numbers in the do‑file to use as context |
| `verbose`                  | display additional and debug information              |




___
# Explain Query
See the current settings of the tool, including internal settings, API settings, and model settings.
## Syntax

```stata
explain query [parameter]
```
Omitting the parameter returns a list of all settings.

To set a parameter, use:
```stata
explain set parameter value
```


### Possible Parameters
| Parameter           | Description                                                   |
|---------------------|---------------------------------------------------------------|
| **Stata**           |                                                               |
| `python_env`        | (optional) Specify the Python environment to use.             |
| **API**             |                                                               |
| `api_config`        | (optional) Path of file containing API key and provider       |
| `model`             | Specifies the LLM model in form of "provider:model-name"      |
| **Model**           |                                                               |
| `sys_msg`           | (optional) Add custom LLM Role Prompt                         |
| `user_msg`          | (optional) Specify the user message to use.                   |
| `temperature`       | (optional) Control the randomness of the LLM's responses.     |
| `max_tokens`        | (optional) Limit the number of tokens the LLM can generate.   |
| `max_p`             | (optional) Limit the probability of the LLM's responses.      |
| `top_k`             | (optional) Limit the number of tokens considered by the LLM.  |
| `frequency_penalty` | (optional) Increase the likelihood of new tokens.             |
| `presence_penalty`  | (optional) Increase the likelihood of tokens already present. |
| `stop_sequence`     | (optional) Specify a sequence of tokens to stop generation.   |

**Note** the availability of model parameters depends on the model you choose. These are the 
most common set of parameters that are available across most models, but some models may 
have additional parameters or may not support some of these parameters. If the model does not
support a parameter, it will return an error 503 (Not Implemented).

#### Python Environment
If you have a specific Python environment you want to use, you can specify it here. This should point the environment folder 
and will search for its Python executable. For example,
```stata
explain set python_env "C:\user\Anaconda3\envs\myenv"
```

#### API Configuration
`api_config` is the path to a text or JSON file containing the API key and provider.
The file should be in the following format (or similar formats depending on the provider):
```json
// api.txt

{"provider": {api_key: "your-api-key"}}

// e.g. Hugging Face
{"huggingface": {"token": "your-api-key"}}

//multiple providers
{"provider1": {"api_key": "your-api-key1"}, "provider2": {"api_key": "your-api-key2"}}
```

```stata
explain set api_config "C:\user\api.txt"

* alternatively, set the environment variable

!export HUGGINGFACE_API_KEY="your-api-key"
```

#### Model
The format is `provider:model-name`. For example, to use the Llama model from 
Hugging Face (assuming you have the API key set in an environment variable or a file), you can set the model with:
```stata
explain set model "huggingface:meta-llama/Llama-3.3-70B-Instruct"
```
#### Advanced Parameters 
**`sys_msg`**
This is an advanced option that allows you to set a custom LLM role prompt that changes the behavior of the LLM.
Use `di $sys_msg` to see the current system message.

**`user_msg`**
This is an advanced option that allows you to set a custom user message that changes the user prompt of the LLM
Use `di $user_msg` to see the current user message. 

See the provider's documentation to learn about model-specific parameters.

___
# Explain Do
Use the `do` subcommand to run `explain` using a do-file as context.

## Syntax
```stata
explain do using [, rewrite suggestfix detail lines(integer[-integer]) verbose]
```
## Examples
Consider the following simple do-file, `analysis.do`:
```stata
sysuse auto, clear
summarize price mpg
scatter price mpg
regress price mpg ard
predict residuals, residuals 
```
In the command window or another do-file, run
```stata
explain do using "C:\MyProjects\analysis.do"
```
to get a concise explanation of what the do-file does. This is especially helpful for long do-files or 
looking at other researchers' code. 

Most models will explain the code using bullet points, but if you want a more detailed explanation, use the `detail` option.
You may need to increase the `max_tokens` setting to accommodate the additional output tokens required depending on the selected model.

To isolate a few lines of code from the do-file, use the `lines` option:
```stata
explain do using "C:\MyProjects\analysis.do", lines(1-2)
```
will only consider the first two lines of the do-file as they appear in the do-file editor of Stata.


If your do-file contains errors, is incomprehensible, or you want to optimize it, use the `suggestfix` or `rewrite` options:
```stata
explain do using "C:\MyProjects\analysis.do", suggestfix
```
which prints a suggested improved version of the do-file. `suggestfix` is a minimal revision, widely for issues stemming with
syntactic issues or native-Stata programs, while `rewrite` is an extensive revision that will rewrite the entire do-file for efficiency
and clarity.

---
# Explain Code 
use the `code` subcommand to run `explain` using inputted code as context.

## Syntax
```stata
explain code "code" [, suggestfix detail  verbose]
```

## Examples
```stata
explain code "sysuse auto, clear"
```
This will return a concise explanation (usually bulleted) of only the string of code provided. the `detail` option
can be used to get a more detailed explanation. `suggestfix` can be used to get clean, optimize, rewrite, or debug the code.
Note that this does not consider the line of code in context of the entire do-file, so debugging is limited mainly to syntax errors.

In some cases, `explain code` and `explain do` are equivalent:

```stata
explain code "sysuse auto, clear"
explain do using "C:\MyProjects\analysis.do", lines(1)
```
---

# Explain Error
Use the `error` subcommand to run `explain` on an error message. This is especially useful for debugging code. 
`explain` will use the error message in `r(error)` by default, but you can specify a different error message.
## Syntax

```stata
explain error [r(#)] [code] [using] [, suggestfix detail capture lines(integer[-integer]) verbose]
```
`r(#)` is the error code or message. For example, `r(0)` means the code executed without error, and 
`r(198)` is a common syntax error.
If the `using` option is not specified, a general explanation of the error code is returned.
If the `using` option is specified, the tool will use the do-file as context for the error explanation. You can also further 
refine the context by specifying the `lines()` option to use specific lines of the do-file as context.

`suggestfix` returns a potential solution to the error. `detail` provides a more detailed explanation of the error.

`capture` runs the code in a `capture` block to retain the error message in `r(error)`, then returns the explanation.




## Examples

### 1. General explanation
```stata
explain error r(111)
```
returns a general explanation of error code `r(111)`.

### 2. Explanation of an error message
```stata
capture gen x = 1 + "a"
explain error
```
`explain error` assumes the error message is in `r(error)`, which requires the `capture` clause. You can
capture the error message of a block of code with


```stata
capture noisily {
... command ...
}
```

You can avoid using the `capture` clause by inputting the line of code directly and specifying the `capture` option:

```stata    
explain error "gen x = 1 + "a"", capture
```
which wraps the code in a `capture` block, executes it, retains the error message in `r(error)`, 
and returns the explanation.

### 3. Error code from a do-file
```stata
explain error r(111) using "C:\MyProjects\analysis.do", lines(1)
```
tries to connect the error code `r(111)` to the first line of the do-file `analysis.do`. This may yield unexpected results
if in fact there is no error `r(111)` in the first line of the do-file.

Instead of specifying an error message, you can exectute the code and explain whatever error does occur. 
Notice there is an error in `analysis.do`: There is a variable `ard` in line 4 that does not exist in the dataset. 
The following snippets are equivalent:
```stata
explain error using "C:\MyProjects\analysis.do", lines(4) capture
explain error "regress price mpg ard", capture
```

```stata
capture noisily {
do "C:\MyProjects\analysis.do"
}
explain error

explain error "do C:\MyProjects\analysis.do", capture

```

Since there is only one error in the do-file, all of these commands will point the LLM to the same error message and return 
the same explanation.
---

## A note about Context and Memory

The idea of "memory" for most LLM models is simply a concatenation of prompts and responses throughout the progression 
of a chat. `explain` is not designed for chat models, and while it supports many models capable of retaining memory of the history of
a chat, `explain` starts a fresh API connection each time it is called. It is as if you are starting a new chat with the model
each time you call `explain`. This reduces temporal degradation of the model's responses, computational overhead, and 
contextual problems if you are editing the code or do-file between calls to `explain`.

# License

---
This software is licensed under the MIT License. Feel free to use and distribute this software as you see fit.

# Contributing

---
Please, please, please fork this repository and contribute! 

# Further Reading

---
## Interested in LLMs and AI?
Consider using Hugging Face's many free courses on AI and LLMs, 
such as the [Natural Language Processing course](https://huggingface.co/course/chapter1) 
or the [Fine-Tuning a Model course](https://huggingface.co/course/chapter2).

---
# Acknowledgements

---
Thanks to Andrew Ng for the simplified interface of the `aisuite` package, which means I don't have to write countless `curl` commands.
Thanks to Washington University at St. Louis for the support and computational resources to develop this tool.


# Author

---
Collin Zoeller<br>
[collinzoeller@gmail.com](mailto:collinzoeller@gmail.com)<br>
Tepper School of Business<br>
Carnegie Mellon University<br>
[GitHub](github.com/colzoel)<br>
[LinkedIn](linkedin.com/in/collin-zoeller)<br>
[Website](colzoel.github.io)
