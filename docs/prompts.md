
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

---

## Simplex- and Interior-point methods

```text
I want to be able to specify which linear programming method use -- Simplex or Interior Point.
Change the package code accordingly.
Change an example script "./examples/solving-stingler-diet.raku" to shows the use of method.
```

---

## Docs (in the code)

```text
For each method of the class COIN-OR::Model add usage message (or WHY) for each argument. E.g. Str:D $name, #= variable name.
```

````text
Above each method of the class COIN-OR::Model add usage message with the `#|` notation. For example:
```raku
#| Add constraint
method add(...
```
````

---

## Installation script

```text
Make an installation script in "./resources" that installs the COIN-OR libraries and the Raku package for both Linux or macOS. 
Make a separate script for Windows.
```