snakemake -j 10 -k --use-conda \
    --cluster-config config/cluster.yaml \
    --conda-frontend mamba \
    --rerun-trigger mtime \
    --cluster "sbatch \
        --cpus-per-task={threads} \
        --output={cluster.output} \
        --error={cluster.error} \
        --job-name={cluster.jobname} \
        --mail-user=muhammad.zarulhanifah@monash.edu \
        {cluster.etc}"
