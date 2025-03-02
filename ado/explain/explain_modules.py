import sys
import os
import subprocess
import json


corpus_prompts = {
    "do": {"rewrite": "Rewrite the following Stata do-file for improved optimization and clarity:",
           "suggestfix": "Consider any lines in the following do-file that may result in an error. "
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
              "explain": "Explain what the following stata error code or message means. If code is provided, "
                         "describe the error in context of the code."}
}


sys_role = {
    "short": {
     "role": "system",
     "content": "You are an expert in the Stata statistical program. Your task is to answer questions about Stata code."
                "Respond as succinctly and briefly as possible. Prefer to use bullets if appropriate."
                "Do not lie. Do not make-up information. If you do not know the answer, say so."
                "You are speaking to your peers. Your response must be professional yet comfortable in tone."
    }
}


def build_prompt(prompt):

    message = [
        sys_role['short'],
        {
            "role": "user",
            "content": prompt
        }
    ]

    return message


def linenums(options):
    i = options.find("lines:")
    if i != -1:
        lines = options[i+6:]
        if lines == "":
            lines = None
    else:
        lines = None
    return lines


def init():

    try:
        subprocess.check_call([sys.executable, "-q", "-m", "pip", "install", "aisuite"])
    except Exception as e:
        print("Error installing aisuite dependency: " + str(e))
        sys.exit(1)
    print("Successfully installed aisuite dependency.")
    return


def read_file(dofile, lines=None):
    # print(f"Reading file: {dofile}")
    if dofile is not None and dofile != "":
        try:
            with open(dofile, "r") as f:
                file_lines = f.readlines()
                # print(file_lines)
        except Exception as e:
            print("Error reading do-file: " + str(e))
            sys.exit(1)

        if lines is not None:
            if "-" in lines:
                lines = lines.split("-")
                start = int(lines[0])
                end = int(lines[1])

                file_lines = file_lines[start-1:end]
                file_lines = [f.strip('\n') for f in file_lines]  # Stata is 1-indexed, adjust to 0-indexed
                return "\n".join(file_lines)
            else:
                file_lines = file_lines[int(lines)-1]  # line number as written in Stata
                return file_lines
    else:
        return ""


def read_config(config_file):

    if config_file == "" or config_file is None:
        print("No config file provided.")
        sys.exit(1)

    try:
        with open(config_file, "r") as f:
            config = json.load(f)
    except Exception as e:
        print("Error reading config file: " + str(e))
        sys.exit(1)
    return config


def call_api(api_config, model, prompt, verbose, kwargs):
    import aisuite
    client = aisuite.Client(api_config)
    message = build_prompt(prompt)

    if verbose:
        print(f"\nmodel: {model}\n\n")
        print(f"message:\n {message}\n")
        for k, v in kwargs.items():
            print(f"\n{k}: {v}")

    if model is None or model == "":
        print("model required.")
        sys.exit(1)

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


def explain_(subcmd, usr_input, config, model, dofile, opts, kwargs):

    configx = read_config(config)
    dofx = read_file(dofile, opts['lines'])
    if opts["verbose"]:
        options  = [k for k,v in opts.items() if v]
        print(f" subcommand: {subcmd},\n"
              f" input: {usr_input},\n"
              f" dofile path: {dofile},\n"
              f" dofile content: {dofx},\n"
              f" lines: {opts['lines']},\n"
              f" config: {config},\n"
              f" model: {model},\n"
              f" options: {options},\n"
              f" kwargs: {kwargs}")

    for i in ["rewrite", "suggestfix"]:
        if opts[i]:
            prompt = f"{corpus_prompts[subcmd][i]}\n{usr_input} {dofx}"
            break
        else:
            prompt = f"{corpus_prompts[subcmd]['explain']}\n{usr_input} {dofx}"

    call_api(configx, model, prompt, opts['verbose'], kwargs)
    return


# ####### MAIN FUNCTION ########
def main(subcommand,
         usr_input=None,
         model=None,
         config=None,
         dofile=None,
         options=None,
         max_p=None,
         top_k=None,
         max_tokens=None,
         temperature=None,
         frequency_penalty=None,
         presence_penalty=None,
         stop_sequence=None
         ):

    kwargs = {
        "max_p": max_p,
        "top_k": top_k,
        "max_tokens": max_tokens,
        "temperature": temperature,
        "frequency_penalty": frequency_penalty,
        "presence_penalty": presence_penalty,
        "stop_sequence": stop_sequence
    }

    kwargs = {k: v for k, v in kwargs.items() if v is not None and v != ""}

    lines = linenums(options)

    opts = {
        "rewrite":    True if "rewrite" in options else False,
        "explain":    True if "explain" in options else False,
        "suggestfix": True if "suggestfix" in options else False,
        "capture":    True if "capture" in options else False,
        "verbose":    True if "verbose" in options else False,
        "lines":      lines if "lines" in options else None
    }

    if subcommand in ["do", "code", "error"]:
        explain_(subcommand, usr_input, config, model, dofile, opts, kwargs)

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
    return


# ####### RUN MAIN FUNCTION ########
if __name__ == "__main__":
    import argparse
    argparse = argparse.ArgumentParser()
    argparse.add_argument("subcommand",         type=str, help="do, code, error, or init")
    argparse.add_argument("usr_input",              type=str, default=None)
    argparse.add_argument("model",              type=str,  default=None)
    argparse.add_argument("config",             type=str, default=None)
    argparse.add_argument("dofile",             type=str, default=None)
    argparse.add_argument("options",            type=str, default=None)
    argparse.add_argument("max_p",              type=str, default=None)
    argparse.add_argument("top_k",              type=str, default=None)
    argparse.add_argument("max_tokens",         type=str, default=None)
    argparse.add_argument("temperature",        type=str, default=None)
    argparse.add_argument("frequency_penalty",  type=str, default=None)
    argparse.add_argument("presence_penalty",   type=str, default=None)
    argparse.add_argument("stop_sequence",      type=str, default=None)
    args = argparse.parse_args()

    main(args.subcommand,
         args.usr_input,
         args.model,
         args.config,
         args.dofile,
         args.options,
         args.max_p,
         args.top_k,
         args.max_tokens,
         args.temperature,
         args.frequency_penalty,
         args.presence_penalty,
         args.stop_sequence
         )


