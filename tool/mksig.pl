#!/usr/bin/perl

$flg = 0;

while(<>) {
	s/reg//g;
        s/wire//g;
	if ((flg == 0)&&(/^module\s+(\S+)\s*\(/)) {
		$flg = 1;
	}
	elsif (($flg > 0)&&(/^\s*(input|output)\s+(\[\d+:\d+\])\s+(\w+)\s*/)) {
		print "wire $2 $3; // $1\n";
	}
	elsif (($flg > 0)&&(/^\s*(input|output)\s+(\w+)\s*/)) {
		print "wire $2; // $1\n";
	}
	        elsif (($flg > 0)&&(/\s*\)\;\s*$/)) {
                $flg = 0;
        }
}


