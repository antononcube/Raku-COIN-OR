use v6.d;
unit module COIN-OR;

=begin pod

=head1 NAME

COIN::OR - NativeCall bindings for the COIN-OR CBC mixed-integer solver

=head1 SYNOPSIS

    use COIN::OR;

    my $model = Model.new(:name<example>);
    $model.add-column('x', :lower(0), :upper(2), :objective(3), :integer);
    $model.add-column('y', :lower(0), :upper(3), :objective(2), :integer);
    $model.add-row('capacity', [0, 1], [1e0, 1e0], '<=', 4);
    $model.maximize;
    $model.solve or die 'CBC did not find an optimal solution';
    say $model.objective-value;       # 10
    say $model.solution;              # [2e0, 2e0]

=head1 DESCRIPTION

This module uses CBC's supported C interface from C<libCbcSolver>. Install the
CBC development package described in this distribution's F<README.md> before
using it.

=end pod

use NativeCall;

# NativeCall resolves the ordinary library name on Linux distributions. On
# macOS, where Homebrew's prefix is architecture-dependent, callers can
# provide either the full dylib path or its containing directory.
constant $shared-library-file = do given $*KERNEL.name.lc {
    when 'darwin' { 'libCbcSolver.dylib' }
    when /win/   { 'libCbcSolver-3.dll' }
    default      { 'libCbcSolver.so' }
};
sub cbc-library(--> Str) is export {
    %*ENV<COIN_OR_CBC_LIBRARY>
    // (%*ENV<COIN_OR_LIBRARY_DIR>:exists
        ?? "%*ENV<COIN_OR_LIBRARY_DIR>/$shared-library-file"
        !! $shared-library-file)
}

class CbcModel is repr('CPointer') { }

sub Cbc_getVersion(--> Str) is native(&cbc-library) { * }
sub Cbc_newModel(--> CbcModel) is native(&cbc-library) { * }
sub Cbc_deleteModel(CbcModel) is native(&cbc-library) { * }
sub Cbc_setProblemName(CbcModel, Str --> int32) is native(&cbc-library) { * }
sub Cbc_addCol(CbcModel, Str, num64, num64, num64, int8, int32, Pointer, Pointer) is native(&cbc-library) { * }
sub Cbc_addRow(CbcModel, Str, int32, CArray[int32], CArray[num64], int8, num64) is native(&cbc-library) { * }
sub Cbc_setObjSense(CbcModel, num64) is native(&cbc-library) { * }
sub Cbc_solve(CbcModel --> int32) is native(&cbc-library) { * }
sub Cbc_isProvenOptimal(CbcModel --> int32) is native(&cbc-library) { * }
sub Cbc_isProvenInfeasible(CbcModel --> int32) is native(&cbc-library) { * }
sub Cbc_status(CbcModel --> int32) is native(&cbc-library) { * }
sub Cbc_getObjValue(CbcModel --> num64) is native(&cbc-library) { * }
sub Cbc_getNumCols(CbcModel --> int32) is native(&cbc-library) { * }
sub Cbc_getNumRows(CbcModel --> int32) is native(&cbc-library) { * }
sub Cbc_getColSolution(CbcModel --> Pointer) is native(&cbc-library) { * }
sub Cbc_setLogLevel(CbcModel, int32) is native(&cbc-library) { * }
sub Cbc_setParameter(CbcModel, Str, Str) is native(&cbc-library) { * }
sub Cbc_setAllowableGap(CbcModel, num64) is native(&cbc-library) { * }
sub Cbc_setAllowableFractionGap(CbcModel, num64) is native(&cbc-library) { * }
sub Cbc_setAllowablePercentageGap(CbcModel, num64) is native(&cbc-library) { * }

sub cbc-version(--> Str) is export { Cbc_getVersion }

class Model is export {
    has CbcModel $!model;
    has Bool $!closed = False;

    #| Create a new empty CBC optimization model.
    submethod BUILD(
        :$name = '', #= Optional descriptive name assigned to the CBC problem.
    ) {
        $!model = Cbc_newModel();
        die 'CBC could not create a model' unless $!model.defined;
        Cbc_setProblemName($!model, $name) if $name.chars;
    }

    #| Release the native CBC model. Calling this more than once is safe.
    method close(--> Nil) {
        return if $!closed;
        Cbc_deleteModel($!model) if $!model.defined;
        $!closed = True;
        Nil
    }

    #| Release the native model automatically when this Raku object is collected.
    submethod DESTROY { self.close }

    #| Return the native model, or fail if the model has been closed.
    method !open(--> CbcModel) {
        die 'This COIN-OR model is closed' if $!closed;
        $!model
    }

    #| Add a decision variable to the model.
    method add-column(
        Str:D $name,            #= Unique name of the decision variable.
        Real:D :$lower = 0,     #= Inclusive lower bound for the variable; defaults to zero.
        Real:D :$upper = Inf,   #= Inclusive upper bound for the variable; defaults to positive infinity.
        Real:D :$objective = 0, #= Coefficient of the variable in the objective function.
        Bool :$integer = False, #= When true, restrict the variable to integral values.
    --> Nil) {
        Cbc_addCol(self!open, $name, $lower.Num, $upper.Num, $objective.Num,
                   $integer ?? 1 !! 0, 0, Pointer, Pointer);
        Nil
    }

    #| Add a named linear constraint involving existing decision variables.
    method add-row(
        Str:D $name,                #= Unique name of the linear constraint.
        Positional:D $columns,      #= Zero-based indexes of the variables participating in the constraint.
        Positional:D $coefficients, #= Coefficients corresponding position-for-position to C<$columns>.
        Str:D $sense,               #= Constraint relation: C<< <= >>, C<< >= >>, C<=>, C<L>, C<G>, or C<E>.
        Real:D $rhs,                #= Right-hand-side value of the constraint.
    --> Nil) {

        die 'A row needs equally many column indexes and coefficients'
        unless $columns.elems == $coefficients.elems;

        my %sense = '<=' => 'L', '>=' => 'G', '=' => 'E', 'L' => 'L', 'G' => 'G', 'E' => 'E';
        die "Unknown row sense '$sense'; use <=, >=, or ="
        unless %sense{$sense}:exists;

        my $indices = CArray[int32].new;
        my $values = CArray[num64].new;
        for ^$columns.elems -> $i {
            $indices[$i] = $columns[$i].Int;
            $values[$i] = $coefficients[$i].Num;
        }

        Cbc_addRow(self!open, $name, $columns.elems, $indices, $values, %sense{$sense}.ord, $rhs.Num);
        Nil
    }

    #| Set the objective direction to minimization.
    method minimize(--> Nil) { Cbc_setObjSense(self!open, 1e0); Nil }

    #| Set the objective direction to maximization.
    method maximize(--> Nil) { Cbc_setObjSense(self!open, -1e0); Nil }

    #| Set CBC's solver-output verbosity.
    method log-level(
        Int:D $level, #= CBC verbosity level; zero suppresses solver log output.
    --> Nil) { Cbc_setLogLevel(self!open, $level); Nil }

    #| Select the LP algorithm used when solving the model.
    method lp-method(
    #= LP algorithm: C<simplex>, C<dual-simplex>, or C<interior-point>.
            Str:D $method
            --> Nil) {
        my %cbc-action =
                'simplex' => 'primalSimplex',
                'dual-simplex' => 'dualSimplex',
                'interior-point' => 'barrier';
        die "Unknown LP method '$method'; use simplex, dual-simplex, or interior-point"
        unless %cbc-action{$method}:exists;
        Cbc_setParameter(self!open, %cbc-action{$method}, '');
        Nil
    }

    #| Set the primal-feasibility tolerance used by the LP solver.
    method primal-tolerance(
        #= Maximum permitted primal constraint violation; must be positive.
        Real:D $value
    --> Nil) {
        die 'Primal tolerance must be positive' unless $value > 0;
        Cbc_setParameter(self!open, 'primalTolerance', $value.Num.Str);
        Nil
    }

    #| Set the dual-feasibility tolerance used by the LP solver.
    method dual-tolerance(
        #= Maximum permitted dual infeasibility; must be positive.
        Real:D $value
    --> Nil) {
        die 'Dual tolerance must be positive' unless $value > 0;
        Cbc_setParameter(self!open, 'dualTolerance', $value.Num.Str);
        Nil
    }

    #| Set how close a MIP variable must be to an integer to be integral.
    method integer-tolerance(
        #= Maximum distance from an integer value; must be positive.
        Real:D $value
    --> Nil) {
        die 'Integer tolerance must be positive' unless $value > 0;
        Cbc_setParameter(self!open, 'integerTolerance', $value.Num.Str);
        Nil
    }

    #| Set the absolute MIP optimality gap at which CBC may stop.
    method allowable-gap(
        #= Absolute difference permitted between the incumbent and best bound.
        Real:D $value
    --> Nil) {
        die 'Allowable gap cannot be negative' if $value < 0;
        Cbc_setAllowableGap(self!open, $value.Num);
        Nil
    }

    #| Set the fractional MIP optimality gap at which CBC may stop.
    method allowable-fraction-gap(
        #= Fractional difference permitted between the incumbent and best bound.
        Real:D $value
    --> Nil) {
        die 'Allowable fraction gap cannot be negative' if $value < 0;
        Cbc_setAllowableFractionGap(self!open, $value.Num);
        Nil
    }

    #| Set the percentage MIP optimality gap at which CBC may stop.
    method allowable-percentage-gap(
        #= Percentage difference permitted between the incumbent and best bound.
        Real:D $value
    --> Nil) {
        die 'Allowable percentage gap cannot be negative' if $value < 0;
        Cbc_setAllowablePercentageGap(self!open, $value.Num);
        Nil
    }

    #| Solve the model and return whether CBC proved the solution optimal.
    method solve(--> Bool:D) { Cbc_solve(self!open); so Cbc_isProvenOptimal($!model) }

    #| Return whether CBC has proved an optimal solution.
    method optimal(--> Bool:D) { so Cbc_isProvenOptimal(self!open) }

    #| Return whether CBC has proved the model infeasible.
    method infeasible(--> Bool:D) { so Cbc_isProvenInfeasible(self!open) }

    #| Return CBC's numeric solve-status code.
    method status(--> Int:D) { Cbc_status(self!open) }

    #| Return the objective value of the best solution found.
    method objective-value(--> Num:D) { Cbc_getObjValue(self!open) }

    #| Return the current number of decision variables.
    method columns(--> Int:D) { Cbc_getNumCols(self!open) }

    #| Return the current number of linear constraints.
    method rows(--> Int:D) { Cbc_getNumRows(self!open) }

    #| Return solution values in decision-variable insertion order.
    method solution(--> Array:D) {
        my $count = self.columns;
        return [] unless $count;
        my $pointer = Cbc_getColSolution(self!open);
        return [] unless $pointer;
        my $values = nativecast(CArray[num64], $pointer);
        [$values[^$count].map(*.Num)]
    }
}
