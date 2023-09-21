rule fastqc:
    input:
        indir = config["fastq_dir_path"],
        metadata = ancient(config["metadata"])
    output:
        temp(directory("results/preprocessing/fastqc/{sample}"))
    conda:
        "../envs/multiqc.yaml"
    log:
        "results/log/fastqc/{sample}.log"
    shell:
        """
        pref=$(awk -v var={wildcards.sample} '$1 == var {{print $3}}' {input.metadata})

        r1=$(find {input.indir} | grep $pref"_S" | grep "_R1_001.fastq.gz")
        r2=$(find {input.indir} | grep $pref"_S" | grep "_R2_001.fastq.gz")
		
        mkdir -p {output}
        fastqc -o {output} $r1 $r2 2> {log}
        """

rule multiqc:
    input:
        expand(rules.fastqc.output, sample = samples)
    output:
        directory("results/preprocessing/multiqc")
    conda:
        "../envs/multiqc.yaml"
    log:
        "results/log/multiqc/log.log"
    shell:
        """
        multiqc -o {output} {input} 2> {log}
        """

