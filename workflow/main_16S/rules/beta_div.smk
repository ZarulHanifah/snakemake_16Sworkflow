rule beta_group_significance:
    input:
        bray = rules.diversity_core_metrics_phylogenetics.output.bray_curtis,
        metadata = config["metadata"]
    output:
        directory("results/normalised/beta_group_significance")
    conda:
        "qiime2"
    log:
        "results/log/beta_group_significance/log.log"
    params:
        meta_of_interest = config["ancom"]
    shell:
        """
        indir=$(dirname {input.bray})

        echo > {log}
        mkdir -p {output}
        
        for m in {params.meta_of_interest} ; do
        for bd in bray_curtis jaccard unweighted_unifrac weighted_unifrac; do

         qiime diversity beta-group-significance \
          --i-distance-matrix "$indir"/"$bd"_distance_matrix.qza \
          --m-metadata-file {input.metadata} \
          --m-metadata-column $m \
          --o-visualization {output}/"$bd"_"$m"_statistics.qzv \
          2>> {log}
        
        done
        done
        """