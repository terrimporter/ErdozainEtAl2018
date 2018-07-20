#!/bin/zsh
#Oct. 6, 2017 edited to grab R1 and R2 fastq.gz files by their extension (everything but basename)
#Oct.3, 2016 by Terri Porter
#Script to grab all paired end seq files, loop through, run seqprep multiple to pair the reads
#USAGE zsh runseqprep_gz.sh _R1_001.fastq.gz _R2_001.fastq.gz

NR_CPUS=10
count=0

EXT=$1
EXT2=$2

for r1 in *$EXT
do

echo $r1

base=${r1%%$EXT}
#suffix=_R2.fastq
echo $base

r2=$base$2

echo $r2

#Pair raw reads
seqprep -f $r1 -r $r2 -1 ${r1}.out -2 ${r2}.out -q 20 -s ${base}.paired.fastq.gz -o 25 &

let count+=1
[[ $((count%NR_CPUS)) -eq 0 ]] && wait

done
	
wait

echo "All jobs are done"
