import sys
import os
import subprocess
from builtins import print

corpus_prompts = {
    "do": {"rewrite": "Rewrite the following Stata do-file for improved optimization and clarity:",
           "suggestfix":"Consider any lines in the following do-file that may result in an error. "
                        "Check that the syntax is correct."
                         "Return any corrections in the form of 'current line -> corrected line'."
                        "If there are no errors, return 'No errors found'."
                        "Do-file:",
           "explain": "Explain how the following do-file works:"
           },
    "code": {"rewrite": f"Rewrite the following Stata code for improved optimization and clarity:",
        "suggestfix": f"Consider this Stata code. Check for any errors. "
                      f"Return any corrections in the form of 'current line -> corrected line'.",
             "explain": f"Explain how the following Stata code works:"},
    "error": {"suggestfix": "Consider the following error message, and relevant code. What is the error? "
                            "How do I fix it?"
                            "Return any corrections in the form of 'current line -> corrected line'.",
              "explain": "Explain what the following stata error code or message means in general. The error code "
                         "is of the format r(###). "}
}


sys_role = {
    "short":{
    "role": "system",
    "content": "You are an expert in the Stata statistical program. Your task is to answer questions about Stata code."
               "Respond as succinctly and briefly as possible. Prefer to use bullets if appropriate."
               "Do not lie. Do not make-up information. If you do not know the answer, say so."
               "You are speaking to your peers. Your response must be professional yet comfortable in tone."
    },
    "detail":{
            "role": "system",
            "content": "You are an expert in the Stata statistical program. "
                       "Your task is to answer questions about Stata code."
                       "Respond succinctly yet detailed."
                       "Carefully walk through any steps."
                       "Do not lie. Do not make-up information. "
                       "If you do not know the answer, say so."
                       "You are speaking to your peers. "
                       "Your response must be professional yet comfortable in tone."
    },
}


def build_prompt(detail, prompt):

    if detail:
        message = [
            sys_role['detail'],
            {
                "role": "user",
                "content": prompt
            }
        ]
        return message

    else:
        message = [
            sys_role['short'],
            {
                "role": "user",
                "content": prompt
            }
        ]

    return message

def unpack(options):
    rewrite = options["rewrite"]
    suggestfix = options["suggestfix"]
    detail = options["detail"]
    verbose = options["verbose"]
    return rewrite, suggestfix, detail, verbose

def init():

    try:
        subprocess.check_call([sys.executable, "-q","-m", "pip", "install", "aisuite"])
    except Exception as e:
        print("Error installing aisuite dependency: " + str(e))
        sys.exit(1)
    print("Successfully installed aisuite dependency.")
    return


def read_file(dofile, lines=None):
    print(f"Reading file: {dofile}")
    if dofile is not None:
        try:
            with open(dofile, "r") as f:
                file_lines = f.readlines()
                print(file_lines)
        except Exception as e:
            print("Error reading do-file: " + str(e))
            sys.exit(1)

        if lines is not None:
            if "-" in lines:
                lines = lines.split("-")
                start = int(lines[0])
                end = int(lines[1])

                file_lines = file_lines[start-1:end]
                file_lines = [f.strip('\n') for f in file_lines] # Stata is 1-indexed, adjust to 0-indexed
            else:
                file_lines = file_lines[int(lines)-1] # line number as written in Stata

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


def call_api(api_config, model, prompt, detail, verbose, kwargs):
    import aisuite
    client = aisuite.Client(api_config)
    message = build_prompt(detail, prompt)

    if verbose:
        print(f"\nmodel: {model}\n\n")
        print(f"message:\n {message}\n")
        for k, v in kwargs.items():
            print(f"\n{k}: {v}")


    try:
        response = client.chat.completions.create(model=model,
                                                 messages=message,
                                                  **kwargs)
        explanation = response.choices[0].message.content
        print("\n", explanation)
    except Exception as e:
        print("Error calling aisuite API: " + str(e))
        sys.exit(1)
    return


def explain_do(dofile, config_file, model, options, kwargs):

    file_lines = read_file(dofile)
    config = read_config(config_file)

    rewrite, suggestfix, detail, verbose = unpack(options)

    if rewrite:
        prompt = corpus_prompts["do"]["rewrite"] + "\n" + file_lines
    elif suggestfix:
        prompt = corpus_prompts["do"]["suggestfix"] + "\n" + file_lines
    else:
        prompt = corpus_prompts["do"]["explain"] + "\n" + file_lines


    call_api(config, model, prompt, detail, verbose, kwargs)
    return

def explain_code(
                 code=None,
                 dofile=None,
                 lines=None,
                 config_file=None,
                 model=None,
                 options=None,
                 kwargs=None):

    rewrite, suggestfix, detail, verbose = unpack(options)
    config = read_config(config_file)

    print(f"code: {code},\n")
    if code is None:
        code = read_file(dofile, lines)  # or subset if lines are specified

    if verbose:
        print(f"code: {code},\n"
              f" dofile: {dofile},\n"
              f" lines: {lines},\n"
              f" config: {config_file},\n"
              f" model: {model},\n"
              f" options: {options},\n"
              f" kwargs: {kwargs}")


    if options == "rewrite":
        prompt = corpus_prompts["code"]["rewrite"] + "\n" + code

    elif options == "suggestfix":
        prompt = corpus_prompts["code"]["suggestfix"] + "\n" + code
    else:
        prompt = corpus_prompts["code"]["explain"] + "\n" + code
    call_api(config, model, prompt, detail, verbose, kwargs)
    return


def explain_error(error, config_file, model, options, kwargs):
    config = read_config(config_file)

    rewrite, suggestfix, detail, verbose = unpack(options)

    if options == "suggestfix":
        prompt = corpus_prompts["error"]["suggestfix"] + "\n" + error
    else:
        prompt = corpus_prompts["error"]["explain"] + "\n" + error

    call_api(config, model, prompt, detail, verbose, kwargs)
    return


def main(subcommand,
         input=None,
         model=None,
         config=None,
         dofile=None,
         options=None,
         max_p=None,
         top_k=None,
         frequency_penalty=None,
         presence_penalty=None,
         stop_sequence=None,
         max_tokens=None,
         temperature=None):

    input = input if input != "" else None
    model = model if model != "" else None
    config = config if config != "" else None
    dofile = dofile if dofile != "" else None


    kwargs = {
        "max_p": max_p,
        "top_k": top_k,
        "frequency_penalty": frequency_penalty,
        "presence_penalty": presence_penalty,
        "stop_sequence": stop_sequence,
        "temperature": temperature,
        "max_tokens": max_tokens
    }


    i= options.find("lines:")
    if i != -1:
        lines = options[i+6:]
    else :
       lines = None

    opts = {
        "rewrite":    True if "rewrite" in options else False,
        "explain":    True if "explain" in options else False,
        "suggestfix": True if "suggestfix" in options else False,
        "detail":     True if "detail" in options else False,
        "verbose":    True if "verbose" in options else False,
        "lines":      lines if "lines" in options else None
    }

    kwargs = {k: v for k, v in kwargs.items() if v is not None and v!=""}

    if subcommand == "do":
        explain_do(dofile, config, model, opts, kwargs)
    elif subcommand == "code":

        explain_code(input, dofile, lines, config, model, opts, kwargs)

    elif subcommand == "error":
        explain_error(input, config, model, opts, kwargs)
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
    argparse = argparse.ArgumentParser()
    argparse.add_argument("subcommand",         type=str, help="do, code, error, or init")
    argparse.add_argument("input",              type=str, default=None)
    argparse.add_argument("model",              type=str,  default=None)
    argparse.add_argument("config",             type=str, default=None)
    argparse.add_argument("dofile",             type=str, default=None)
    argparse.add_argument("options",            type=str, default=None)
    argparse.add_argument("max_tokens",         type=str, default=None)
    argparse.add_argument("temperature",        type=str, default=None)
    argparse.add_argument("max_p",              type=str, default=None)
    argparse.add_argument("top_k",              type=str, default=None)
    argparse.add_argument("frequency_penalty",  type=str, default=None)
    argparse.add_argument("presence_penalty",   type=str, default=None)
    argparse.add_argument("stop_sequence",      type=str, default=None)
    args = argparse.parse_args()


    main(args.subcommand,
         args.input,
         args.model,
         args.config,
         args.dofile,
         args.options,
         args.max_tokens,
         args.temperature,
         args.max_p,
         args.top_k,
         args.frequency_penalty,
         args.presence_penalty,
         args.stop_sequence
         )


