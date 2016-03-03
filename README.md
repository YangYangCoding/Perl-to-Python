This code has been written by Yang Yang.
This is a example code(Perl) to translate the codes written by Perl into the codes written by Python.

Here is an example,
If the code of perl called test.pl looks like:

#!/usr/bin/perl

$a = 3;
print "$a";

Then after running the perl2python.pl, it will creative a new test file with python code called test.py:

#!/usr/bin/python2.7 -u
import sys

a = 3
sys.stdout.write(a)

These two codes(test.pl & test.py) have the same output(ressult).
So as long as the new generate python code has the same output or same function as the original perl code, then we 
consider the translation is right.

You can use perl2python.pl like this on your Mac terminal:
perl perl2python.pl test.pl>test.py

This perl2python code has bugs and can not translate all kinds of perl codes into python codes.
So you can try your way to fix bugs or write your code to implement it.

 Good luck and have fun!

