rule qiime_tools_import:
	input:
		expand(rules.mergepairs.output, sample = samples)
	output:
		"results/demux.qza"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/qiime_tools_import/log.log"
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
			--output-path {output} 2> {log}
		"""

rule qiime_demux_summarize:
	input:
		rules.qiime_tools_import.output
	output:
		"results/demux.qzv"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/qiime_demux_summarize/log.log"
	shell:
		"""
		qiime demux summarize \
			--i-data {input} \
			--o-visualization {output}
		"""

rule qiime_dada2_denoise-single:
	input:
		rules.qiime_tools_import.output
	output:
		rep_seqs = "results/dada2/rep_seqs.qza",
		table = "results/dada2/table.qza",
		stats = "results/dada2/stats.qza"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/qiime_dada2_denoise-single/log.log"
	threads: 8
	params:
		trunc_len = 0,
	shell:
		"""
		qiime dada2 denoise-single \
			--i-demultiplexed-seqs {input} \
			--p-trunc-len {params.trunc_len} \
			--p-n-threads {threads} \
			--o-representative-sequences {output.rep_seqs} \
			--o-table {output.table} \
			--o-denoising-stats {output.stats}
		"""

