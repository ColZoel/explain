{smcl}
***************************************************************************
                         EXPLAIN — LLM Assisted Explanation Tool
***************************************************************************

Version: 1.0.2
Author:   Your Name
Date:     [Insert Date]

DESCRIPTION
-----------
The EXPLAIN command is a stateful, LLM‐assisted tool that helps you
diagnose errors, understand code snippets, and even optimize or
explain entire do‐files in Stata. It leverages a Large Language Model
(e.g., OpenAI’s API) to generate human‑readable explanations and code
suggestions based on the context you provide.

The command is organized into several subcommands:

  • SET     — Configure global parameters.
  • DO      — Explain or rewrite a complete do‑file.
  • ERROR   — Explain an error (using stored error messages or a
              specified error code) and optionally provide code context.
  • CODE    — Explain a code snippet or a range of lines from a do‑file.
  • QUERY   — Display the current parameter settings.

Each subcommand has its own syntax and options as described below.

---------------------------------------------------------------------------
SYNOPSIS
---------------------------------------------------------------------------
  explain set <parameter> <value>
  explain do "path/to/do-file.do" [rewrite]
  explain error [r(errorcode)|errorcode] [, lines(<n>|<n>,<m>) | previous(<n>)] [suggestfix]
  explain code ["your code snippet"] [, lines(<n>|<n>,<m>)]
  explain query [<parameter>]

---------------------------------------------------------------------------
DETAILS
---------------------------------------------------------------------------

1. SET MODE
   ---------
   Use the set subcommand to assign or override global parameters that
   control the behavior of the LLM. These parameters include:

     • temperature: Controls the randomness of the LLM output.
                    Default is 0.3 (range: 0 to 1).
     • max_tokens:  Maximum number of tokens returned.
                    Default is 150 (model-specific; e.g., up to ~4000).
     • max_lines:   Maximum number of lines to use when extracting context
                    from a do‑file (or “.” for the entire file).
     • api:         API endpoint (e.g., //api.openai.com/v1/completions).
     • secret:      Path to a file containing your API secret key.
     • file:        Path to your primary do‑file to be used as a source of
                    code context.

   Examples:
         explain set temperature 0.6
         explain set max_tokens 200
         explain set max_lines 10
         explain set api //api.openai.com/v1/completions
         explain set secret "C:\MyProjects\api-secret.txt"
         explain set file "C:\MyProjects\analysis.do"

2. DO MODE
   --------
   Explain an entire do‑file or get a rewritten (optimized) version.

   Syntax:
         explain do "path/to/do-file.do" [rewrite]

   Options:
         rewrite   – If specified, the LLM returns a suggestion for a more
                     optimized or streamlined version of the do‑file.
   Note:
         If the do‑file is too large (e.g., more than 200 lines), a message
         is returned asking you to check smaller chunks instead.

3. ERROR MODE
   ----------
   Explain an error in your code. There are several ways to use error mode:

   a) General Error Explanation:
         If you type:
               explain error
         then EXPLAIN will check if a global error message (last_error_msg)
         is stored. If none is found, it uses the current Stata error code
         (even if _rc == 0) and asks the LLM for a general explanation.
         (After processing, last_error_msg is reset.)

   b) Specific Error Code:
         You may specify an error code explicitly:
               explain error r(198)
         or
               explain error 198
         In that case, EXPLAIN sends that code to the LLM to get an explanation.
         If the code is invalid, a message “Invalid error code.” is returned.

   c) Error with Code Context:
         You may provide context from your do‑file by specifying:
             • lines(<n>)         – to extract line n from the set do‑file.
             • lines(<n>,<m>)      – to extract lines n through m.
             • previous(<n>)       – to extract the n lines preceding the error
                                    (using a stored global last_error_line if available).

         You may also add the option “suggestfix” to have the LLM offer a
         potential correction.

   Examples:
         explain error, lines(10)
         explain error, lines(10,20) suggestfix
         explain error, previous(10)
         explain error r(198)

4. CODE MODE
   ---------
   Explain a code snippet. You can either pass a snippet directly or
   extract lines from the do‑file.

   Syntax:
         a) Direct snippet:
             explain code "sysuse auto, clear"
         b) Extracted from do‑file:
             explain code, lines(10-20)
         (You may also use a comma-separated range: lines(10,20).)

5. QUERY MODE
   ----------
   Display the current global settings in a table format similar to
   Stata’s “query memory” command. If you type:
         explain query
   a table with all parameter values is shown; if you specify a parameter:
         explain query temperature
   only that parameter’s value is displayed along with possible values.

---------------------------------------------------------------------------
EXAMPLES
---------------------------------------------------------------------------
. explain set temperature 0.6
  → Sets the temperature parameter to 0.6.

. explain set file "C:\MyProjects\analysis.do"
  → Sets the primary do‑file for context extraction.

. explain error, lines(10,20) suggestfix
  → Uses lines 10 to 20 from the set do‑file and a stored error message
     (or current _rc) to ask the LLM for an explanation plus a suggested fix.

. explain code "regress price mpg"
  → Sends the provided code snippet to the LLM for an explanation.

. explain query
  → Displays a table of all current parameter settings.

---------------------------------------------------------------------------
NOTES
---------------------------------------------------------------------------
- Before using the error or code subcommands, make sure you have set
  the necessary globals (via the SET subcommand) so that EXPLAIN knows
  which do‑file to reference and what LLM parameters to use.
- It is recommended that you wrap your Stata commands so that when an
  error occurs you capture the error message in a global (last_error_msg)
  and optionally the error line in last_error_line.
- The LLM functionality depends on having a valid API secret. Ensure that
  you have properly set the secret using the set secret command.
- This project is modular. Some subcommands (such as QUERY) may be stored
  in separate ado files (e.g., explain_query.ado) and are called by the
  main explain.ado.

---------------------------------------------------------------------------
SEE ALSO
-----------
help ado
help syntax

***************************************************************************
                         End of EXPLAIN Help File
***************************************************************************