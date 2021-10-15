rule allignment_mafft:
	input:
		rules.filter_rep_seqs_nonmicrobial.output
	output:
		"results/tree/aligned_rep_seqs.qza"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/allignment_mafft/log.log"
	shell:
		"""
		qiime alignment mafft \
			--i-sequences {input} \
			--o-alignment {output} &> {log}
		"""

rule allignment_mask:
	input:
		rules.allignment_mafft.output
	output:
		"results/tree/masked_aligned_rep_seqs.qza"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/allignment_mask/log.log"
	shell:
		"""
		qiime alignment mask \
			--i-alignment {input} \
			--o-masked-alignment {output} &> {log}
		"""

rule phylogeny_fasttree:
	input:
		rules.allignment_mask.output
	output:
		"results/tree/unrooted_tree.qza"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/phylogeny_fasttree/log.log"
	shell:
		"""
		qiime phylogeny fasttree \
			--i-alignment {input} \
			--o-tree {output} &> {log}
		"""	
    
rule phylogeny_midpoint_root:
	input:
		rules.phylogeny_fasttree.output
	output:
		"results/tree/rooted_tree.qza"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/phylogeny_midpoint_root/log.log"
	shell:
		"""
		qiime phylogeny midpoint-root \
			--i-tree {input} \
			--o-rooted-tree {output} &> {log}
		"""

rule mock_diversity_alpha_rarefaction:
	input:
		table = rules.filter_table_nonmicrobial.output,
		tree = rules.phylogeny_midpoint_root.output,
		metadata = config["metadata"]
	output:
		"results/mock_diversity_alpha_rarefaction.qzv"
	conda:
		"../envs/qiime2-2021.8.yaml"
	log:
		"results/log/mock_diversity_alpha_rarefaction/log.log"
	params:
		max_depth = config["read_depth"]["highest"],
		metrics = "observed_features chao1 faith_pd shannon simpson_e",
		steps = 100
	shell:
		"""
		metrics=$(for i in {params.metrics} ; do echo " --p-metrics "$i ; done | tr "\n" " ")
		
		qiime diversity alpha-rarefaction \
			--i-table {input.table} \
			--i-phylogeny {input.tree} \
			--p-max-depth {params.max_depth} \
			$metrics \
			--p-steps {params.steps} \
			--m-metadata-file {input.metadata} \
			--o-visualization {output} &> {log}
		"""	
