import sys
from builtins import open, Exception, print, len

import aisuite

def main(dofile, rewrite_flag, explain_temperature, explain_max_tokens, explain_secret):
    try:
        with open(dofile, "r") as f:
            file_lines = f.readlines()
    except Exception as e:
        print("Error reading do-file: " + str(e))
        sys.exit(1)

    # If the file is too large, print a message and exit.
    threshold = 200

    if len(file_lines) > threshold:
        print("do-file too large. Consider checking smaller chunks instead.")
        sys.exit(0)

    file_content = "".join(file_lines)

    if rewrite_flag.strip():
        prompt = f"Please rewrite the following Stata do-file for improved optimization and clarity:\n{file_content}"
    else:
        prompt = f"Please explain what the following Stata do-file achieves:\n{file_content}"

    try:
        temperature = float(explain_temperature) if explain_temperature != "" else 0.3
    except Exception:
        temperature = 0.3

    try:
        max_tokens = int(explain_max_tokens) if explain_max_tokens != "" else 250
    except Exception:
        max_tokens = 250

    api_key = explain_secret if explain_secret != "" else "YOUR_DEFAULT_API_KEY"

    aisuite.api_key = api_key

    try:
        response = aisuite.Completion.create(engine="text-davinci-003", prompt=prompt, max_tokens=max_tokens, temperature=temperature)
        explanation = response.choices[0].text.strip()
        print(explanation)
    except Exception as e:
        print("Error calling aisuite API: " + str(e))
        sys.exit(1)