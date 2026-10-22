# Raku-COIN-OR

Raku interface to the COIN-OR numerical optimization solver.

The initial API wraps CBC's portable C interface through Raku `NativeCall`.
It supports constructing and solving linear mixed-integer models; see
F<examples/small-model.raku>.

---

## Installation

### macOS

```sh
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

Homebrew installs formulae below an architecture-dependent prefix (normally
`/opt/homebrew` on Apple Silicon and `/usr/local` on Intel). Configure the
binding with either of these optional environment variables before running
Raku:

```sh
# Recommended: ask Homebrew for the exact CBC C-interface library.
export COIN_OR_CBC_LIBRARY="$(brew --prefix cbc)/lib/libCbcSolver.dylib"

# Alternative: provide the containing directory; the package chooses
# libCbcSolver.dylib on macOS (and libCbcSolver.so on Linux).
export COIN_OR_LIBRARY_DIR="$(brew --prefix cbc)/lib"
```

`COIN_OR_CBC_LIBRARY` takes precedence over `COIN_OR_LIBRARY_DIR`. Neither is
needed on a system where the dynamic linker can already locate `libCbcSolver`.
For a persistent macOS configuration, add the preferred `export` line to
`~/.zprofile` (zsh's login-shell configuration) and start a new terminal.

### Ubuntu Linux

```sh
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
