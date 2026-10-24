#!/usr/bin/env raku
use v6.d;
# use lib 'lib';
use COIN-OR;

# Maximize 3x + 2y, subject to x + y <= 4, x <= 2, y <= 3,
# where x and y are non-negative integers.
my $model = COIN-OR::Model.new(:name<small-model>);
$model.add-column('x', :upper(2), :objective(3), :integer);
$model.add-column('y', :upper(3), :objective(2), :integer);
$model.add-row('capacity', [0, 1], [1e0, 1e0], '<=', 4);
$model.maximize;
$model.log-level(0);

die 'CBC did not prove the model optimal' unless $model.solve;
say "objective: {$model.objective-value}";
say "x: {$model.solution[0]}, y: {$model.solution[1]}";
