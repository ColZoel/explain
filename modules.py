import sys
import aisuite


def read_file(dofile):  #fixme: retrieve context window size from model and use it as threshold
    try:
        with open(dofile, "r") as f:
            file_lines = f.readlines()
    except Exception as e:
        print("Error reading do-file: " + str(e))
        sys.exit(1)
    return "".join(file_lines)


def read_config(config_file):
    try:
        with open(config_file, "r") as f:
            config = f.readlines()
    except Exception as e:
        print("Error reading config file: " + str(e))
        sys.exit(1)
    return config


def call_api(api_config, model, prompt, max_tokens, temperature):
    client = aisuite.Client(api_config)

    try:
        response = client.chat.completion.create(engine=model,
                                                 prompt=prompt,
                                                 max_tokens=max_tokens,
                                                 temperature=temperature)
        explanation = response.choices[0].text.strip()
        print(explanation)
    except Exception as e:
        print("Error calling aisuite API: " + str(e))
        sys.exit(1)
