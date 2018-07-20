#!/usr/bin/perl
#March 28, 2017 by Teresita M. Porter
#Script to add the sample name, parsed from the basename of the file, to the FASTA header prior to global concatenation and denoising
#USAGE perl rename_fasta.plx file.fasta

use strict;
use warnings;

#declare vary
my $filename;
my $base;
my $outfile;
my $line;
my $i=0;
my $newline;

#declare array
my @in;
my @filename;

open (IN, "<", $ARGV[0]) || die "Cannot open infile: $!\n";
@in=<IN>;
close IN;

$filename = $ARGV[0];
@filename = split(/\./,$filename); ##### edit delimiter type here #####
$base = $filename[0];
$outfile = $filename.".fa";

open (OUT, ">>", $outfile) || die "Cannot open outfile: $!\n";

while ($in[$i]) {
	$line = $in[$i];
	chomp $line;

	if ($line =~ /^>/) {
		$line =~ s/^>//g; 
		$newline = $base.";".$line;
		print OUT ">".$newline."\n";
	}
	else {
		print OUT "$line\n";
	}
	$newline=();
	$i++;
}
$i=0;

close OUT;
