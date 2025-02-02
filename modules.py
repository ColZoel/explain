import sys
import aisuite
from dotenv import load_dotenv

def read_file(dofile):  #fixme: retrieve context window size from model and use it as threshold
    try:
        with open(dofile, "r") as f:
            file_lines = f.readlines()
    except Exception as e:
        print("Error reading do-file: " + str(e))
        sys.exit(1)
    return file_lines


def call_api(model, prompt, max_tokens, temperature, api_key):
    client = aisuite.Client()


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
