import sys
import os
import subprocess

corpus_prompts = {
    "do": {"rewrite": "Rewrite the following Stata do-file for improved optimization and clarity:",
           "explain": "Explain what the following Stata do-file achieves:"
           },
    "code": {"suggestfix": f"",
             "explain": f""},
    "error": {f""}
}


sys_role = {
    "role": "system",
    "content": "You are an expert in the Stata statistical program. Your task to answer questions about Stata code."
               "Respond as succinctly and briefly as possible. Prefer to use bullets if appropriate."
               "Do not lie. Do not make-up information. If you do not know the answer, say so."
               "You are speaking to your peers. Your response must be professional yet comfortable in tone."
}


def build_prompt(prompt):
    message = [
        sys_role,
        {
            "role": "user",
            "content": prompt
        }
    ]
    return message


def init():

    try:
        subprocess.check_call([sys.executable, "-q","-m", "pip", "install", "aisuite"])
    except Exception as e:
        print("Error installing aisuite dependency: " + str(e))
        sys.exit(1)
    print("Successfully installed aisuite dependency.")
    return


def read_file(dofile):
    try:
        with open(dofile, "r") as f:
            file_lines = f.readlines()
    except Exception as e:
        print("Error reading do-file: " + str(e))
        sys.exit(1)
    return "\n".join(file_lines)


def read_config(config_file):
    import json
    try:
        with open(config_file, "r") as f:
            config = json.load(f)
    except Exception as e:
        print("Error reading config file: " + str(e))
        sys.exit(1)
    return config


def call_api(api_config, model, prompt, kwargs):
    import aisuite
    client = aisuite.Client(api_config)
    message = build_prompt(prompt)

    print("kwargs: ", kwargs)

    try:
        response = client.chat.completions.create(model=model,
                                                 messages=message,
                                                  **kwargs)
        explanation = response.choices[0].message.content
        print("\n", explanation)
    except Exception as e:
        print("Error calling aisuite API: " + str(e))
        sys.exit(1)


def explain_do(dofile, config_file, model, options, kwargs):

    file_lines = read_file(dofile)
    config = read_config(config_file)

    if options  == "rewrite":
        prompt = corpus_prompts["do"]["rewrite"] + "\n" + file_lines
    else:
        prompt = corpus_prompts["do"]["explain"] + "\n" + file_lines
    call_api(config, model, prompt, kwargs)


def explain_code(code, config_file, model, options, kwargs):
    config = read_config(config_file)

    if options == "suggestfix":
        prompt = corpus_prompts["code"]["suggestfix"] + "\n" + code
    else:
        prompt = corpus_prompts["code"]["explain"] + "\n" + code
    call_api(config, model, prompt, kwargs)


def explain_error(error, config_file, model, kwargs):

    config = read_config(config_file)
    prompt = corpus_prompts["error"] + "\n" + error
    call_api(config, model, prompt, kwargs)


def main(subcommand,
         input=None,
         model=None,
         config=None,
         options=None,
         max_p=None,
         top_k=None,
         frequency_penalty=None,
         presence_penalty=None,
         stop_sequence=None,
         max_tokens=None,
         temperature=None):

    kwargs = {
        "max_p": max_p,
        "top_k": top_k,
        "frequency_penalty": frequency_penalty,
        "presence_penalty": presence_penalty,
        "stop_sequence": stop_sequence,
        "temperature": temperature,
        "max_tokens": max_tokens
    }

    kwargs = {k: v for k, v in kwargs.items() if v is not None and v!=""}


    if subcommand == "do":
        explain_do(input, config, model, options, kwargs)
    elif subcommand == "code":
        explain_code(input, config, model, options, kwargs)
    elif subcommand == "error":
        explain_error(input, config, model, options, kwargs)
    elif subcommand == "init":
        try:
            import aisuite
            print(f"aisuite dependency already installed in env: {os.path.dirname(sys.executable)}.")
        except ImportError:
            print(f"Attempting to install aisuite dependency into {os.path.dirname(sys.executable)}...")
            init()
    else:
        print("Invalid subcommand. Please use 'do', 'code', or 'error'.")
        sys.exit(1)


if __name__ == "__main__":
    import argparse
    argparse = argparse.ArgumentParser(description="Explain Stata do-files, code snippets, and error messages.")
    argparse.add_argument("subcommand", type=str, help="do, code, error, or init")
    argparse.add_argument("input", type=str, help="path to do-file, code snippet, or error message", default=None)
    argparse.add_argument("model", type=str, help="model name", default=None)
    argparse.add_argument("config", type=str, help="path to config file", default=None)
    argparse.add_argument("options", type=str, help="rewrite, explain, suggestfix", default=None)
    argparse.add_argument("max_tokens", type=str, help="maximum tokens to generate", default=None)
    argparse.add_argument("temperature", type=str, help="temperature for sampling", default=None)
    argparse.add_argument("max_p", type=str, help="maximum probability for sampling", default=None)
    argparse.add_argument("top_k", type=str, help="top k tokens to sample from", default=None)
    argparse.add_argument("frequency_penalty", type=str, help="frequency penalty", default=None)
    argparse.add_argument("presence_penalty",  type=str, help="presence penalty", default=None)
    argparse.add_argument("stop_sequence", type=str, help="stop sequence", default=None)
    args = argparse.parse_args()


    main(args.subcommand,
         args.input,
         args.model,
         args.config,
         args.options,
         args.max_tokens,
         args.temperature,
         args.max_p,
         args.top_k,
         args.frequency_penalty,
         args.presence_penalty
         )


