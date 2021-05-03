#!/usr/bin/perl
/*
 * Stack Machine CPU Sample
 *   Binary to ASCII Translator 
 *    Perl code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2021 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

use Switch;
use feature "switch";

sub bin2asc {
	$bin = hex($_[0]);
	$upper = int($bin / 16);
	$lower = $bin % 16;

	$upper_c = ord(&chg16tochar($upper));
	$lower_c = ord(&chg16tochar($lower));

	return sprintf "%2x %2x",$upper_c,$lower_c;
}

sub chg16tochar {
	$num = $_[0];
	switch($num) {
		case 0 { return "0"; }
		case 1 { return "1"; }
		case 2 { return "2"; }
		case 3 { return "3"; }
		case 4 { return "4"; }
		case 5 { return "5"; }
		case 6 { return "6"; }
		case 7 { return "7"; }
		case 8 { return "8"; }
		case 9 { return "9"; }
		case 10 { return "a"; }
		case 11 { return "b"; }
		case 12 { return "c"; }
		case 13 { return "d"; }
		case 14 { return "e"; }
		case 15 { return "f"; }
		else { return "x"; }
	}
}


while(<>) {
	s/\/\/.*$//;
	if (/^\s*$/) {
		next;
	}
	elsif (/^\s*(\w+)\s+(\w+)/) {
		print &bin2asc($1)." ".&bin2asc($2)."\n";
	}
	elsif (/^\s*(\w+)/) {
		print &bin2asc($1)."\n";
	}
}


