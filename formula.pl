#!/usr/bin/perl
use strict;
use warnings;

use Algorithm::Combinatorics qw(permutations);

my @nums = qw/2 3 5 7 9/;

my $iter = permutations(\@nums);
while (my $p = $iter->next) {
	my $r = $p->[0] + $p->[1] * $p->[2] ** 2 + $p->[3] ** 3 - $p->[4];
	if ($r == 399) {
		print join(',',@$p) . "\n";
		exit;
	}
}
