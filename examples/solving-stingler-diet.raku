#!/usr/bin/env raku
use v6.d;
# use lib 'lib';
use COIN-OR;

# Stigler diet LP, using the foods that define the optimum in the
# Google OR-Tools data set. Values are nutrients delivered per 1939 dollar.
my @requirements = 3, 70, .8, 12, 5, 1.8, 2.7, 18, 75;
my @names = 'Corn Meal', 'Cabbage', 'Spinach', 'Navy Beans, Dried';
my @values =
    [36,897,1.7,99,30.9,17.4,7.9,106,0],
    [2.6,125,4,36,7.2,9,4.5,26,5369],
    [1.1,106,0,138,918.4,5.7,13.8,33,2755],
    [26.9,1691,11.4,792,0,38.4,24.6,217,0];

my $model = Model.new(:name<stigler-diet>);
for @names -> $name { $model.add-column($name, :objective(1)) }
for @requirements.kv -> $nutrient, $minimum {
    $model.add-row("nutrient-$nutrient", ^@names.elems,
        @values.map({ $_[$nutrient] }), '>=', $minimum);
}
$model.minimize;
$model.log-level(0);

say "Number of variables = {$model.columns}";
say "Number of constraints = {$model.rows}";
die 'The diet model does not have an optimal solution' unless $model.solve;

my @solution = $model.solution;
say "\nAnnual Foods:";
for @names.kv -> $i, $name {
    next unless @solution[$i] > 1e-8;
    say "$name: \${(365 * @solution[$i]).fmt('%.4f')}";
}
say "\nOptimal annual price: \${(365 * $model.objective-value).fmt('%.4f')}";
