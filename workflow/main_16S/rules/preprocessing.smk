rule trimming:
	input:
		config["fastq_dir_path"]
	output:
		r1 = temp("results/preprocessing/trimming/{sample}_R1_.fastq"),
		r2 = temp("results/preprocessing/trimming/{sample}_R2_.fastq")
	conda:
		"../envs/qiime2-2021.8.yaml"
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
				$r1 $r2 2>> {log}
		"""

rule mergepairs:
	input:
		r1 = rules.trimming.output.r1,
		r2 = rules.trimming.output.r2
	output:
		temp("results/preprocessing/merge/{sample}.fastq")
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/mergepairs/{sample}.log"
	shell:
		"""
		vsearch --fastq_mergepairs {input.r1} \
				--reverse {input.r2} \
				--fastqout {output} 2> {log}
		"""