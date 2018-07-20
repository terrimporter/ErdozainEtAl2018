#!/bin/zsh
#July 20, 2018 by Teresita M. Porter
#Script to get read counts from FASTA headers for all *.uniques in a directory
#USAGE sh get_read_counts_uniques.sh

#Adjust number of cores to use here if processing more than one file
NR_CPUS=5
count=0

echo -e 'sample\treadcount'

for f in *.uniques
do

base=${f%%.uniques*}

readcount=$(grep ">" $f | awk 'BEGIN {FS=";"} {print $2}' | sed 's/size=//g' | awk '{sum+=$1} END {print sum}')

echo -e $base'\t'$readcount

let count+=1 
[[ $((count%NR_CPUS)) -eq 0 ]] && wait

done
	
wait

echo "All jobs are done"
