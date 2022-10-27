rule feature_table_rarefy:
    input:
        rules.filter_table_nonmicrobial.output
    output:
        "results/normalised/normalised_table.qza"
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/log/feature_table_rarefy/log.log"
    params:
        sampling_depth = config["read_depth"]["lowest"]
    shell:
        """
        qiime feature-table rarefy \
            --i-table {input} \
            --p-sampling-depth {params.sampling_depth} \
            --o-rarefied-table {output} &> {log}
        """

rule get_feature_table:
	input:
		rules.feature_table_rarefy.output
	output:
		report("results/feature-table.biom", caption = "../report/get_feature_table.rst", category = "Step 4: Downstream")
	shell:
		"""
		unzip -d $(dirname {output}) \
			-j {input} $(unzip -l {input} | grep "biom" | tr -s " " | cut -d " " -f5)
		"""

rule taxa_barplot:
    input:
        table = rules.feature_table_rarefy.output,
        taxonomy = rules.feature_classifier_classify_sklearn.output,
        metadata = config["metadata"]
    output:
        report("results/normalised/taxa_barplots.qzv", caption = "../report/taxa_barplot.rst", category = "Step 4: Downstream")
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/log/taxa_barplot/log.log"
    params:
        sampling_depth = config["read_depth"]["lowest"]
    shell:
        """
        qiime taxa barplot \
            --i-table {input.table} \
            --i-taxonomy {input.taxonomy} \
            --m-metadata-file {input.metadata} \
            --o-visualization {output} &> {log}
        """

rule diversity_alpha_rarefaction:
    input:
        table = rules.feature_table_rarefy.output,
        tree = rules.phylogeny_midpoint_root.output,
        metadata = config["metadata"]
    output:
        report("results/normalised/alpha_rarefaction.qzv", caption = "../report/diversity_alpha_rarefaction.rst", category = "Step 4: Downstream")
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/log/diversity_alpha_rarefaction/log.log"
    params:
        metrics = "observed_features chao1 faith_pd shannon simpson_e",
        sampling_depth = config["read_depth"]["lowest"],
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

rule diversity_core_metrics_phylogenetics:
    input:
        tree = rules.phylogeny_midpoint_root.output,
        table = rules.feature_table_rarefy.output,
        metadata = config["metadata"]
    output:
        bray_curtis = report("results/normalised/CORE_METRICS/bray_curtis_emperor.qzv", caption = "../report/diversity_core_metrics_phylogenetics_bray_curtis.rst", category = "Step 4: Downstream"),
        jaccard = report("results/normalised/CORE_METRICS/jaccard_emperor.qzv", caption = "../report/diversity_core_metrics_phylogenetics_jaccard.rst", category = "Step 4: Downstream"),
        unweighted_unifrac = report("results/normalised/CORE_METRICS/unweighted_unifrac_emperor.qzv", caption = "../report/diversity_core_metrics_phylogenetics_unweighted_unifrac.rst", category = "Step 4: Downstream"),
        weighted_unifrac = report("results/normalised/CORE_METRICS/weighted_unifrac_emperor.qzv", caption = "../report/diversity_core_metrics_phylogenetics_weighted_unifrac.rst", category = "Step 4: Downstream")
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/log/diversity_alpha_rarefaction/log.log"
    params:
        metrics = "observed_features chao1 faith_pd shannon simpson_e",
        sampling_depth = config["read_depth"]["lowest"],
        steps = 50
    shell:
        """
        outdir=$(dirname {output.bray_curtis})
		rm -rf $outdir

        qiime diversity core-metrics-phylogenetic \
            --i-phylogeny {input.tree} \
            --i-table {input.table} \
            --p-sampling-depth {params.sampling_depth} \
            --m-metadata-file {input.metadata} \
            --output-dir $outdir &> {log}
        """    


# for i in "$out_tmp"/RARE_"$seqdepth"/CORE_METRICS/*vector*; do
#      a=$(sed 's/.*\///' <<< $i | sed 's/_vector.*//' )
#      qiime diversity alpha-group-significance \
#          --i-alpha-diversity $i \
#          --m-metadata-file $mapping \
#          --o-visualization "$out_tmp"/RARE_"$seqdepth"/CORE_METRICS/"$a"-group-significance.qzv
# done
