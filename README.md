# Raku-COIN-OR

Raku interface to the COIN-OR numerical optimization solver.

The initial API wraps CBC's portable C interface through Raku C<NativeCall>.
It supports constructing and solving linear mixed-integer models; see
F<examples/small-model.raku>.

---

## Installation

### maxOS

```
#!/bin/bash

# Ensure Homebrew is up to date
brew update

# Install all 4 core COIN-OR packages
brew install coinutils clp cbc ipopt

# Verify installations
echo -e "\n--- Verification ---"
for cmd in cbc clp ipopt; do
  if command -v $cmd &> /dev/null; then
    echo "✅ $cmd installed: $($cmd --version 2>&1 | head -n 1)"
  else
    echo "❌ $cmd failed to install"
  fi
done
```

### Ubuntu Linux 

```
sudo apt update
# Install CBC (Mixed-Integer Linear Programming Solver)
sudo apt install coinor-cbc coinor-libcbc-dev

# Install CLP (Linear Programming Solver)
sudo apt install coinor-clp coinor-libclp-dev

# Install Ipopt (Nonlinear Programming Solver)
sudo apt install coinor-ipopt coinor-libipopt-dev
```

## Quick start

After installing CBC, run the example from the distribution root:

```sh
raku -Ilib examples/small-model.raku
```

Run the integration test with:

```sh
raku -Ilib xt/01-small-model.rakutest
```
