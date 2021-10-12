#!/bin/bash
# bash mod_script.sh -i ALL_FASTQ -f CCTACGGGNGGCWGCAG -r GACTACHVGGGTATCTAATCC -m mapping.csv -c silva-138-99-515-806-nb-classifier.qza -o results

function checkargs {
if [[ $OPTARG =~ ^-[i/f/r/m/c/o]$ ]]
then
    echo "$OPTARG is an invalid argument to -$opt"
    exit
fi
}

while getopts "i:f:r:m:c:o:" opt
do
case $opt in
i)
    checkargs
    in_dir_tmp=`echo $OPTARG | sed 's/\/$//g'`;;
f)
    checkargs
    fwd_primer=`echo $OPTARG | sed 's/\/$//g'`;;
r)
    checkargs
    rvs_primer=`echo $OPTARG | sed 's/\/$//g'`;;
m)
    checkargs
    mapping=`echo $OPTARG | sed 's/\/$//g'`;;
c)
    checkargs
    classifier=`echo $OPTARG | sed 's/\/$//g'`;;
o)
    checkargs
    out_tmp=`echo $OPTARG | sed 's/\/$//g'`;;
:)
    echo "option -$OPTARG requires an argument"
    exit
esac
done


# Input fastq should be in gzip

# USEARCH="/home/zarul/Zarul/__stuff__/usearch11.0.667_i86linux32"
QIIMEENV="qiime2-2021.2"

echo $in_dir_tmp
echo $fwd_primer
echo $rvs_primer
echo $mapping
echo $classifier
echo $out_tmp
echo $QIIMEENV

source activate $QIIMEENV

if [ ! -d "$out_tmp" ]; then
    cd $in_dir_tmp

    # Trim primer sequences
    for f in *_R1_*; do
            r=$(sed "s/_R1_/_R2_/" <<< $f)
            cutadapt -g $fwd_primer -G $rvs_primer \
                    -o ${f%.fastq.gz}.trimmed.fastq -p ${r%.fastq.gz}.trimmed.fastq \
                    --untrimmed-o ${f%.fastq.gz}.untrimmed.fastq --untrimmed-p ${r%.fastq.gz}.untrimmed.fastq \
                    $f $r

            vsearch --fastq_mergepairs ${f%.fastq.gz}.trimmed.fastq --reverse ${r%.fastq.gz}.trimmed.fastq --fastqout ${f%.fastq.gz}.merged.fastq
    done

    mkdir TRIMMED UNTRIMMED MERGED

    mv *untrimmed* UNTRIMMED
    mv *trimmed.fastq TRIMMED
    mv *merged* MERGED

    mv UNTRIMMED TRIMMED MERGED ..
    cd ..

    cd MERGED
    rename 's/\.merged//' *
    gzip *
    cd ..


    mkdir $out_tmp
    mv UNTRIMMED TRIMMED MERGED $out_tmp

else
    echo
fi


if [ ! -s "$out_tmp"/table.qza ] ; then
    qiime tools import \
        --type 'SampleData[SequencesWithQuality]' \
        --input-path "$out_tmp"/MERGED \
        --input-format CasavaOneEightSingleLanePerSampleDirFmt \
        --output-path "$out_tmp"/demux.qza

    qiime demux summarize \
        --i-data "$out_tmp"/demux.qza \
        --o-visualization "$out_tmp"/demux.qzv

    qiime dada2 denoise-single \
        --i-demultiplexed-seqs "$out_tmp"/demux.qza \
        --p-trunc-len 0 \
        --p-n-threads 0 \
        --o-representative-sequences "$out_tmp"/rep-seqs.qza \
        --o-table "$out_tmp"/table.qza \
        --o-denoising-stats "$out_tmp"/stats.qza
else
    echo
fi

if [ ! -s "$out_tmp"/rep-seqs.qzv ] ; then
    qiime feature-table summarize \
        --i-table "$out_tmp"/table.qza \
        --o-visualization "$out_tmp"/table.qzv \
        --m-sample-metadata-file $mapping

    qiime feature-table tabulate-seqs \
        --i-data "$out_tmp"/rep-seqs.qza \
        --o-visualization "$out_tmp"/rep-seqs.qzv
else
    echo
fi

    # ## ID dem tings

if  [ ! -s "$out_tmp"/TAXONOMY/taxonomy.qza ] ; then
    mkdir "$out_tmp"/TAXONOMY

    qiime feature-classifier classify-sklearn \
        --i-classifier $classifier \
        --i-reads  "$out_tmp"/rep-seqs.qza \
        --o-classification "$out_tmp"/TAXONOMY/taxonomy.qza

    qiime metadata tabulate \
    	--m-input-file "$out_tmp"/TAXONOMY/taxonomy.qza \
    	--o-visualization "$out_tmp"/TAXONOMY/taxonomy.qzv
else
    echo
fi

    # Filter dem alien tings

if [ ! -s "$out_tmp"/filt-rep-seqs.qza ] ; then
    qiime taxa filter-table \
        --i-table "$out_tmp"/table.qza \
        --i-taxonomy "$out_tmp"/TAXONOMY/taxonomy.qza \
        --p-exclude mitochondria,chloroplast \
        --o-filtered-table "$out_tmp"/filt_table.qza

    qiime taxa filter-seqs \
      --i-sequences "$out_tmp"/rep-seqs.qza \
      --i-taxonomy "$out_tmp"/TAXONOMY/taxonomy.qza \
      --p-exclude mitochondria,chloroplast \
      --o-filtered-sequences "$out_tmp"/filt-rep-seqs.qza

    qiime feature-table summarize \
        --i-table "$out_tmp"/filt_table.qza \
        --o-visualization "$out_tmp"/filt_table.qzv \
        --m-sample-metadata-file $mapping
else
    echo
fi

    # Plant a tree

if [ ! -s "$out_tmp"/ALL_TREE/rooted-tree.qza ] ; then
    mkdir "$out_tmp"/ALL_TREE

    qiime alignment mafft \
      --i-sequences "$out_tmp"/filt-rep-seqs.qza \
      --o-alignment "$out_tmp"/ALL_TREE/aligned-rep-seqs.qza

    qiime alignment mask \
      --i-alignment "$out_tmp"/ALL_TREE/aligned-rep-seqs.qza \
      --o-masked-alignment "$out_tmp"/ALL_TREE/masked-aligned-rep-seqs.qza

    qiime phylogeny fasttree \
      --i-alignment "$out_tmp"/ALL_TREE/masked-aligned-rep-seqs.qza \
      --o-tree "$out_tmp"/ALL_TREE/unrooted-tree.qza

    qiime phylogeny midpoint-root \
      --i-tree "$out_tmp"/ALL_TREE/unrooted-tree.qza \
      --o-rooted-tree "$out_tmp"/ALL_TREE/rooted-tree.qza
else
    echo
fi
    

echo 'Note highest and lowest depth, then plot alpha rarefaction'
qiime tools view "$out_tmp"/filt_table.qzv


for i in $(seq 5); do echo ; done
echo '##################################################################################'
for i in $(seq 5); do echo ; done
read -p 'Highest sequencing depth? : ' seqdepth1

qiime diversity alpha-rarefaction \
    --i-table "$out_tmp"/filt_table.qza \
    --i-phylogeny "$out_tmp"/ALL_TREE/rooted-tree.qza \
    --p-max-depth $seqdepth1 \
    --p-metrics observed_features \
    --p-metrics chao1 \
    --p-metrics faith_pd \
    --p-metrics shannon \
    --p-metrics simpson_e \
    --p-steps 100 \
    --m-metadata-file $mapping \
    --o-visualization "$out_tmp"/mock-alpha-rarefaction.qzv

qiime tools view "$out_tmp"/mock-alpha-rarefaction.qzv

for i in $(seq 5); do echo ; done
echo '##################################################################################'
for i in $(seq 5); do echo ; done
read -p 'Balance your sequencing depth (Number of reads to snapshot whole ASVs (VS) Number of remaining samples).Your chosen sequencing depth? : ' seqdepth

mkdir "$out_tmp"/RARE_"$seqdepth"

qiime feature-table rarefy \
    --i-table "$out_tmp"/filt_table.qza \
    --p-sampling-depth $seqdepth \
    --o-rarefied-table "$out_tmp"/RARE_"$seqdepth"/"$seqdepth"_table.qza

qiime diversity alpha-rarefaction \
    --i-table "$out_tmp"/RARE_"$seqdepth"/"$seqdepth"_table.qza \
    --i-phylogeny "$out_tmp"/ALL_TREE/rooted-tree.qza \
    --p-max-depth $seqdepth \
    --p-metrics observed_features \
    --p-metrics chao1 \
    --p-metrics faith_pd \
    --p-metrics shannon \
    --p-metrics simpson_e \
    --p-steps 50 \
    --m-metadata-file $mapping \
    --o-visualization "$out_tmp"/RARE_"$seqdepth"/alpha-rarefaction.qzv

qiime diversity core-metrics-phylogenetic \
    --i-phylogeny "$out_tmp"/ALL_TREE/rooted-tree.qza \
    --i-table "$out_tmp"/RARE_"$seqdepth"/"$seqdepth"_table.qza \
    --p-sampling-depth $seqdepth \
    --m-metadata-file $mapping \
    --output-dir "$out_tmp"/RARE_"$seqdepth"/CORE_METRICS

for i in "$out_tmp"/RARE_"$seqdepth"/CORE_METRICS/*vector*; do
     a=$(sed 's/.*\///' <<< $i | sed 's/_vector.*//' )
     qiime diversity alpha-group-significance \
         --i-alpha-diversity $i \
         --m-metadata-file $mapping \
         --o-visualization "$out_tmp"/RARE_"$seqdepth"/CORE_METRICS/"$a"-group-significance.qzv
done

##  Make a barplot

qiime taxa barplot \
    --i-table "$out_tmp"/RARE_"$seqdepth"/"$seqdepth"_table.qza \
    --i-taxonomy "$out_tmp"/TAXONOMY/taxonomy.qza \
    --m-metadata-file $mapping \
    --o-visualization "$out_tmp"/RARE_"$seqdepth"/taxa-barplots.qzv
