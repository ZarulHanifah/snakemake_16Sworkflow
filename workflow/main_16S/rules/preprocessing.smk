rule trimming:
	input:
		r1 = os.path.join(config["fastq_path"], "{}")
		r2 = os.path.join(config["fastq_path"], "{}")
	output:
		r1 = temp("results/preprocessing/trimming/{}.fastq"),
		r2 = temp("results/preprocessing/trimming/{}.fastq")
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/trimming/{}.log"
	params:
		fwd_primer_seq = config["fwd_primer_seq"],
		rvs_primer_seq = config["rvs_primer_seq"]
	shell:
		"""
		cutadapt -g {params.fwd_primer_seq} -G {params.rvs_primer_seq} \
				-o {output.r1} -p {output.r2} \
				{input.r1} {input.r2} 2> {log}
		"""

rule mergepairs:
	input:
		r1 = rules.trimming.output.r1,
		r2 = rules.trimming.output.r2
	output:
		temp("results/preprocessing/merge/{}.fastq")
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/mergepairs/{}.log"
	shell:
		"""
		vsearch --fastq_mergepairs {input.r1} \
				--reverse {input.r2} \
				--fastqout {output} 2> {log}
		"""