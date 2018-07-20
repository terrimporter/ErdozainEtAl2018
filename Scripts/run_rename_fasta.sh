#!/bin/zsh
#Mar.28/17 by Teresita M. Porter
#Runs rename_fasta.plx on a directory of FASTA files
#Adds base name (sample name) to start of FASTA header
#Also concatenates the output into a single outfile for a global analysis
#USAGE sh run_rename_fasta.sh

for f in *.fasta
do

rename_fasta $f

done

for g in *.fa
do

cat $g >> cat.fasta

done

echo 'Job is done.'
