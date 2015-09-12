#!/usr/bin/perl

@lines = undef;
$i = 0;
#These two variable are used to record which line need to do spcial change later.
$count_line = 1;
$stdin_line = 0;
# These two variables are used for printing import info only once.
$fileinput_print = 0;
$sys_print = 0;
#change head file format, like 'import sys...'

while ($line = <>) {
	if ($line =~ /^#!/ && $. == 1) {
		# translate #! line 
		
		print "#!/usr/bin/python2.7 -u\n";
		next;
	} 
	elsif ($line =~ /.*\<STDIN\>.*/ || $line =~ /.*ARGV.*/ || $line =~ /print\s*\".*[^\\n]\"/) {
		# add 'import sys' when we meet <STDIN>.
		if ($sys_print == 0) {
			print "import sys\n";
		}
		$sys_print = 1;
		if ($line =~ /.*\$\w+\s*\=\s*\<STDIN\>.*/) {
			# as case 'odd0.pl', we need to know if the variable before '<STDIN>' is a number or string, 				# if it is a number, record the line nb and we change it later.
			
			$stdin_line = $count_line;
		}
	}
	elsif ($line =~ /.*=\s*\<\>.*/ || $line =~ /s\/.*\/.*\//) {
		# add 'import fileinput, re' when we meet '= <>'
		if ($fileinput_print == 0) {
			print "import fileinput, re\n";
		}
		$fileinput_print = 1;
	}
	$lines[$i++] = $line;
	$count_line++;
}


#clear count_line, when it is eqaul to stdin_lineor other .*_line, then we do spcial change.
$count_line = 1;
#change source code format

foreach $line (@lines) {
	
	if ($line =~ /^#!/ && $. == 1) {
	
		# translate #! line 
		$count_line++;
		next;
	} 
	elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
	
		# Blank & comment lines can be passed unchanged
		#print "0..0";
		print $line;
	} 
	elsif ($line =~ /^\s*print.*\s*$/) {
		# Python's print adds a new-line character by default
		# so we need to delete it from the Perl print statement
		#print "1..1";
		$new_line = 0;
		if ($line =~ /\\n/) {
			
			$line =~ s/\\n|\"\\n\"|\,//g;
			$new_line = 1;
		}
		$line =~ s/\;//g;
		
		if ($line =~ /.*\s*\$\w+\s*.*$/) {
			if ($line =~ /.*\@ARGV.*/) {
				# if it is array of ARGV, then change to array format
				$line =~ s/\@ARGV/sys.argv[1:]/g;
				print $line;
				$count_line++;
				next;
			}
			elsif ($line =~ /.*\$ARGV.*/) {
				# if it is $ARGV[], then change to element format
				#print "1\n";
				$tmp = $line;
				$tmp =~ s/\"|ARGV|\$|print|\[|\]|\s*//g;
				$line =~ s/\"|\$//g;
				$line =~ s/ARGV\[.*\]/sys.argv\[$tmp + 1\]/g;
				print $line;
				$count_line++;
				next;
			}
			elsif ($line =~ /\*|\+|\-|\//) {
				# if we  meet pattern '$i * $j', then delete $ and print.
				$line =~ s/\$//g;
				print $line;
				$count_line++;
				next;
			}
			#variables in perl has $ in front, and we need to delete $ in python, if it is no $, print it 				#as string, and add ',' between them.
			elsif ($new_line == 0 && $line =~ /^\s*print\s*\"\s*\$\w+\s*\"\s*$/) {
				$line =~ s/\$|\"//g;
				$line =~ s/print\s*/sys.stdout.write\(/g;
				chomp $line;
				$line = join('', $line, "\)", "\n");
				print $line;
				$count_line++;
				next;
			}
			@tmp = split (' ', $line);
			$add_comma = 0;
			foreach $tmp (@tmp){
				if ($tmp eq 'print') {
					next;
				}
				if ($tmp =~ /.*\$\w+.*/) {
					if ($add_comma == 1) {
						$tmp =~ s/\$|"//g;
						$tmp = join('', ",", $tmp);
						next;
					}
					$tmp =~ s/\$|"//g;
					$add_comma = 1;
				}
				else {
					if ($add_comma == 1) {
						$tmp =~ s/"//g;
						$tmp = join('', ",\"", $tmp, "\"");
						next; 
					}
					$tmp =~ s/"//g;
					$tmp = join('', "\"", $tmp, "\"");
					$add_comma = 1;
				}
			}
			$line =~ s/print.*/print/g;
			chomp $line;
			print $line, " ";
			foreach $tmp (@tmp) {
				next, if ($tmp =~ /print/);
				print $tmp, " ";
			}
			print "\n";
			$count_line++;
			next;
		}
		if ($line =~ /.*ARGV.*/) {
  			# change argv format to match python style
			#print "laal\n";	
			if ($line =~ /.*\@ARGV.*/) {
				# if it is array of ARGV, then change to array format
				$line =~ s/\@ARGV/sys.argv[1:]/g;
			}
			else {
				# if it is $ARGV[], then change to element format
				#print "1\n";
				$tmp = $line;
				$tmp =~ s/\"|ARGV|\$|print|\[|\]|\s*//g;
				$line =~ s/\"|\$//g;
				$line =~ s/ARGV\[.*\]/sys.argv\[$tmp + 1\]/g;
			}
		}
		if ($line =~ /\s+join\s*\(/) {
			# when we see 'join' in print, change the format
			$line =~ s/join\(/.join\( /;
			@tmp = split (' ', $line);
			$newstr = join ('', $tmp[0], " ", $tmp[2], " ",$tmp[3], $tmp[1], $tmp[4]);
			print $newstr, "\n";
			$count_line++;
			next;
		}
		if ($line =~ /\s+split\s*\(/) {
			# when we see 'split' in print, change the format
			$line =~ s/split\(/.split\( /;
			@tmp = split (' ', $line);
			$newstr = join ('', $tmp[0], " ", $tmp[2], " ",$tmp[3], $tmp[1], $tmp[4]);
			print $newstr, "\n";
			$count_line++;
			next;
		}
		if ($new_line == 0) {
			
			$line =~ s/print\s*/sys.stdout.write\(/g;
			chomp $line;
			$line = join('', $line, "\)", "\n");
		}
		print $line;
	} 
	
	elsif ($line =~ /^\s*while\s*\(.*\)\s*\{/ || $line =~ /^\s*if\s*\(.*\)\s*\{/ || $line =~ /.*elsif\s*\(.*\)\s*\{/) {
		# if we meet 'if' or 'while' or 'elsif' condition, then change the format for the logical operators. 
		#print "2..2";
		$line =~ s/\(//;
		$line =~ s/\)/\:/;
		$line =~ s/\{//g;
		# delete '}' before 'elsif' and change 'elsif' to 'elif'.
		$line =~ s/\s*\}\s*//g;
		$line =~ s/elsif/elif/g;
		$line =~ s/\s+eq\s+/==/g;
		$line =~ s/\s+ne\s+/!=/g;
		if ($line =~ /.*\s*\$\w+\s*.*$/) {
			# variables in perl has $ in front, and we need to delete $ in python.
		
			$line =~ s/\$//g;
			$line =~ s/\;//g;
			if ($line =~ /\|\|/ || $line =~ /\&\&/) {
				#when if statement have two or more conditions
				$line =~ s/\|\|/\) or \(/g;
				$line =~ s/\&\&/\) and \(/g;
				$line =~ s/if/if \(/g;
				$line =~ s/while/while \(/g;
				$line =~ s/\:/\)\:/g;
			}
		}
		if ($line =~ /.*=\s*\<\>.*/) {
			# when we see '= <>', change it to python format.		
			$line =~ s/while|\s*|=|\<|\>|\://g;
			print "for ", $line, " in fileinput.input():\n";
			$count_line++;
			next;
		}
		if ($line =~ /.*\=\s*\<STDIN\>\s*.*/) {
			# when we see 'while' and '<STDIN>', change it to 'for x in sys.stdin:'.
			$line =~ s/while|STDIN|\s*|=|\<|\>|\://g;
			print "for ", $line, " in sys.stdin:\n";
			$count_line++;
			next;
		}
		print $line;
	}
	elsif ($line =~ /\s*foreach\s*.*/) {
		# when we see 'foreach', translate it to 'for ... in ...'
		#print "3..3";
		
		$line =~ s/foreach/for/g;
		if ($line =~ /\$#ARGV/) {
			# when we meet '(0..$#ARGV)', change it to 'xrange(len(sys.argv) - 1)'
			$line =~ s/\(|\)|\$|\{//g;
			@tmp = split (' ', $line);
			print $tmp[0], " ", $tmp[1], " in xrange(len(sys.argv) - 1):\n";
			$count_line++;	
			next;
		}
		$line =~ s/\(|\)|\$|\{//g;
		if ($line =~ /.*ARGV.*/) {
  			# change argv format to match python style
				
			if ($line =~ /.*\@ARGV.*/) {
				# if it is array of ARGV, then change to array format
				
				$line =~ s/\@ARGV/sys.argv[1:]/g;
				
			}
			else {
				# if it is $ARGV[], then change to element format
				$tmp = $line;
				$tmp =~ s/ARGV|\$|print|\[|\]|\s*//g;
				$line =~ s/ARGV\[.*\]/sys.argv\[$tmp + 1\]/g;
				
			}
		}
		if ($line =~ /.+\.\..+/) {
			# if meet 'foreach (0..x)', then change to 'xrange(0, x)'
			
			@tmp = split(' ', $line);
			$tmp[2] =~ s/\b..\b/, /g;
			$tmp_str = $tmp[2];
			$tmp_str =~ s/.*, //g;
			$tmp_str++;
			$tmp[2] =~ s/, .*$/, $tmp_str/g;
			print $tmp[0], " ", $tmp[1], " in xrange(", $tmp[2], "):\n";
			$count_line++;
		}
		else {
			@tmp = split(' ', $line);
			print $tmp[0], " ", $tmp[1], " in ", $tmp[2], ":\n";
			$count_line++;
		}
	}

	# I put 'if' condition, loops and print as higher changing format level, 
	#and others are lower changing format level. 
	elsif ($line =~ /^\s*chomp.*/) {
		# when we meet 'chmop', we need to change format to '.rstrip()'.
		#print "4..4";
		if ($line =~ /.*\s*\$\w+\s*;\s*$/) {
			# if there is a variable after 'chomp', then change.
			$line =~ s/(\$|\;)//g;
			$line =~ s/chomp\s*//;
			chomp $line;
			$tmp = $line;	
			$tmp =~ s/\s*//g;
			$line = join ('', $line, " = ", $tmp, ".rstrip()");
			print $line, "\n";
		}
		
	}
	elsif ($line =~ /^.*\s*\$.+\s*.*$/) {
		# variables in perl has $ in front, and we need to delete $ in python.
		#print "5..5";
		$line =~ s/\$//g;
		$line =~ s/\;//g;
		if ($line =~ /.*\s*=\s*\<STDIN\>\s*\s*$/) {
			
			# change read format when we see '<STDIN>'.
			if ($stdin_line == $count_line) {
				
				$line =~ s/<STDIN>/float(sys.stdin.readline())/g;
				print $line;
				$count_line++;
				next;
			}
			$line =~ s/<STDIN>/sys.stdin.readline()/g;
		}
		if ($line =~ /.*=~\s*s\/.*\/.*\/.*/) {
			# if we see 's///' then change it to python style
			$line =~ s/=~|s|g|\bi\b//g;
			@tmp = split ('/', $line);
			print $tmp[0], " = re.sub(r'", $tmp[1], "', '", $tmp[2], "', ", $tmp[0], ")\n";
			$count_line++;
			next;
		}
		if ($line =~ /\+\+/) {
			# if we see '$i++', change it to 'i += 1'.
			$line =~ s/\+\+/ \+\= 1/g;
		}
		print $line;
	}
	elsif ($line =~ /^\s*\}\s*$/) {
		#delete the '}' of 'if' condition or 'while' loop.
		#print "6..6";
		$line =~ s/\}//g;
	}
	elsif ($line =~ /\s*last;/ || $line =~ /\s*next;/) {
		# change last or next to break and continue.
		#print "7..7";
		$line =~ s/last;/break/;
		$line =~ s/next;/continue/;
		print $line;
	}
	elsif ($line =~ /else\s*\{/) {
		# change 'else' format to match python code.
		if ($line =~ /\s*\}\s*else\s*\{/) {
			$line =~ s/\}\s*else\s*\{/else:/g;
		}
		else {
			$line =~ s/\}//g;
			$line =~ s/\s*\{/:/g;
		}
		print $line;
	}
	elsif ($line =~ /\s+join\s*\(/) {
		# when we see 'join' in print, change the format
		$line =~ s/join\(/.join\( /;
		@tmp = split (' ', $line);
		$newstr = join ('', $tmp[0], " ", $tmp[2], " ",$tmp[3], $tmp[1], $tmp[4]);
		print $newstr, "\n";
		$count_line++;
		next;
	}
	elsif ($line =~ /\s+split\s*\(/) {
		# when we see 'split' in print, change the format
		$line =~ s/split\(/.split\( /;
		@tmp = split (' ', $line);
		$newstr = join ('', $tmp[0], " ", $tmp[2], " ",$tmp[3], $tmp[1], $tmp[4]);
		print $newstr, "\n";
		$count_line++;
		next;
	}
	else {
		# Lines we can't translate are printed directly.
		#print "8..8";
		print $line;
	}
	$count_line++;
}

