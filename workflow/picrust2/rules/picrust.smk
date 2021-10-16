rule place_seqs:
	input:
		asv = "input_folder/dna-sequences.fasta",
		biom = "input_folder/feature-table.biom"
	output:
		tre = "results/out.tre",
		intermediate = temp(directory("intermediate/place_seqs"))
	conda:
		"../envs/picrust.yaml"
	threads: 8
	shell:
		"""
		place_seqs.py -s {input.asv} \
					-o {output.tre} \
					-p {threads} \
					--intermediate {output.intermediate} \
					--verbose
		"""

rule hsp_traits:
	input:
		rules.place_seqs.output.tre
	output:
		"results/{trait}_predicted.tsv.gz"
	conda:
		"../envs/picrust.yaml"
	threads: 8
	shell:
		"""
		hsp.py -i {wildcards.trait} \
				-t {input} \
				-o {output} \
				-p {threads} \
				-n --verbose
		"""

rule functional_metagenome_pipeline:
	input:
		biom = "input_folder/feature-table.biom",
		nsti_hsp = expand(rules.hsp_traits.output, trait = ["16S"]),
		function_hsp = rules.hsp_traits.output
	output:
		unstrat = "results/{trait}_metagenome_out/pred_metagenome_unstrat.tsv.gz",
		strat = "results/{trait}_metagenome_out/pred_metagenome_strat.tsv.gz"
	conda:
		"../envs/picrust.yaml"
	threads: 8
	shell:
		"""
		outdir=$(dirname {output})

		metagenome_pipeline.py -i {input.biom} \
								-m {input.nsti_hsp} \
								-f {input.function_hsp} \
								-o $outdir --strat_out --wide_table
		"""

rule functional_add_descriptions:
	input:
		unstrat = rules.functional_metagenome_pipeline.output.unstrat,
		strat = rules.functional_metagenome_pipeline.output.strat
	output:
		unstrat = "{trait}_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz",
		strat = "{trait}_metagenome_out/pred_metagenome_strat_descrip.tsv.gz"
	conda:
		"../envs/picrust.yaml"
	threads: 8
	shell:
		"""
		add_descriptions.py -i {input.unstrat} \
							-m {wildcards.trait} \
							-o {output.unstrat}

		add_descriptions.py -i {input.strat} \
							-m {wildcards.trait} \
							-o {output.strat}
		"""

rule pathway_metagenome_pipeline:
	input:
		expand(rules.functional_metagenome_pipeline.output.strat, trait = ["EC"])
	output:
		unstrat = "pathways_out/path_abun_unstrat.tsv.gz",
		strat = "pathways_out/path_abun_strat.tsv.gz"
	conda:
		"../envs/picrust.yaml"
	threads: 8
	shell:
		"""
		outdir=$(dirname {output})

		pathway_pipeline.py -i {input} \
							-o $outdir \
							-p {threads} 
							--verbose --wide_table
		"""

rule pathway_add_descriptions:
	input:
		unstrat = rules.pathway_metagenome_pipeline.output.unstrat,
		strat = rules.pathway_metagenome_pipeline.output.strat
	output:
		unstrat = "pathways_out/path_abun_unstrat_descrip.tsv.gz",
		strat = "pathways_out/path_abun_strat_descrip.tsv.gz"
	conda:
		"../envs/picrust.yaml"
	threads: 8
	params:
		trait = "METACYC"
	shell:
		"""
		add_descriptions.py -i {input.unstrat} \
							-m {params.trait} \
							-o {output.unstrat}

		add_descriptions.py -i {input.strat} \
							-m {params.trait} \
							-o {output.strat}
		"""
