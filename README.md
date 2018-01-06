# Synacor Challenge

Here is my code used to solve the synacor challenge, which is here: https://challenge.synacor.com/.
This is highly recommended and can be done in any language of your choice.



## SPOILERS FOLLOW
```
 |
 |
 |
 |
 |
 |
 |
 |
 |
 |
\|/
```

The overall goal is to find 8 codes.

Initially you are provided with a binary file containing a program and a description of the computer that could run it. Your first task is to create a virtual machine that can execute the program successfully.

**CODE 1**: In the architecture description.

A very good description of the architecture is provided to work with. I found this was easy enough to do, but then had problems with the number format and making sure it was used correctly. The program itself runs many self tests and will tell you if something is wrong, e.g. 'mul not implemented', to the best of its ability. Of course if something is drastically wrong it won't run at all, or just crash randomly.

Run the code with:
```
./vm.pl challenge.bin
```

**CODE 2**: Given at start of the program's run.

**CODE 3**: Given when it passes its self tests.

Once the vm emulation is working, the program runs and you arrive at the beginning of an old-school text adventure game. Excellent, the hard part is done, now I just have to play the game (right?).

**CODE 4**: From the first object you find.

Going into the game some more, you encounter a maze of twisty passages and get eaten by a grue!

**CODE 5**: Seen on the wall in one of the twisty passages. 

The Twisty Passage maze loops and repeats itself, so some graph paper comes to the rescue to find the correct path. The correct way is dark (and you get eaten) so you have to find a lamp, some oil and light the way.

At this point I was restarting the game every time which was annoying, so I thought about implementing a save/load system. I started this, but instead just created a script with all the game commands that I can use when launching the game. So on each launch, all the correct commands I know so far will play through. It would also have required custom parsing of the input, at the time I didn't know I'd need this anyway!

I set up a script called 'run' like this:
```
cat play.txt | ./vm.pl challenge.bin
```

Which worked, but then I couldn't input anything from the keyboard as the only input from the program was from the cat command.
Some digging around and I found you can do this instead:
```
cat play.txt - | ./vm.pl challenge.bin
```
Where cat will output play.txt and then STDIN (-) to the pipe.
It didn't take long to run through all the commands for each restart, so I never used a proper save/load system.

Getting past the maze puzzle, you arrive in an area with coins of different values and a mathematical formula to solve:
```
_ + _ * _^2 + _^3 - _ = 399
```

I used brute force to solve this one:
```
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
```

Then you find a teleporter and use it.

**CODE 6**: Seen in the stream of time and space.

Awesome, 6/8 codes done. It can't be much harder can it?


## *THE TELEPORTER PROBLEM*

Arriving at synacor headquarters, you find a book with instructions on how to use the teleporter to get to the next destination.
The instructions tell you that register 8 controls the teleporter destination. 0 is the default, where you are. The next destination has to be discovered. Further, an algorithm is used to check the destination which would take far too long to actually run.

So, at this point I can see that this is no longer just playing through the game, but also hacking the registers/code inside the vm.

Initially I just tried setting register 8 to 1000 to see what would happen.
This happens when using the teleporter:
	"Unusual setting detected!  Starting confirmation process!  Estimated time to completion: 1 billion years."

And then the program hangs.

Was it just doing an extremely long loop?
Here's where I realised I'd need to dump out the program, and also the running registers and instructions when it got to this process.

I changed the 'read' instruction to be able to take custom commands. This was done by reading input in the vm itself, and only passing it to the running code if it was a regular command. The custom ones ran their own subroutines instead. I added a command to dump the entire program out, and one to switch debugging on or off. Debugging mode is similar to the memory dump, but dumps the registers and the current instruction.

I also dumped out the program as characters to see all the text inside (this part is no longer in the final version). This was with the naive thought that I could just see all the codes. No such luck! The codes are generated in some way in the program itself.

After doing this and trying the teleporter again, it was clear that it wasn't just a dummy loop of some sort but an actual calculation that was taking place.

This is where I was stuck for some time, and ended up looking at some other solutions on github to try and understand what was happening.

During this I worked out how to skip past the check by changing some instructions to noops. This works, and gets you to the next destination along with showing you code 7! However, on trying this on the website and getting an error, it was clear that the correct teleport number is needed to get the correct code as well.

From some other solutions, I could see that the code was similar to the Ackermann function: https://en.wikipedia.org/wiki/Ackermann_function.
This is a devious recursive function that will take a very long time to run once the inputs are a certain size. It can't be easily changed to an iterative version, because it is not primitive recursion.

Setting up a program to run this and try and find the correct input is easy enough, but was obvious that it would be far too slow.
My initial attempt was like this:
```
sub fn {
	my ($m,$n,$val) = @_;

	if ($m == 0) {
		return ($n + 1);
	}

	if ($n == 0) {
		return fn($m - 1, $val, $val);
	}

	return fn($m - 1, fn($m, $n - 1, $val), $val);
}
```
I tried a C version which was better for the first few values, and then crashed because the stack was full. Not knowing much about C, I didn't continue with that. I wanted to do the whole challenge with perl if possible, anyway.

Eventually I came up with a more efficient way.
```
memoize('fn');

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
```
(The full program is in the repository).
The first optimisation is to use Memoize to cache calls to the function with the same inputs. This is also why $val is global and not an input, to save storing that in the cache. The cache is flushed after each value is tested.

Next, the big one: use tail call recursion. This is a new thing I learnt whilst doing this challenge.
If you are returning with a call to the same function like this:

```
return fn($x);
```

This creates a stack frame for the new call, with the inital caller waiting for the call to return just to return the value itself. This ends up with a chain of return calls on the stack, e.g.:

```
return fn(1) {
	# do stuff
	return fn(2)
		# do stuff
		return fn(3)
			etc
```

Some languages (like Haskell) will optimise these calls with tail recursion. This means that instead of putting a new call on the stack and waiting for it, the code just starts executing the new function call. It replaces the current calling code. See https://en.wikipedia.org/wiki/Tail_call for a better explanation!

Perl doesn't do this, but the 'goto' function makes this possible. So goto actually has a use beyond `10 PRINT "HELLO" 20 GOTO 10`.

If you set @_ to the input for the next call and call 'goto &(subroutine)', the same effect happens with the current running subroutine being replaced by the call to the next one.

The other main optimisation was to use the @_ array directly instead of copying the values into $m and $n. It's ugly, but saves a lot of values being copied.

And of course using % 32768 on the return values as our vm operates in mod 32768.

This now ran in a not-unreasonable amount of time, with forking added. It took a few hours to get the final result.

So, the last step was to update the vm to set register 8 to the correct value in the 'teleporter hack'.

**CODE 7**: In the sand after using the teleporter with the correct code.

## Orb Puzzle

Now, in the next area is an orb with some instructions on how to solve the next puzzle.
You have to carry the orb through a series of rooms which alternate between numbers and mathematical operators. The orbs value is altered as you walk along. If you arrive at the door with the correct value (30), it will open.

The map looks like this:
```
*  8  -  1
4  * 11  *
+  4  - 18
22 -  9  *
```
You start in the bottom left with the orb at 22, and need to arrive at the top right with it set to 30.
For example, if you go east, east, north, north, east, north, the value will be:
```
22 - 9 - 11 * 1 = 2 
```
I wrote a recursive search to try all the possible paths out. Initially it wouldn't visit the same space more than once. This was the wrong approach, so I tried again where it could re-visit spaces.

I got a path that finished with 30, and added it to the vm script. This failed, because of revisiting the start location which causes the orb to disappear. I read the instructions a bit closer, and removed the possibilty of visiting the start location again.

Now I got several results and tried the first one in the script again. This time the path was too long and the orb disappears at the end.
I reduced the possible search depth and now I only had one possible path. This worked and lead me to the final room with a mirror in it.

**CODE 8**: Written on your head, seen in the mirror!

The final trick is to reverse code 8 as seen in the mirror, and we're all done.

## Final Thoughts

I really enjoyed this challenge, especially the teleporter problem even though it was infuriating and I cheated a bit for the answer. Once the vm was up and running, I had no idea the code and registers would need to be hacked.
I have a bit more insight into how an emulator would work, for the C64 or Spectrum for example.


## Further Challenges

* Create an assembler/compiler to create synacor binaries.
* Decompile the entire challenge program into the language of your choice, and perhaps compile it to a native executable.
* Change the program above to be able to do the teleport hack natively.
* Re-create the game in inform: https://en.wikipedia.org/wiki/Inform
* Write the vm in bf.
