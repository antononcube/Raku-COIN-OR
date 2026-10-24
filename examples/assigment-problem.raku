#!/usr/bin/env raku
use v6.d;
# use lib 'lib';
use COIN-OR;

# Google OR-Tools assignment example, modeled as a CBC binary MIP.
my @costs =
    [90, 80, 75, 70],
    [35, 85, 55, 65],
    [125, 95, 90, 95],
    [45, 110, 95, 115],
    [50, 100, 90, 100];
my $workers = @costs.elems;
my $tasks = @costs[0].elems;

my $model = COIN-OR::Model.new(:name<assignment-problem>);
for ^$workers -> $worker {
    for ^$tasks -> $task {
        $model.add-column("worker-{$worker}-task-{$task}",
            :upper(1), :objective(@costs[$worker][$task]), :integer);
    }
}

# A worker performs at most one task.
for ^$workers -> $worker {
    my @columns = (^$tasks).map({ $worker * $tasks + $_ });
    $model.add-row("worker-{$worker}", @columns, [1e0 xx $tasks], '<=', 1);
}

# Every task is assigned exactly once.
for ^$tasks -> $task {
    my @columns = (^$workers).map({ $_ * $tasks + $task });
    $model.add-row("task-{$task}", @columns, [1e0 xx $workers], '=', 1);
}

$model.minimize;
$model.log-level(0);
die 'No optimal assignment was found' unless $model.solve;

say "Total cost = {$model.objective-value.fmt('%.1f')}\n";
my @solution = $model.solution;
for ^$workers -> $worker {
    for ^$tasks -> $task {
        next unless @solution[$worker * $tasks + $task] > .5;
        say "Worker {$worker} assigned to task {$task}. Cost = {@costs[$worker][$task]}";
    }
}
