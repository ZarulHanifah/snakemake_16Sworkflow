# snakemake_16Sworkflow

My Snakemake implementation for 16S analysis. If you have snakemake installed, then all other software installation will be managed by Snakemake.

# How to visualise the data
If you find "qzv" files, you can visualize it one [QIIME 2 View](https://view.qiime2.org/)

# How snakemake works on this QIIME2 pipeline

There will be a few "pitstops" in the pipeline where some information needs to be added into config.yaml.

Subsequent to the denoising step, the feature table needs to have an even number of reads per sample for normalised downstream analyses. This can be achieved by subsamping reads, which needs a set read depth per sample to be determined.

- You can set small number of reads per sample to retain as much samples...
	- and you might be keeping samples with inadequate reads to represent the sample.
- Or, set a high read depth to only retain samples with sufficient reads...
	- but you might end up with little number of samples to work with.

So, you have to make the call. First, visualize `filt_table.qzv` to determine highest number of reads found in a sample. If you have this number, fill it in config.yaml (`config["read_depth"]["highest"]`).

This will be used to draw a rarefaction curve with the highest possible number of reads (`mock_alpha_rarefaction.qzv`).

By visualizing the rarefaction curves, you should be able to determine whether the number of reads are adequate to at least plateaue the alpha diversity (whether you pretty much "found everyone" in your sample). If you achieve this, good. If not, it is your call.

But let's say if:
	- Rarefactions plateaued at 10k reads
	- 2/100 samples were at 1k reads, and did not plateaue
	- The next sample of lowest read depth is 20k reads, and it plateaue

Then I would subsample number of reads to 20k to maximise as much read depth while including as much samples. If the two samples are very crucial, maybe I would request a topup of the reads.

Fill in the config.yaml (`config["read_depth"]["lowest"]). Then the pipeline will continue the downstream analyses.
