
## MVP

Using the AI-Agent Codex with "GPT-5.6-Terra" (medium reasoning) run on Ubuntu Linux.

First version:

```text
Make the Raku package "COIN-OR" using Raku's "NativeCall" (interfacing the optimization library COIN-OR)
and libraries installed with the shell scripts in "./README.md".
Please, make the small-model example in "./examples" and make corresponding tests in "./xt".
```

In order to make it work on macOS:

```text
Make the corresponding changes to make that package also work on macOS:
- Add env variables for the variables locations the Raku package can use
- Provide corresponding instructionsions in REAME.md
``` 

---

## LP examples

```text
Work out the LP example of Google OR-Tools with Raku's "COIN-OR":
https://developers.google.com/optimization/lp/lp_example

Put the code in the file "./examples/solving-a-linear-programming-problem.raku".
```

```text
Work out the Stingler Diet example of Google OR-Tools with Raku's "COIN-OR":
https://developers.google.com/optimization/lp/stigler_diet

Put the code in the file "./examples/solving-stingler-diet.raku".
```

---

## Assignment example

```text
Work out the Assignment example of Google OR-Tools with Raku's "COIN-OR":
https://developers.google.com/optimization/assignment/assignment_example

Put the code in the file "./examples/assigment-problem.raku".
```