rule tools_import:
	input:
		expand(rules.mergepairs.output, sample = samples)
	output:
		"results/demux.qza"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/tools_import/log.log"
	params:
		type = "SampleData[SequencesWithQuality]",
		input_format = "CasavaOneEightSingleLanePerSampleDirFmt"
	shell:
		"""
		inputdir=$(dirname {input[0]})

    	qiime tools import \
			--type {params.type} \
			--input-path $inputdir \
			--input-format {params.input_format} \
			--output-path {output} &> {log}
		"""

rule demux_summarize:
	input:
		rules.tools_import.output
	output:
		"results/demux.qzv"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/demux_summarize/log.log"
	shell:
		"""
		qiime demux summarize \
			--i-data {input} \
			--o-visualization {output} &> {log}
		"""

rule dada2_denoise_single:
	input:
		rules.tools_import.output
	output:
		rep_seqs = "results/dada2/rep_seqs.qza",
		table = "results/dada2/table.qza",
		stats = "results/dada2/stats.qza"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/dada2_denoise_single/log.log"
	threads: 8
	params:
		trunc_len = 0
	shell:
		"""
		qiime dada2 denoise-single \
			--i-demultiplexed-seqs {input} \
			--p-trunc-len {params.trunc_len} \
			--p-n-threads {threads} \
			--o-representative-sequences {output.rep_seqs} \
			--o-table {output.table} \
			--o-denoising-stats {output.stats} &> {log}
		"""

rule feature_table_summarize:
	input:
		table = rules.dada2_denoise_single.output.table,
		metadata = config["metadata"]
	output:
		"results/dada2/table.qzv"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/feature_table_summarize/log.log"
	shell:
		"""
		qiime feature-table summarize \
			--i-table {input.table} \
			--o-visualization {output} \
			--m-sample-metadata-file {input.metadata} &> {log}
		"""

rule feature_table_tabulate_seqs:
	input:
		rules.dada2_denoise_single.output.rep_seqs
	output:
		"results/dada2/rep_seqs.qzv"
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/feature_table_tabulate_seqs/log.log"
	shell:
		"""
		qiime feature-table tabulate-seqs \
			--i-data {input} \
			--o-visualization {output} &> {log}
		"""