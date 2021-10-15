rule feature_table_rarefy:
    input:
        rules.filter_table_nonmicrobial.output
    output:
        f"results/normalised_{seq_depth}/{seq_depth}_table.qza"
    conda:
        "../envs/qiime2-2021.8.yaml"
    log:
        "results/log/feature_table_rarefy/log.log"
    params:
        sampling_depth = seq_depth
    shell:
        """
        qiime feature-table rarefy \
            --i-table {input} \
            --p-sampling-depth {params.sampling_depth} \
            --o-rarefied-table {output} &> {log}
        """

rule taxa_barplot:
    input:
        table = rules.feature_table_rarefy.output,
        taxonomy = rules.feature_classifier_classify_sklearn.output,
        metadata = config["metadata"]
    output:
        f"results/normalised_{seqdepth}/taxa_barplots.qzv"
    conda:
        "../envs/qiime2-2021.8.yaml"
    log:
        "results/log/taxa_barplot/log.log"
    params:
        sampling_depth = seq_depth
    shell:
        """
        qiime taxa barplot \
            --i-table {input.table} \
            --i-taxonomy {input.taxonomy} \
            --m-metadata-file {input.mapping} \
            --o-visualization {output} &> {log}
        """



rule diversity_alpha_rarefaction:
    input:
        table = rules.feature_table_rarefy.output,
        tree = rules.phylogeny_midpoint_root.output,
        metadata = config["metadata"]
    output:
        f"results/normalised_{seqdepth}/alpha_rarefaction.qzv"
    conda:
        "../envs/qiime2-2021.8.yaml"
    log:
        "results/log/diversity_alpha_rarefaction/log.log"
    params:
        metrics = "observed_features chao1 faith_pd shannon simpson_e",
        sampling_depth = seq_depth,
        steps = 50
    shell:
        """
        metrics=$(for i in {params.metrics} ; do echo " --p-metrics "$i ; done | tr "\n" " ")

        qiime diversity alpha-rarefaction \
            --i-table {input.table} \
            --i-phylogeny {input.tree} \
            --p-max-depth {params.sampling_depth} \
            $metrics \
            --p-steps {params.steps} \
            --m-metadata-file {input.metadata} \
            --o-visualization {output} &> {log}
        """

rule diversity_core_metrics_phylogenetic:
    input:
        tree = rules.phylogeny_midpoint_root.output,
        table = rules.feature_table_rarefy.output,
        metadata = config["metadata"]
    output:
        directory(f"results/normalised_{seqdepth}/CORE_METRICS")
    conda:
        "../envs/qiime2-2021.8.yaml"
    log:
        "results/log/diversity_alpha_rarefaction/log.log"
    params:
        metrics = "observed_features chao1 faith_pd shannon simpson_e",
        sampling_depth = seq_depth,
        steps = 50
    shell:
        """
        qiime diversity core-metrics-phylogenetic \
            --i-phylogeny {input.tree} \
            --i-table {input.table} \
            --p-sampling-depth {params.seq_depth} \
            --m-metadata-file {input.metadata} \
            --output-dir {output} &> {log}
        """    


# for i in "$out_tmp"/RARE_"$seqdepth"/CORE_METRICS/*vector*; do
#      a=$(sed 's/.*\///' <<< $i | sed 's/_vector.*//' )
#      qiime diversity alpha-group-significance \
#          --i-alpha-diversity $i \
#          --m-metadata-file $mapping \
#          --o-visualization "$out_tmp"/RARE_"$seqdepth"/CORE_METRICS/"$a"-group-significance.qzv
# done
