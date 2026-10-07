process GFFREAD_CUSTOM {
    // TODO tag ?
    // TODO label ?

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gffread:0.12.7--hdcf5f25_4' :
        'quay.io/biocontainers/gffread:0.12.7--hdcf5f25_4' }"

    input:
        tuple val(meta), path(gtf)
        path fasta

    output:
        path("*.fasta"), emit: transcriptome_fasta

    script:
    def prefix = "${meta.id}"
    """
    gffread -w '${prefix}_transcriptome.fasta' -g ${fasta} ${gtf}
    """
}