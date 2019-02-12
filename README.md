# README

This repository contains the dataflow and scripts I used to process the CO1 metabarcode reads in the paper Erdozain et al., 2019.  

## Citation

Erdozain, M., Thompson, D.G., Porter, T.M., Kidd, K., Kreutzweiser, D.P., Sibley, P.K., Swystun, T., Chartrand, D., Hajibabaei, M.  (2019) Metabarcoding of storage ethanol vs. conventional morphometric identification in relation to the use of stream macroinvertebrates as ecological indicators in forest management.  Ecological Indicators, 101: 173-184.  https://www.sciencedirect.com/science/article/pii/S1470160X19300147

## Overview

[Part I - Raw read stats](#part-i---raw-read-stats)  
[Part II - Pair reads](#part-ii---pair-reads)  
[Part III - Primer trimming](#part-iii---primer-trimming)  
[Part IV - Concatenate sequences and dereplicate](#part-iv---concatenate-sequences-and-dereplicate)  
[Part V - Denoising](#part-v---denoising)  
[Part VI - Generate ESV table](#part-vi---generate-esv-table)  
[Part VII - Taxonomic assignment](#part-vii---taxonomic-assignment)  
[Implementation notes](#implementation-notes)  
[References](#references)  
[Acknowledgements](#acknowledgements)  


## Part I - Raw read stats

I started with compressed fastq files from Illumina MiSeq paired-end sequencing.   I get read statistics including the number of reads as well as minimum/maximum/mean/mode sequence lengths for each sample.  I always check that the number of forward and reverse reads match.  The command gz_stats links to the script run_fastq_gz_stats.sh .  Therein, the stats2 command links to the fastq_gz_stats.plx script.  This Perl script requires the additional Statistics::Lite module that can be obtained from CPAN.  The gz_stats command requires one command-line argument, in this case the pattern that will match all the forward reads or reverse reads, respectively.

~~~linux
gz_stats R1_001.fastq.gz
gz_stats R2_001.fastq.gz
~~~

## Part II - Pair reads

I pair the forward and reverse reads using SEQPREP available from https://github.com/jstjohn/SeqPrep (St. John, 2016).  I specify that there needs to be a minimum Phred score of 20 in the overlap region and a minimum overlap of 25 bp.  The program automatically detects compressed fastq files based on the file extension and will automatically output compressed fastq files based on the file extension provided.  I normally run SEQPREP on a directory of files using the command pair that links to the runseqprep_gz.sh script.  The command 'pair' requires two command-line arguments, the pattern that matches all foward read files and the pattern that matches all revrse read files.

~~~linux
pair _R1_001.fastq.gz _R2_001.fastq.gz
gz_stats gz
~~~

## Part III - Primer trimming

I used CUTADAPT v1.10 to remove primers, specifying that the trimming reads need to be at least 150 bp in length, with a Phred scor eof at least 20 at the ends, and allow a maximum of 3 N's .  The program automatically detects compressed fastq files and will provide compressed fastq outfiles.  Be sure to edit the number of parallel jobs after the -j flag.  After I've moved outfiles into their own directory, I get trimmed read stats with the gz_stats command.

~~~linux
#trim forward primer off the 5' end of paired reads
ls | grep .gz | parallel -j 23 "cutadapt -g <FORWARD PRIMER SEQUENCE> -m 150 -q 20,20 --max-n=3 --discard-untrimmed {} -o {}.Ftrimmed.fastq.gz"
gz_stats gz

#trim reverse primer off the 3' end of paired reads
ls | grep .Ftrimmed.fastq.gz | parallel -j 23 "cutadapt -a <REVERSE-COMPLEMENTED REVERSE PRIMER SEQUENCE> -m 150 -q 20,20 --max-n=3 --discard-untrimmed {} -o {}.Rtrimmed.fastq.gz"
gz_stats gz
~~~

## Part IV - Concatenate sequences and dereplicate

I decompressed the files with gunzip.  I used MOTHUR v1.36.1 to convert fastq files to FASTA files.  I used the command rename_all_fastas to add the sample name parsed from the file name to the FASTA header.  This command links to the run_rename_fasta.sh script .  Therein, the rename_fasta command links to the rename_fasta.plx script.  This script also concatenates sequences from all the samples into a single file.  I used the vi editor to change dashes in the concatenated FASTA file headers into underscores so that VSEARCH/USEARCH sorts out the samples properly.  I dereplicate the reads using VSEARCH, retaining the number of reads per cluster.  I get the cluster stats with the stats_uniques command that links to the run_fastastats_parallel_uniques.sh script.  Therein, the stats command links to the fasta_stats_parallel.plx script.  This script also requires the Statistica::Lite Perl module. I check the number of reads contained in the unique clusters with the read_counts_global_uniques command that links to the sh get_read_counts_uniques.sh script.

~~~linux
ls | grep .gz | parallel -j 23 "gunzip {}"
ls | grep .fastq | parallel -j 23 "mothur '#fastq.info(fastq={},qfile=F)'"
rename_all_fastas
vi -c "%s/-/_/g" -c "wq" cat.fasta
vsearch --threads 23 --derep_fulllength cat.fasta --output cat.uniques --sizein --sizeout
stats_uniques
read_counts_global_uniques
~~~

## Part V - Denoising

I denoised the reads with USEARCH v10.0.240 that uses the unoise3 algorithm (Edgar, 2016) available from https://www.drive5.com/usearch/ .  With this program, denoising refers to the clustering of reads by 100% identity (matching substraings become their own clusters).  The algorithm corrects predicted sequence errors, remove of putative chimeric sequences, and PhiX reads.  It also removes rare reads, that I specify here to be singletons and doubletons only.  This step takes quite some time so I run it using Linux screen.  I get denoised read stats using the stats_denoised command that links to the run_fastastats_parallel_denoised.sh script.  Therein the stats command links to the fasta_stats_parallel.plx script. To accomodate a bug in the USEARCH program, the >Zotu in the FASTA headers are changed to >Otu instead so that the OTU table is generated properly.  I do this with the vi editor.

~~~linux
usearch10 -unoise3 cat.uniques -zotus cat.denoised -minsize 3
stats_denoised
vi -c "%s/>Zotu/>Otu/g" -c "wq" cat.denoised
~~~

## Part VI - Generate ESV table

I generate an OTU table to track the number of reads per OTU are found in each sample.  Here all good quality primer-trimmed reads (from Part III above) are mapped to the denoised reads from the Part V above.  In this case, OTUs are defined by 100% sequence similarity.  They are basically denoised ZOTUs (zero-radius OTUs) (Edgar, 2016) or ESVs (exact sequence variants) (Callahan et al., 2017) using whatever terminology you like best.

~~~linux
usearch10 -otutab cat.fasta -zotus cat.denoised -id 1.0 -otutabout cat.fasta.table
~~~

## Part VII - Taxonomic assignment

I taxonomically assign the ESVs using the CO1 Classifier v2.0 (Porter and Hajibabaei, 2018).  The CO1 reference sets are available from https://github.com/terrimporter/CO1Classifier .  This tool uses the Ribosomal Database Project (RDP) naive Bayesian classifier (Wang et al., 2007) available from https://sourceforge.net/projects/rdp-classifier/ .  I then map the read numbers from the ESV table (Part VI) to the taxonomic assignments with the script add_abundance_to_rdp_out3.plx

~~~linux
java -Xmx8g -jar /path/to/rdp_classifier_2.12/dist/classifier.jar classify -t /path/to/rRNAClassifier.properties -o cat.denoised.out cat.denoised
perl add_abundance_to_rdp_out3.plx cat.fasta.table cat.denoised.out
~~~

## Implementation notes

Shell scripts are written for Z shell.  Other scripts are written in Perl and may require additional libraries that are indicated at the top of the script when needed and these can be obtained from CPAN.  Generally, I like to write shell scripts for long-running jobs and I like to use GNU parallel to parallelize many quick jobs right from the command line available from https://www.gnu.org/software/parallel/ (Tang, 2011).  Documentation is extensive, but for the examples I provide in this dataflow, be sure to edit the -j (number of jobs) flag according to the number of cores you have available.

To keep the dataflow here as clear as possible, I have ommitted file renaming and clean-up steps.  I also use shortcuts to link to scripts as described above in numerous places.  This is only helpful if you will be running this pipeline often.  I describe, in general, how I like to do this here:

### Batch renaming of files

Note that I am using Perl-rename (Gergely, 2018) that is available at https://github.com/subogero/rename not linux rename.  I prefer the Perl implementation so that you can easily use regular expressions.  I first run the command with the -n flag so you can review the changes without making any actual changes.  If you're happy with the results, re-run without the -n flag.

```linux
rename -n 's/PATTERN/NEW PATTERN/g' *.gz
```

### File clean-up

At every step, I place outfiles into their own directory, then cd into that directory.  I also delete any extraneous outfiles that may have been generated but are not used in subsequent steps to save disk space.

### Symbolic links

Instead of continually traversing nested directories to get to files, I create symbolic links to target directories in a top level directory.  Symbolic links can also be placed in your ~/bin directory that point to scripts that reside elsewhere on your system.  So long as those scripts are executable (e.x. chmod 755 script.plx) then the shortcut will also be executable without having to type out the complete path or copy and pasting the script into the current directory.

```linux
ln -s /path/to/target/directory shortcutName
ln -s /path/to/script/script.sh commandName
```

# References

Callahan, B.J., McMurdie, P.J., and Holmes, S.P. (2017) Exact sequence variants should replace operational taxonomic units in marker-gene data analysis.  The ISME Journal, 11: 2639.

Edgar, R. C. (2016). UNOISE2: improved error-correction for Illumina 16S and ITS amplicon sequencing. BioRxiv. doi:10.1101/081257

Porter, T. M., & Hajibabaei, M. (2018). Automated high throughput animal CO1 metabarcode classification. Scientific Reports, 8, 4226. Available from https://github.com/terrimporter/CO1Classifier

St. John, J. (2016, Downloaded). SeqPrep. Retrieved from https://github.com/jstjohn/SeqPrep/releases  

Tange, O. (2011). GNU Parallel - The Command-Line Power Tool. ;;Login: The USENIX Magazine, February, 42–47. Available from https://www.gnu.org/software/parallel/

Wang, Q., Garrity, G. M., Tiedje, J. M., & Cole, J. R. (2007). Naive Bayesian Classifier for Rapid Assignment of rRNA Sequences into the New Bacterial Taxonomy. Applied and Environmental Microbiology, 73(16), 5261–5267. Available from https://sourceforge.net/projects/rdp-classifier/

# Acknowledgements

I would like to acknowledge funding from the Canadian government from the Genomics Research and Development Initiative (GRDI) Ecobiomics project.

Last updated: July 19, 2018
