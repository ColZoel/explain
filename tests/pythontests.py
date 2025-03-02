from ado.explain.explain_modules import *
import pytest


def test_build_prompt():
    prompt = "This is a test prompt."
    assert build_prompt(prompt) == [
        {"role": "system",
         "content": "You are an expert in the Stata statistical program. Your task is to answer questions about Stata code."
                    "Respond as succinctly and briefly as possible. Prefer to use bullets if appropriate."
                    "Do not lie. Do not make-up information. If you do not know the answer, say so."
                    "You are speaking to your peers. Your response must be professional yet comfortable in tone."
         },
        {"role": "user",
         "content": "This is a test prompt."
         }
    ]


def test_linenums():

    options = "capture verbose lines: 1-10"
    assert linenums(options) == "1-10"

    options = "capture verbose"
    assert linenums(options) is None

    options = "capture verbose lines:"
    assert linenums(options) is None

    options = "capture verbose lines: 1"
    assert linenums(options) == "1"

    options = "capture verbose lines: 1-"
    assert linenums(options) == "1-"


def test_read_file():
    dofile = "tests/testfile.txt"
    lines = None
    assert read_file(dofile, lines) == ['This is a test file.\n']

    dofile = "tests/testfile.txt"
    lines = "1-1"
    assert read_file(dofile, lines) == ['This is a test file.\n']

    dofile = "tests/testfile.txt"
    lines = "1-2"
    assert read_file(dofile, lines) == ['This is a test file.\n', 'This is a test file.\n']

