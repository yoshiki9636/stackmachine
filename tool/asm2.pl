#!/usr/bin/perl
/*
 * Stack Machine CPU Sample
 *   Stack Machine Simple Assembler 
 *    Perl code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2021 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

use Getopt::Long;

GetOptions('v' => \$v);

$name = $ARGV[0];
$pc = 0;
@label = ();
%value = ();

while(<>) {
	if (/^;/) {
		next;
	}
	elsif (/^:(\w+)/) {
		@label = ( @label, $1 );
		$value{$1} = $pc;
	}
	elsif (/^\s*JMP\s+(\w+)\s+(\w+)/) {
		$pc += 2;
	}
	elsif (/^\s*POP/) {
		$pc += 1;
	}
	elsif (/^\s*PUSH\s+I\s+(\w+)/) {
		$pc += 2;
	}
	elsif (/^\s*PUSH\s+([AB])/) {
		$pc += 1;
	}
	elsif (/^\s*ADD\s+I\s+(\w+)/) {
		$pc += 2;
	}
	elsif (/^\s*ADD\s+AB/) {
		$pc += 1;
	}
	elsif (/^\s*SUB\s+I\s+(\w+)/) {
		$pc += 2;
	}
	elsif (/^\s*SUB\s+AB/) {
		$pc += 1;
	}
	elsif (/^\s*CMP\s+I\s+(\w+)/) {
		$pc += 2;
	}
	elsif (/^\s*CMP\s+AB/) {
		$pc += 1;
	}
	elsif (/^\s*OUT\s+(\w+)/) {
		$pc += 2;
	}
	elsif (/^\s*CLR/) {
		$pc += 1;
	}
	elsif (/^\s*NOP/) {
		$pc += 1;
	}
}

$ARGV[0] = $name;

while(<>) {
	if (/^;/) {
		next;
	}
	elsif (/^\s*$/) {
		next;
	}
	elsif (/^\s*JMP\s+(\w+)\s+(\w+)/) {
		$jmp = 0x00;
		if ($1 eq IM) { $jmp += 0x00; }
		elsif ($1 eq "CZ") { $jmp += 0x03; }	
		elsif ($1 eq "ZC") { $jmp += 0x03; }	
		elsif ($1 eq "Z") { $jmp += 0x01; }	
		elsif ($1 eq "C") { $jmp += 0x02; }	
		elsif ($1 eq "SUO") { $jmp += 0x0c; }
		elsif ($1 eq "SOU") { $jmp += 0x0c; }
		elsif ($1 eq "SU") { $jmp += 0x08; }
		elsif ($1 eq "SO") { $jmp += 0x04; }
		printf "%02x ",$jmp;
		$hit = 0;
		foreach $l (@label) {
			if ($2 eq $l) { $hit = 1; break; }
		}
		if ($hit == 1) {
			printf "%02x ",$value{$2};
		}
		else {
			print  "$2";
		}

	}
	elsif (/^\s*POP/) {
		print  "20";
	}
	elsif (/^\s*PUSH\s+I\s+(\w+)/) {
		print  "40 $1";
	}
	elsif (/^\s*PUSH\s+([AB])/) {
		$push = 0x40;
		if ($1 eq "A") { $push += 0x01; }
		else { $push += 0x02; }
		printf "%02x",$push;
	}
	elsif (/^\s*ADD\s+I\s+(\w+)/) {
		print  "60 $1";
	}
	elsif (/^\s*ADD\s+AB/) {
		print  "61";
	}
	elsif (/^\s*SUB\s+I\s+(\w+)/) {
		print  "80 $1";
	}
	elsif (/^\s*SUB\s+AB/) {
		print  "81";
	}
	elsif (/^\s*CMP\s+I\s+(\w+)/) {
		print  "a0 $1";
	}
	elsif (/^\s*CMP\s+AB/) {
		print  "a1";
	}
	elsif (/^\s*OUT\s+(\w+)/) {
		print  "c0 $1";
	}
	elsif (/^\s*CLR/) {
		print  "e0";
	}
	elsif (/^\s*NOP/) {
		print  "ff";
	}
	if ($v == 1) {
		print " // $_";
	}
	else {
		print "\n";
	}

}


