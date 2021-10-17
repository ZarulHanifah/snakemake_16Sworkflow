rule feature_classifier_classify_sklearn:
	input:
		rep_seqs = rules.dada2_denoise_single.output.rep_seqs,
		classifier = config["classifier"]
	output:
		"results/taxonomy/taxonomy.qza"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/feature_classifier_classify_sklearn/log.log"
	shell:
		"""
		qiime feature-classifier classify-sklearn \
			--i-classifier {input.classifier} \
			--i-reads  {input.rep_seqs} \
			--o-classification {output} &> {log}
		"""

rule metadata_tabulate_taxonomy:
	input:
		rules.feature_classifier_classify_sklearn.output
	output:
		report("results/taxonomy/taxonomy.qzv", caption = "../report/metadata_tabulate_taxonomy.rst", category = "Taxonomy")
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/metadata_tabulate_taxonomy/log.log"
	shell:
		"""
		qiime metadata tabulate \
			--m-input-file {input} \
			--o-visualization {output} &> {log}
		"""

rule filter_table_nonmicrobial:
	input:
		table = rules.dada2_denoise_single.output.table,
		taxonomy = rules.feature_classifier_classify_sklearn.output
	output:
		"results/dada2/filt_table.qza"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/filter_table_nonmicrobial/log.log"
	params:
		exclude = "mitochondria,chloroplast"
	shell:
		"""
		qiime taxa filter-table \
			--i-table {input.table} \
			--i-taxonomy {input.taxonomy} \
			--p-exclude {params.exclude} \
			--o-filtered-table {output} &> {log}
		"""

rule vis_filter_table_nonmicrobial:
	input:
		table = rules.filter_table_nonmicrobial.output,
		metadata = config["metadata"]
	output:
		report("results/dada2/filt_table.qzv", caption = "../report/vis_filter_table_nonmicrobial.rst", category = "Taxonomy")
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/vis_filter_table_nonmicrobial/log.log"
	shell:
		"""
		qiime feature-table summarize \
			--i-table {input.table} \
			--o-visualization {output} \
			--m-sample-metadata-file {input.metadata} &> {log}
		"""

rule filter_rep_seqs_nonmicrobial:
	input:
		rep_seqs = rules.dada2_denoise_single.output.rep_seqs,
		taxonomy = rules.feature_classifier_classify_sklearn.output
	output:
		"results/dada2/filt_rep_seqs.qza"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/filter_rep_seqs_nonmicrobial/log.log"
	params:
		exclude = "mitochondria,chloroplast"
	shell:
		"""
		qiime taxa filter-seqs \
			--i-sequences {input.rep_seqs} \
			--i-taxonomy {input.taxonomy} \
			--p-exclude {params.exclude} \
			--o-filtered-sequences {output} &> {log}
		"""

rule get_dna_seq:
	input:
		rules.filter_rep_seqs_nonmicrobial.output
	output:
		"results/dna-sequences.fasta"
	shell:
		"""
		unzip -d $(dirname {output}) -j {input} $(unzip -l {input} | grep "dna" | tr -s " " | cut -d " " -f5)
		"""
