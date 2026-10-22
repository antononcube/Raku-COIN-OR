#!/usr/bin/env raku
use v6.d;
use lib 'lib';
use COIN-OR;

# Google OR-Tools LP example, solved with CBC through COIN-OR:
#
# maximize 3x + 4y
# subject to
#   x + 2y <= 14
#   3x - y  >= 0
#   x - y   <= 2
#   x, y >= 0
#
# No :integer argument is given, so x and y are continuous variables.
my $model = Model.new(:name<google-or-tools-lp-example>);
$model.add-column('x', :objective(3));
$model.add-column('y', :objective(4));

$model.add-row('constraint0', [0, 1], [1e0, 2e0], '<=', 14);
$model.add-row('constraint1', [0, 1], [3e0, -1e0], '>=', 0);
$model.add-row('constraint2', [0, 1], [1e0, -1e0], '<=', 2);
$model.maximize;
$model.log-level(0);

say "Number of variables = {$model.columns}";
say "Number of constraints = {$model.rows}";
die 'The problem does not have an optimal solution' unless $model.solve;

my ($x, $y) = $model.solution;
say 'Solution:';
say "Objective value = {$model.objective-value.fmt('%.1f')}";
say "x = {$x.fmt('%.1f')}";
say "y = {$y.fmt('%.1f')}";
