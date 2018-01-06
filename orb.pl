#!/usr/bin/perl
use strict;
use warnings;

my @grid = (
	[qw/ * 8  -  1/],   
	[qw/ 4 * 11  */],
	[qw/ + 4  - 18/],
	[qw/22 -  9  */]
);

my %start = ( x => 0, y => 3 ); 
my %end   = ( x => 3, y => 0 );
my $goal  = 30;

my @dirs = (
	{ x =>  0, y =>  1 },
	{ x =>  0, y => -1 },
	{ x =>  1, y =>  0 },
	{ x => -1, y =>  0 }
);

# recursively search all paths through
# the grid up to a max depth
search(\%start);

sub search {
	my ($loc,$path,$depth) = @_;

	$depth = 0 unless $depth;
	if ($depth > 12) {
		return;
	}

	$path .= $grid[$loc->{y}][$loc->{x}] . ' ';

	# add brackets to ensure left to right evaluation
	if ($grid[$loc->{y}][$loc->{x}] =~ /^\d+$/) {
		$path = '(' . $path . ')';
	}

	if ($loc->{x} == $end{x} && $loc->{y} == $end{y}) {
		# got to the end square
		# to check the result, we can just
		# eval the path and compare with the
		# goal number
		my $x;
		my $exp = '$x = ' . $path;
		eval "$exp";
		if ($x == $goal) {
			# found a valid path
			# remove the brackets for nicer output
			$path =~ s/[\(\)]//g;
			print "$path\n";
		}
		return;
	}

	# search in all 4 directions where valid
	foreach my $dir (@dirs) {
		my $newloc = {
			x => $loc->{x} + $dir->{x},
			y => $loc->{y} + $dir->{y}
		};
	
		# can't go back to start
		next if ($newloc->{x} == $start{x} && $newloc->{y} == $start{y});

		# or outside the map
		next if $newloc->{x} < 0 || $newloc->{x} > 3 || $newloc->{y} < 0 || $newloc->{y} > 3;

		search($newloc,$path,$depth+1);
	}
}
