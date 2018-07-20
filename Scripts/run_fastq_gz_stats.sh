#!/bin/zsh
#July 20, 2018 by Teresita M. Porter
#Script to get read stats from a directory of fastq.gz files
#stats2 links to fastq_gz_stats.plx
#USAGE zsh run_fastq_gz_stats.sh

echo sample'\t'numseqs'\t'minlength'\t'maxlength'\t'meanlength'\t'median'\t'modelength

NR_CPUS=10
count=0

EXT="$1"

for f in *$EXT
do

stats2 $f &

let count+=1
[[ $((count%NR_CPUS)) -eq 0 ]] && wait

done
	
wait

echo "All jobs are done"
