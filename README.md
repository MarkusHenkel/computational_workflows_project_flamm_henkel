# nf-core/newrnaseq

## Introduction
<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

**nf-core/newrnaseq** is a bioinformatics pipeline that can be used to analyse bulk RNA single- and paired-end sequencing data (no UMIs) obtained from organisms with a reference genome and annotation. It takes a samplesheet with FASTQ files as input, performs quality control (QC), trimming and alignment, and produces a gene expression matrix and extensive QC report.

## Pipeline Overview

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/community/brand/workflow-schematics#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

Per default, the pipeline computes the following steps:

1. Read QC ([`FastQC` nf-core module](https://nf-co.re/modules/fastqc))
2. Unzipping of FastQ, GTF and genome Fasta files ([`GUNZIP` nf-core module](https://nf-co.re/modules/gunzip))
3. Generating index for genome Fasta ([`samtools` nf-core module](https://nf-co.re/modules/samtools_faidx))
2. Trimming of adapters ([`fastp` nf-core module](https://nf-co.re/modules/fastp))
3. Trimmed read QC ([`FastQC` nf-core module](https://nf-co.re/modules/fastqc))
4. Quantification ([`Salmon` nf-core modules](https://nf-co.re/modules/salmon_quant))
5. Gene-level counts ([`tximport` nf-core modules](https://nf-co.re/modules/tximeta_tximport))
4. Alignment ([`STAR` nf-core modules](https://nf-co.re/modules/star_align))
5. Mark duplicate reads ([`Picard` nf-core modules](https://nf-co.re/modules/picard_markduplicates/))
6. Present pipeline results summary ([`MultiQC` nf-core module](https://nf-co.re/modules/multiqc))


## Usage

<!-- > [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data. -->

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate): -->





### Introduction

<!-- TODO nf-core: Add documentation about anything specific to running your pipeline. For general topics, please point to (and add to) the main nf-core website. -->

In order to run the pipeline, a samplesheet and a reference genome is required. 
The pipeline supports the input of a reference genome both by name (via iGenomes) and by a combination of Fasta and GTF files. The respective 

### Samplesheet input


You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. 
It has to be a comma-separated file with 3 columns and a header row.
Each row represents a fastq file (single-end) or a pair of fastq files (paired end).
Example:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,forward
```


Use this parameter to specify its location. 

```bash
--input '[path to samplesheet file]'
```

<!-- #### Multiple runs of the same sample

The `sample` identifiers have to be the same when you have re-sequenced the same sample more than once e.g. to increase sequencing depth. The pipeline will concatenate the raw reads before performing any downstream analysis. Below is an example for the same sample sequenced across 3 lanes:

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP1,AEG588A1_S1_L003_R1_001.fastq.gz,AEG588A1_S1_L003_R2_001.fastq.gz
CONTROL_REP1,AEG588A1_S1_L004_R1_001.fastq.gz,AEG588A1_S1_L004_R2_001.fastq.gz
``` -->

#### Full samplesheet

The pipeline will auto-detect whether a sample is single- or paired-end using the information provided in the samplesheet. The samplesheet can have as many columns as you desire, however, there is a strict requirement for the first 4 columns to match those defined in the table below.

A final samplesheet file consisting of both single- and paired-end data may look something like the one below. Make sure that all sample IDs are unique,

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2, strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,auto
CONTROL_REP2,AEG588A2_S2_L002_R1_001.fastq.gz,AEG588A2_S2_L002_R2_001.fastq.gz,reverse
CONTROL_REP3,AEG588A3_S3_L002_R1_001.fastq.gz,AEG588A3_S3_L002_R2_001.fastq.gz,reverse
TREATMENT_REP1,AEG588A4_S4_L003_R1_001.fastq.gz,forward
TREATMENT_REP2,AEG588A5_S5_L003_R1_001.fastq.gz,forward
TREATMENT_REP3,AEG588A6_S6_L003_R1_001.fastq.gz,AEG588A6_S6_L004_R1_001.fastq.gz,auto
```

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina short reads 1. Gzipping is optional, however if file `fastq_2` is zipped then `fastq_1` has to be gzipped as well. File extension has to be either ".fastq.gz"/".fq.gz" or  ".fastq"/".fq" if the file is zipped or not zipped respectively.                                                             |
| `fastq_2` | Full path to FastQ file for Illumina short reads 2. Gzipping is optional, however if file `fastq_1` is zipped then `fastq_2` has to be gzipped as well. File extension has to be either ".fastq.gz"/".fq.gz" or ".fastq"/".fq" if the file is zipped or not zipped respectively.                                                             |
|`strandedness`| String indicating the strandedness of the reads. Has to be one of: `forward`, `reverse`, `auto`. Choose `auto` if strandedness should be determined automatically by Salmon (more specifically the SALMON_QUANT step). |

<!-- TODO link sometimes works and sometimes doesnt immediately afterwards -->
An [example samplesheet](Semester_2/biomedical_data/computational_workflows_project_flamm_henkel/assets/samplesheet.csv) has been provided with the pipeline.

### Running the pipeline

The typical command for running the pipeline is as follows:

<!-- ```bash
nextflow run nf-core/newrnaseq --input ./samplesheet.csv --outdir ./results --genome GRCh37 -profile docker
``` -->

```bash
nextflow run nf-core/newrnaseq \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --genome <igenome_name>
```

where `igenome_name` is one of the following: 

- Ensembl / NCBI / UCSC-based (human):

  - GRCh37
  - GRCh38
  - CHM13
  - hg38
  - hg19

- Mouse:

  - GRCm38
  - mm10

- Other species (Ensembl):

  - TAIR10
  - EB2
  - UMD3.1
  - WBcel235
  - CanFam3.1
  - GRCz10
  - BDGP6
  - EquCab2
  - EB1
  - Galgal4
  - Gm01
  - Mmul_1
  - IRGSP-1.0
  - CHIMP2.1.4
  - Rnor_5.0
  - Rnor_6.0
  - R64-1-1
  - EF2
  - Sbi1
  - Sscrofa10.2
  - AGPv3

- Other species (UCSC):

  - bosTau8
  - ce10
  - canFam3
  - danRer10
  - dm6
  - equCab2
  - galGal4
  - panTro4
  - rn6
  - susScr3
 
<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

Or if instead of choosing an iGenome, specify a Fasta and GTF file of the reference genome:
```bash
nextflow run nf-core/newrnaseq \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --gtf <file.gtf> \
   --fasta <genome.fasta>
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```
<!-- 
If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/running/run-pipelines#configuring-pipelines), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/newrnaseq -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: './samplesheet.csv'
outdir: './results/'
genome: 'GRCh37'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch). -->

<!-- #### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/newrnaseq
``` -->

<!-- #### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/newrnaseq releases page](https://github.com/nf-core/newrnaseq/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles. -->

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

<!-- > [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported. -->

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow `24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

<!-- ### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information. -->

<!-- ## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#set-max-resources) and [customise process resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#customize-process-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#update-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#modifying-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs). -->

### Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

<!-- 
## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```



Now, you can run the pipeline using:

```bash
nextflow run nf-core/newrnaseq \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --genome <igenome_name>
```

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->
<!-- 
or if instead of choosing a previously listed iGenome, specify a Fasta and GTF file of the reference genome:
```bash
nextflow run nf-core/newrnaseq \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR> \
   --gtf <file.gtf> \
   --fasta <genome.fasta>
``` -->

<!-- > [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/running/run-pipelines#using-parameter-files). -->

 <!-- For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/newrnaseq/usage) and the [parameter documentation](https://nf-co.re/newrnaseq/parameters).  -->

# nf-core/newrnaseq: Output

## Introduction


The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.



### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://docs.seqera.io/platform-cloud/reports/overview) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

### Salmon

<details markdown="1">
<summary>Output files</summary>

- `salmon/`
- `<sample>/`: folder containing the quantification results for a specific sample. One per sample.
- `*_lib_format_counts.json`: file containing the library format counts. One per sample
- `*_meta_info.json`: File containing meta information from Salmon quant. One per sample

</details>

[Salmon](https://combine-lab.github.io/salmon/) quantifies transcript abundance from RNA-seq reads using quasi-mapping, which does not require a full alignment. It also estimates the library type (strandedness) of each sample. The per-sample results are summarised in the MultiQC report and used by tx2gene and tximeta.

### tximeta

<details markdown="1">
<summary>Output files</summary>

- `tximeta/`
- `all_samples.gene_counts_length_scaled.tsv`: Count values derived from tximport output after summarizeToGene(), with a ‘countsFromAbundance’ specification of ‘lengthScaledTPM’ over all samples.
- `all_samples.gene_counts.tsv`: Count values derived from tximport output after summarizeToGene() over all samples.
- `all_samples.gene_lengths.tsv`: Length values derived from tximport output after summarizeToGene() over all samples.
- `all_samples.gene_tpm.tsv`: Abundance (TPM) values derived from tximport output after summarizeToGene() over all samples.
- `all_samples.transcript_counts.tsv`: Count values derived from tximport output over all samples.
- `all_samples.transcript_lengths.tsv`: Length values derived from tximport output over all samples.
- `all_samples.transcript_tpm.tsv`: Abundance (TPM) values derived from tximport output over all samples.
- `all_samples.tx2gene_augmented.tsv`: tx2gene transcript-to-gene mapping table actually used by tximport.

</details>

[tximeta](https://bioconductor.org/packages/tximeta/) summarises transcript-level estimates by Salmon to gene level.

### Python

<details markdown="1">
<summary>Output files</summary>

- `python/`
- `*_pca_mqc.png`: PCA plot of the samples.

</details>

A custom Python script that performs a principal component analysis (PCA) on the expression data to give an overview of how the samples relate to each other, for example whether replicates cluster together and whether there are outliers or batch effects. The directory is called `python/`, even though the process that produces these files is called `PYTHON_PCA`.



## Outputs specific to set flags

Depending on if `--skipTrimming`, `--skipAlignment` or both were set some tools aren't used. 

### FastQC
<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>
If trimming is skipped only the second [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) run will be done hence it will only contain QC of the raw reads and the FastQC report of trimmed reads will be missing.

### fastp

<details markdown="1">
<summary>Output files</summary>

- `fastp/`
- `*.fastp.html`: results in HTML format.
- `*.fastp.json`: results in JSON format, used by MultiQC.
- `*.fastp.log`: log file of the fastp run.
- `*.fastp.fastq.gz`: trimmed reads. 

</details>

[fastp](https://github.com/OpenGene/fastp) is a fast all-in-one preprocessing tool for FASTQ files. It performs adapter trimming. The trimmed reads are passed on to the following steps and the second FastQC run.



### STAR


<details markdown="1">
<summary>Output files</summary>

- `star/`
- `*.Aligned.sortedByCoord.out.bam`: sorted BAM file of read alignments.
- `*.Aligned.toTranscriptome.out.bam`: output BAM file of transcriptome alignment.
- `*.Log.final.out`: STAR final log file.
- `*.Log.out`: STAR log out file.
- `*.Log.progress.out`: STAR log progress file.
- `*.SJ.out.tab`: STAR output splice junction tab file.

</details>

[STAR](https://github.com/alexdobin/STAR) is a software package for mapping DNA sequences against a large reference genome, such as the human genome. In this pipeline it is used to align reads to a reference genome. The `*.Log.final.out` files are parsed by MultiQC and shown in the report.


### Picard

<details markdown="1">
<summary>Output files</summary>

- `picard/`
- `*.bam`: BAM file with duplicate reads marked. One per sample.
- `*.metrics.txt`: Duplicate metrics file generated. One per sample.

</details>

[Picard](https://broadinstitute.github.io/picard/) is used to mark duplicate reads and to collect RNA-seq specific alignment metrics. The metrics files are parsed by MultiQC and shown in the report.

<!-- TODO: list the Picard modules that are actually run (e.g. MarkDuplicates, CollectRnaSeqMetrics) -->





## Credits

nf-core/newrnaseq was originally written by Benedikt Flamm and Markus Henkel.

<!-- We thank the following people for their extensive assistance in the development of this pipeline: -->

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

<!-- ## Contributions and Support -->

<!-- If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#newrnaseq` channel](https://nfcore.slack.com/channels/newrnaseq) (you can join with [this invite](https://nf-co.re/join/slack)). -->




## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/newrnaseq for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

<!-- An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x). -->


1. Andrews S. (2010). FastQC: a quality control tool for high throughput sequence data. https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
2. Broad Institute. Picard Toolkit. GitHub repository. https://broadinstitute.github.io/picard/
3. Shifu Chen, Yanqing Zhou, Yaru Chen, Jia Gu, fastp: an ultra-fast all-in-one FASTQ preprocessor, Bioinformatics, Volume 34, Issue 17, September 2018, Pages i884–i890, https://doi.org/10.1093/bioinformatics/bty560 
4. Petr Danecek, James K Bonfield, Jennifer Liddle, John Marshall, Valeriu Ohan, Martin O Pollard, Andrew Whitwham, Thomas Keane, Shane A McCarthy, Robert M Davies, Heng Li, Twelve years of SAMtools and BCFtools, GigaScience, Volume 10, Issue 2, February 2021, giab008, https://doi.org/10.1093/gigascience/giab008 
5. Alexander Dobin, Carrie A. Davis, Felix Schlesinger, Jorg Drenkow, Chris Zaleski, Sonali Jha, Philippe Batut, Mark Chaisson, Thomas R. Gingeras, STAR: ultrafast universal RNA-seq aligner, Bioinformatics, Volume 29, Issue 1, January 2013, Pages 15–21, https://doi.org/10.1093/bioinformatics/bts635 
6. Philip Ewels, Måns Magnusson, Sverker Lundin, Max Käller, MultiQC: summarize analysis results for multiple tools and samples in a single report, Bioinformatics, Volume 32, Issue 19, October 2016, Pages 3047–3048, https://doi.org/10.1093/bioinformatics/btw354 
7. Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen. _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
8. GNU gzip. https://www.gnu.org/software/gzip/
9. Love MI, Soneson C, Hickey PF, Johnson LK, Pierce NT, et al. (2020) Tximeta: Reference sequence checksums for provenance identification in RNA-seq. PLOS Computational Biology 16(2): e1007664. https://doi.org/10.1371/journal.pcbi.1007664
10. Patro, R., Duggal, G., Love, M. et al. Salmon provides fast and bias-aware quantification of transcript expression. Nat Methods 14, 417–419 (2017). https://doi.org/10.1038/nmeth.4197
