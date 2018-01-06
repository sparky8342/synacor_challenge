#!/usr/bin/perl
use strict;
use warnings;

my @op_names = qw/halt set push pop eq gt jmp jt jf add mul mod and or not rmem wmem call ret out read noop/;
my @op_args = (0,2,1,1,3,3,1,2,2,3,3,3,3,3,2,2,2,1,0,1,1,0);

# memory, registers, stack and code position
my @memory;
my @registers = (0,0,0,0,0,0,0,0);
my @stack;
my $pos = 0;

# used to detect custom commands
my @input_buffer;

my $debug = 0; # debug mode switch

my @ops = (
	sub { exit                                                             }, # halt
	sub { set_register($_[0],read_num($_[1]))                              }, # set
	sub { push @stack, read_num($_[0])                                     }, # push
	sub { set_register($_[0], pop @stack)                                  }, # pop
	sub { set_register($_[0], read_num($_[1]) == read_num($_[2]) ? 1 : 0)  }, # eq
	sub { set_register($_[0], read_num($_[1])  > read_num($_[2]) ? 1 : 0)  }, # gt
	sub { $pos = read_num($_[0])                                           }, # jmp
	sub { $pos = read_num($_[1]) if (read_num($_[0]) != 0)                 }, # jt
	sub { $pos = read_num($_[1]) if (read_num($_[0]) == 0)                 }, # jf
	sub { set_register($_[0], (read_num($_[1]) + read_num($_[2])) % 32768) }, # add
	sub { set_register($_[0], (read_num($_[1]) * read_num($_[2])) % 32768) }, # mul
	sub { set_register($_[0], (read_num($_[1]) % read_num($_[2])) % 32768) }, # mod
	sub { set_register($_[0], (read_num($_[1]) & read_num($_[2])))         }, # and
	sub { set_register($_[0], (read_num($_[1]) | read_num($_[2])))         }, # or
	sub { set_register($_[0], ~read_num($_[1]) & ((1 << 15) -1))           }, # not
	sub { set_register($_[0], read_num($memory[read_num($_[1])]))          }, # rmem
	sub { $memory[read_num($_[0])] = read_num($_[1])                       }, # wmem
	sub { push @stack, $pos; $pos = read_num($_[0])                        }, # call
	sub { $pos = pop @stack                                                }, # ret
	sub { print chr(read_num($_[0]))                                       }, # out
	sub { &read_in(@_)                                                     }, # read
	sub {                                                                  }  # noop
);

# custom commands
my %commands = (
	dump  => sub { &dump_mem; print "Memory dumped to memory.dump\n\n" },
	debug => sub { $debug = $debug == 1 ? 0 : 1; print "Debug " . ($debug == 1 ? 'on' : 'off') . "\n\n" },
	teleporthack => sub {
		if (!-e 'teleport_code.txt') {
			print "You attempt to hack the teleport but you don't have the piece of paper with the correct code!\n\n";
			return;
		}

		# set register 8 to the code
		open my $fh, '<', 'teleport_code.txt';
		my $code = <$fh>;
		close $fh;
		chomp($fh);
		$registers[7] = $code;

		# skip call of long function and test of its result
		# the message about a 1 billion year check isnt skipped though
		$memory[5489] = 21; # noop
		$memory[5490] = 21; # noop
		$memory[5491] = 1;  # set command
		$memory[5493] = 1;  # value 1
		$memory[5494] = 21; # noop

		print "You hack into the teleporter and manage to edit the program currently running!\n\n";
	},
	quit  => sub { exit }
);

sub read_in {
	my ($reg) = @_;

	# buffer input to detect custom commands
	while (@input_buffer == 0) {

		# read in command
		my $char;
		read(STDIN,$char,1);
		while ($char ne "\n") {
			push @input_buffer,$char;
			read(STDIN,$char,1);
		}

		# custom commands
		my $command = join('',@input_buffer);

		if (exists($commands{$command})) {
			# run command, don't send it to the vm program
			$commands{$command}->();
			@input_buffer = ();
			print "What do you do?\n";
		}
		else {
			push @input_buffer, "\n";
		}
	}

	set_register($reg,ord(shift @input_buffer));
	return;
}

my $file = $ARGV[0];
read_program($file);

while (1) {
	# end of program
	if ($pos == @memory) {
		last;
	}

	my $currentpos = $pos;

	# operator
	my $op = $memory[$pos];

	# arguments
	my @args = ();

	for (1..$op_args[$op]) {
		$pos++;
		push @args, $memory[$pos];
	}

	# place pointer at next instruction
	$pos++;

	if ($debug) {
		my $fh;
		open $fh, '>>', 'debug.log';
		print $fh join(',',@registers) . "| ";
		print $fh "$currentpos " . $op_names[$op] . " " . join(' ',@args) . "\n";
		close $fh;
	}

	$ops[$op]->(@args);
}

sub set_register {
	my ($register,$value) = @_;

	if ($register >= 32768 && $register <= 32775) {
		$registers[$register-32768] = $value;
	}
	else {
		exit 0;
	}
}

sub read_num {
	my ($n) = @_;

	# invalid

	if ($n > 32775) {
		exit 0;
	}

	# read register if needed

	if ($n >= 32768) {
		$n = $registers[$n-32768];
	}

	return $n;
}

sub read_program {
	my ($file) = @_;
	my $fh;
	open $fh, '<', $file;
	binmode $fh;

	while (read($fh, my $pair, 2)) {
		push @memory,unpack('S<',$pair);
	}

	close $fh;
}

sub dump_mem {
	my $fh;
	open $fh, '>', 'memory.dump';

	my $pos = 0;

	while ($pos < @memory) {
		my $mempos = $pos;
		my $op = $memory[$pos];

		my @args;
		if ($op >= 0 && $op <= 21) {
			for (1..$op_args[$op]) {
				$pos++;
				push @args, $memory[$pos];
			}
		}
		$pos++;

		print $fh $mempos . ' ' . ($op_names[$op] // $op) . ' ' . join(' ',@args) . "\n";
	}

	close $fh;
}
