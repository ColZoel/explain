** LLM Response Test
** This is a small file to help ensure the LLM can read and understand its context

sysuse auto, clear
summarize price mpg af
scatter price mpg
regress price mpg ard
predict residuals, residuals 