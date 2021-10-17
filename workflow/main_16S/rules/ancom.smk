rule taxa_collapse:
    input:
        table = rules.feature_table_rarefy.output,
        taxonomy = rules.feature_classifier_classify_sklearn.output
    output:
        "results/ancom/collapsed_table_l6.qza"
    conda:
        "../envs/qiime2-2021.2.yaml"
    log:
        "results/log/taxa_collapse/log.log"
    params:
        level = 6
    shell:
        """
        qiime taxa collapse \
			--i-table {input.table} \
			--i-taxonomy {input.taxonomy} \
			--p-level {params.level} \
			--o-collapsed-table {output} &> {log}
        """

rule composition_add_pseudocount:
    input:
        rules.taxa_collapse.output
    output:
        temp("results/ancom/comp_collapsed_table_l6.qza")
    conda:
        "../envs/qiime2-2021.2.yaml"
    log:
        "results/log/composition_add_pseudocount/log.log"
    shell:
        """
        qiime composition add-pseudocount \
            --i-table {input} \
            --o-composition-table {output} &> {log}
        """

rule composition_ancom:
    input:
        table = rules.composition_add_pseudocount.output,
        metadata = config["metadata"]
    output:
        "results/ancom/l6_ancom_{metadata}.qzv"
    conda:
        "../envs/qiime2-2021.2.yaml"
    log:
        "results/log/composition_ancom/{metadata}.log"
    shell:
        """
        qiime composition ancom \
            --i-table {input.table} \
            --m-metadata-file {input.metadata} \
            --m-metadata-column {wildcards.metadata} \
            --o-visualization {output} &> {log}
        """
