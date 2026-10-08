/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC as FASTQC_1     } from '../modules/nf-core/fastqc/main' 
include { FASTQC as FASTQC_2     } from '../modules/nf-core/fastqc/main' 
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { FASTP                  } from '../modules/nf-core/fastp/main'
include { GUNZIP as GUNZIP_GTF   } from '../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_FASTA } from '../modules/nf-core/gunzip/main'
include { STAR_GENOMEGENERATE    } from '../modules/nf-core/star/genomegenerate/main'
include { STAR_ALIGN_CUSTOM      } from '../modules/local/star/align/main'
// include { UMITOOLS_EXTRACT       } from '../modules/nf-core/umitools/extract/main'
// include { SAMTOOLS_INDEX         } from '../modules/nf-core/samtools/index/main'
// include { UMITOOLS_DEDUP         } from '../modules/nf-core/umitools/dedup/main'
include { GFFREAD_CUSTOM         } from '../modules/local/gffread_custom/main.nf'
include { SALMON_INDEX           } from '../modules/nf-core/salmon/index/main'
include { SALMON_QUANT           } from '../modules/nf-core/salmon/quant/main'
include { CUSTOM_TX2GENE         } from '../modules/nf-core/custom/tx2gene/main'                                                                                                             
include { TXIMETA_TXIMPORT       } from '../modules/nf-core/tximeta/tximport/main'
include { SAMTOOLS_FAIDX         } from '../modules/nf-core/samtools/faidx/main'
include { PICARD_MARKDUPLICATES  } from '../modules/nf-core/picard/markduplicates/main.nf'                                                                                            
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_newrnaseq_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow NEWRNASEQ {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_fasta // channel: path(genome.fasta)
    ch_gtf // channel: path(genome.gtf)
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:

    def ch_versions = channel.empty()
    def ch_multiqc_files = channel.empty()
    
    //
    // MODULE: FASTQC
    //
    FASTQC_1(ch_samplesheet)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_1.out.zip.map{ _meta, file -> file })

    //
    // MODULE: FASTP
    //    
    FASTP(
        ch_samplesheet.map { meta, reads -> [meta, reads, []] }, // meta-map: list of input FastQ files (len: 1=single end, 2=paired end), adapter fasta file
        false, // discard_trimmed_pass
        false, // save_trimmed_fail
        false // save_merged
    )
    // add Fastp output in JSON format to the MultiQC channel
    ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.map{ _meta, file -> file })

    //
    // MODULE: FASTQC
    //
    FASTQC_2(FASTP.out.reads)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC_2.out.zip.map{ _meta, file -> file })

    // 
    // MODULE: GUNZIP_GTF
    // gunzip the GTF first if it is gzipped, STAR cant handle gzipped GTFs
    // 

    // TODO replace hardcoded 'genome' with actually useful identifier for downstream tasks?
    
    // TODO add logic to only unzip if the fasta and gtf are zipped
    ch_gtf_branched = ch_gtf.branch{ meta, _gtf ->
                                        gz:    meta.gz
                                        plain: true
                                    }

    GUNZIP_GTF(ch_gtf_branched.gz)

    ch_gtf_meta_unzipped = GUNZIP_GTF.out.gunzip
                            .map{ meta, gtf -> [meta + [gz: false], gtf] }
                            .mix(ch_gtf_branched.plain)
    // 
    // MODULE: GUNZIP_FASTA
    // gunzip the fasta and GTF first if they are gzipped, STAR cant handle gzipped fastas and GTFs
    // 
    ch_fasta_branched = ch_fasta.branch{ meta, _fasta ->
                                            gz:     meta.gz
                                            plain:  true
                                        }

    GUNZIP_FASTA(ch_fasta_branched.gz)

    ch_fasta_meta_unzipped = GUNZIP_FASTA.out.gunzip
                                .map{ meta, fasta -> [meta + [gz: false], fasta]}
                                .mix(ch_fasta_branched.plain)

    // 
    // MODULE: STAR_GENOMEGENERATE
    // 

    // DEBUG
    ch_samplesheet.dump(tag: "samplesheet")
    ch_fasta.dump(tag: "fasta")
    ch_gtf.dump(tag: "gtf")

    STAR_GENOMEGENERATE(
        ch_fasta_meta_unzipped, // meta and fasta of reference genome
        ch_gtf_meta_unzipped,  // meta and gtf of reference genome
    )
    // get the [meta,index] tuple 
    ch_star_index = STAR_GENOMEGENERATE.out.index
    ch_star_index.dump(tag: "star_index")


    // 
    // MODULE: STAR alignment
    // 

    STAR_ALIGN_CUSTOM(
        ch_samplesheet, // [meta-map, reads] tuple: list of input FastQ files
        ch_star_index.first(), // STAR genome index (STAR_GENOMEGENERATE output)    // here we used first(), so the idx is emitted for each sample 
        ch_gtf_meta_unzipped.first(), // [meta-map, gtf] tuple of reference genome  // here we used first(), so the gtf is emitted for each sample 
        false, // ignore gtf file
    )
    ch_multiqc_files = ch_multiqc_files.mix(STAR_ALIGN_CUSTOM.out.log_final.map { _meta, f -> f })
    ch_star_align_bam_sorted_aligned = STAR_ALIGN_CUSTOM.out.bam_sorted_aligned


    // TODO add scRNAseq support => add flag for UMI extraction and let user set the barcode pattern (bc_pattern param in UMItools extract)
    // // 
    // // MODULE: UMItools extract
    // // 
    // UMITOOLS_EXTRACT(
    //     ch_samplesheet // samplesheet
    // )

    // // 
    // // MODULE: SAMtools index
    // //
    // SAMTOOLS_INDEX(
    //     ch_star_align_bam
    // )
    // ch_samtools_bai = SAMTOOLS_INDEX.out.index

    // // DEBUG
    // ch_star_align_bam.dump(tag: "bam")
    // ch_samtools_bai.dump(tag: "bai")

    // // TODO join bam and bam index channels into one tuple channel for the UMItools dedup step
    // // ch_bam_bai = 

    // // 
    // // MODULE: UMItools dedup
    // // 
    // // UMITOOLS_DEDUP(
    // //     , // [meta, bam, bai] tuple: bam file and bam index file
    // //     true,// get output stats
    // // )

    // 
    // PROCESS: GFFREAD 
    // 
    // to create transcriptome fasta from gtf and genome fasta ourselves (no download, etc. of transcriptome necessary)

    ch_genome_fasta = GUNZIP_FASTA.out.gunzip.map { _meta, fasta -> fasta }

    GFFREAD_CUSTOM(
        ch_gtf_meta_unzipped, // [meta, unzipped gtf] tuple
        ch_genome_fasta // unzipped fasta
    )
    ch_gffread_fasta = GFFREAD_CUSTOM.out.transcriptome_fasta

    // DEBUG 
    ch_gffread_fasta.dump(tag: "gffread_transcriptome_fasta")


    // 
    // MODULE: Salmon index
    //

    ch_salmon_index_input = ch_gffread_fasta
                                .combine(ch_genome_fasta)
                                .map{
                                    transcriptome, reference ->
                                        tuple([id: file(reference).name], transcriptome, reference)
                                }
    
    SALMON_INDEX(
        ch_salmon_index_input // [meta, transcript_fasta, genome_fasta] tuple: genome_fasta optional 
    )
    ch_salmon_index = SALMON_INDEX.out.index
    ch_salmon_index_path = ch_salmon_index.map { _meta, index -> index }
    ch_gft_path = ch_gtf_meta_unzipped.map { _meta , gtf -> gtf }

    // 
    // MODULE: Salmon quantification
    //
    //
    ch_salmon_quant_input = ch_salmon_index_path
                                .combine(ch_gft_path)
                                .combine(ch_gffread_fasta)
                                .map{
                                    index, gtf, transcriptome ->
                                        tuple([id: file(gtf).name], index, gtf, transcriptome)
                                }

    SALMON_QUANT(
        ch_samplesheet,                 // [meta,reads] tuple: fastq files or single bam TODO reads mode or alignment mode
        ch_salmon_quant_input.first()   // [meta, index, gtf, transcript_fasta]: no transcript_fasta in reads mode 
    )
    ch_multiqc_files = ch_multiqc_files.mix(SALMON_QUANT.out.results.map { _meta, dir -> dir })
    ch_salmon_results = SALMON_QUANT.out.results
    ch_salmon_quant_dirs = ch_salmon_results
                                .map { _meta, quant_dir -> quant_dir }
                                .collect()
    ch_salmon_quant_group = ch_salmon_quant_dirs.map { quant_dirs ->
        tuple([id: 'all_samples'], quant_dirs)
    }


    // 
    // MODULE: CUSTOM_TX2GENE
    // 

    CUSTOM_TX2GENE(
        ch_gtf_meta_unzipped.first(),   // [meta, gtf] tuple of meta map of gtf file
        ch_salmon_quant_group,          // all sample quantification directories
        'salmon',                       // type of quantification input
        'gene_id',                      // default
        'gene_name'                     // default
    )
    ch_tx2gene_out = CUSTOM_TX2GENE.out.tx2gene

    // 
    // MODULE: TXIMPORT 
    //
    //for transcript-level counts --> gene-level counts

    TXIMETA_TXIMPORT(
        ch_salmon_quant_group,  // all sample quantification directories
        ch_tx2gene_out,
        'salmon'                // type of quantification input
    )


    // 
    // MODULE: FAIDX
    // 

    ch_faidx_input = ch_fasta_meta_unzipped.map{ meta, fasta -> tuple(meta, fasta, [])}

    SAMTOOLS_FAIDX(
        ch_faidx_input, // self build input of samples, empty fai list
        false           // No need for index size
    )

    ch_fai = SAMTOOLS_FAIDX.out.fai

    // 
    // MODULE: PICARD_MARKDUPLICATES
    // 
    // Picard marks duplicates

    ch_markduplicates_input = ch_fasta_meta_unzipped.join(ch_fai)

    PICARD_MARKDUPLICATES(
        ch_star_align_bam_sorted_aligned,
        ch_markduplicates_input.first()
    )
    ch_multiqc_files = ch_multiqc_files.mix(PICARD_MARKDUPLICATES.out.metrics.map { _meta, f -> f })
    
    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'newrnaseq_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'newrnaseq'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )
    emit:multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]






}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
