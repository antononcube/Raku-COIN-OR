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
constant $shared-library-file =
    $*KERNEL.name.lc eq 'darwin' ?? 'libCbcSolver.dylib' !! 'libCbcSolver.so';
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
sub Cbc_addCol(CbcModel, Str, num64, num64, num64, int8, int32, Pointer, Pointer)
    is native(&cbc-library) { * }
sub Cbc_addRow(CbcModel, Str, int32, CArray[int32], CArray[num64], int8, num64)
    is native(&cbc-library) { * }
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

sub cbc-version(--> Str) is export { Cbc_getVersion }

class Model is export {
    has CbcModel $!model;
    has Bool $!closed = False;

    submethod BUILD(:$name = '') {
        $!model = Cbc_newModel();
        die 'CBC could not create a model' unless $!model.defined;
        Cbc_setProblemName($!model, $name) if $name.chars;
    }

    method close(--> Nil) {
        return if $!closed;
        Cbc_deleteModel($!model) if $!model.defined;
        $!closed = True;
        Nil
    }

    submethod DESTROY { self.close }

    method !open(--> CbcModel) {
        die 'This COIN-OR model is closed' if $!closed;
        $!model
    }

    method add-column(
        Str:D $name,
        Real:D :$lower = 0,
        Real:D :$upper = Inf,
        Real:D :$objective = 0,
        Bool :$integer = False,
    --> Nil) {
        Cbc_addCol(self!open, $name, $lower.Num, $upper.Num, $objective.Num,
                   $integer ?? 1 !! 0, 0, Pointer, Pointer);
        Nil
    }

    method add-row(
        Str:D $name,
        Positional:D $columns,
        Positional:D $coefficients,
        Str:D $sense,
        Real:D $rhs,
    --> Nil) {
        die 'A row needs equally many column indexes and coefficients'
            unless $columns.elems == $coefficients.elems;
        my %sense = '<=' => 'L', '>=' => 'G', '=' => 'E', 'L' => 'L',
                    'G' => 'G', 'E' => 'E';
        die "Unknown row sense '$sense'; use <=, >=, or ="
            unless %sense{$sense}:exists;

        my $indices = CArray[int32].new;
        my $values = CArray[num64].new;
        for ^$columns.elems -> $i {
            $indices[$i] = $columns[$i].Int;
            $values[$i] = $coefficients[$i].Num;
        }
        Cbc_addRow(self!open, $name, $columns.elems, $indices, $values,
                   %sense{$sense}.ord, $rhs.Num);
        Nil
    }

    method minimize(--> Nil) { Cbc_setObjSense(self!open, 1e0); Nil }
    method maximize(--> Nil) { Cbc_setObjSense(self!open, -1e0); Nil }
    method log-level(Int:D $level --> Nil) {
        Cbc_setLogLevel(self!open, $level); Nil
    }

    method solve(--> Bool:D) { Cbc_solve(self!open); so Cbc_isProvenOptimal($!model) }
    method optimal(--> Bool:D) { so Cbc_isProvenOptimal(self!open) }
    method infeasible(--> Bool:D) { so Cbc_isProvenInfeasible(self!open) }
    method status(--> Int:D) { Cbc_status(self!open) }
    method objective-value(--> Num:D) { Cbc_getObjValue(self!open) }
    method columns(--> Int:D) { Cbc_getNumCols(self!open) }
    method rows(--> Int:D) { Cbc_getNumRows(self!open) }

    method solution(--> Array:D) {
        my $count = self.columns;
        return [] unless $count;
        my $pointer = Cbc_getColSolution(self!open);
        return [] unless $pointer;
        my $values = nativecast(CArray[num64], $pointer);
        [$values[^$count].map(*.Num)]
    }
}
