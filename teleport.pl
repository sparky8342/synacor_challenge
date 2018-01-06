#!/usr/bin/perl
use strict;
use warnings;

use Parallel::ForkManager;
use Memoize qw(memoize flush_cache);

memoize('fn');
my $log = defined($ARGV[0]) && $ARGV[0] eq 'log';
my $logfile = 'teleport.log';
my $codefile = 'teleport_code.txt';
my $end_value = 6;
my $processes = 4;
my $pm = Parallel::ForkManager->new($processes);
my $val;

for (my $process = 1; $process <= $processes; $process++) {
	$pm->start and next;

	for ($val = $process; $val <= 32768; $val += $processes) {

		# stop if the result was found by another child
		last if -e $codefile;

		my $result = fn(4,1);

		if ($log) {
			open my $fh, '>>', $logfile;
			print $fh "$val $result\n";
			close $fh;
		}

		# end condition, save to a file and exit
		if ($result == $end_value) {
			open my $fh, '>', $codefile;
			print $fh "$val\n";
			close $fh;
			last;
		}
		flush_cache('fn');
	}

	$pm->finish;
}

$pm->wait_all_children;

# ackermann style function from teleport check code
sub fn {
	no warnings 'recursion';

	if ($_[0] == 0) {
		return ($_[1] + 1) % 32768;
	}

	if ($_[1] == 0) {
		@_ = ($_[0] - 1, $val);
		goto &fn;
	}

	@_ = ($_[0] - 1, fn($_[0], $_[1] - 1));
	goto &fn;
}
