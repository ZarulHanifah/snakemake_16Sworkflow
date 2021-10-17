rule trimming:
	input:
		config["fastq_dir_path"]
	output:
		r1 = temp("results/preprocessing/trimming/{sample}_R1_.fastq"),
		r2 = temp("results/preprocessing/trimming/{sample}_R2_.fastq")
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/trimming/{sample}.log"
	params:
		fwd_primer_seq = config["fwd_primer_seq"],
		rvs_primer_seq = config["rvs_primer_seq"]
	shell:
		"""
		r1=$(find {input} | grep {wildcards.sample}"_" | grep "_R1_")
		r2=$(find {input} | grep {wildcards.sample}"_" | grep "_R2_")
		
		echo "R1: "$r1 > {log}
		echo "R2: "$r2 >> {log}

		cutadapt -g {params.fwd_primer_seq} -G {params.rvs_primer_seq} \
				-o {output.r1} -p {output.r2} \
				$r1 $r2 &> {log}
		"""

rule mergepairs:
	input:
		r1 = rules.trimming.output.r1,
		r2 = rules.trimming.output.r2
	output:
		uncomp = temp("results/preprocessing/merge/{sample}_XXX_L001_R1_001.fastq"),
		comp = temp("results/preprocessing/merge/{sample}_XXX_L001_R1_001.fastq.gz")
	conda:
		"../envs/qiime2-2021.2.yaml"
	log:
		"results/log/mergepairs/{sample}.log"
	shell:
		"""
		vsearch --fastq_mergepairs {input.r1} \
				--reverse {input.r2} \
				--fastqout {output.uncomp} &> {log}

		cat {output.uncomp} | gzip > {output.comp}
		"""

rule tools_import:
	input:
		expand(rules.mergepairs.output.comp, sample = samples)
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
		report("results/demux.qzv", caption = "../report/demux_summarize.rst", category = "Preprocessing")
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
