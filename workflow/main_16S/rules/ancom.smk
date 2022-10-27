rule taxa_collapse:
    input:
        table = rules.feature_table_rarefy.output,
        taxonomy = rules.feature_classifier_classify_sklearn.output
    output:
        "results/ancom/collapsed_table_l{level}.qza"
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/log/taxa_collapse/l{level}.log"
    shell:
        """
        qiime taxa collapse \
			--i-table {input.table} \
			--i-taxonomy {input.taxonomy} \
			--p-level {wildcards.level} \
			--o-collapsed-table {output} &> {log}
        """

rule composition_add_pseudocount:
    input:
        rules.taxa_collapse.output
    output:
        temp("results/ancom/comp_collapsed_table_l{level}.qza")
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/log/composition_add_pseudocount/l{level}.log"
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
        report("results/ancom/l{level}_ancom_{metadata}.qzv", caption = "../report/composition_ancom.rst", category = "EXTRA: ancom")
    conda:
        "../envs/qiime2.yaml"
    log:
        "results/log/composition_ancom/{metadata}_l{level}.log"
    shell:
        """
        qiime composition ancom \
            --i-table {input.table} \
            --m-metadata-file {input.metadata} \
            --m-metadata-column {wildcards.metadata} \
            --o-visualization {output} &> {log}
        """
