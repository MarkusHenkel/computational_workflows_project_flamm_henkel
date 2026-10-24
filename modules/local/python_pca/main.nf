process PYTHON_PCA {
    tag "$meta.counts_type"
    label "process_single" // pca does not use multithreading

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/matplotlib_numpy_pandas_python_scikit-learn:50344ff37775b8e7' :
        'community.wave.seqera.io/library/matplotlib_numpy_pandas_python_scikit-learn:a5f3c5a900adfcd3'}"

    input:
        tuple val(meta), path(path_count_table_tsv)

    output:
        path("${meta.counts_type}_pca_mqc.png"), emit: pca_plot

    script:
    def count_table = "${path_count_table_tsv}"
    def counts_type = "${meta.counts_type}"
    """
    #!/usr/bin/env python3 

    import numpy as np
    import matplotlib.pyplot as plt
    import pandas as pd
    from sklearn.decomposition import PCA

    # read the tsv into a pandas df
    count_table_df = pd.read_csv("${count_table}", sep="\\t", header=0)


    # get all sample columns (first sample in the third col)
    sample_cols = count_table_df.iloc[:,2:]

    # transpose to go from shape (n_features, n_samples) -> (n_samples, n_features) (scikit-learn pca input)
    sample_cols_transposed = sample_cols.T

    print(sample_cols)
    print(np.shape(sample_cols))

    # perform log transform on raw counts (not on tpm normalized counts) for normalization
    if "${counts_type}" == "gene_raw":
        plot_title = "PCA of log-transformed gene counts"
        sample_cols_transposed = np.log2(1 + sample_cols_transposed)
    elif "${counts_type}" == "gene_tpm":
        plot_title = "PCA of TPM-normalized gene counts"
    else:
        raise ValueError(f"Invalid type of gene counts: ${counts_type}")

    # perform the PCA on the count table values
    pca = PCA(n_components=2)
    coordinates = pca.fit_transform(sample_cols_transposed)

    # plot the PCA and save the figure
    plt.figure(figsize=(10, 8))
    plt.scatter(coordinates[:, 0], coordinates[:, 1])

    # annotate each sample dot in the PCA with its name
    for i, name in enumerate(sample_cols_transposed.index):
        plt.annotate(name, (coordinates[i, 0], coordinates[i, 1]), fontsize=11)

    # add the percentage of explained variance to the axis description e.g. PC2 (20.0%)
    plt.xlabel(f"PC1 ({pca.explained_variance_ratio_[0]*100:.1f}%)")
    plt.ylabel(f"PC2 ({pca.explained_variance_ratio_[1]*100:.1f}%)")
    plt.title(plot_title)
    plt.tight_layout()
    plt.savefig("${counts_type}_pca_mqc.png", dpi=150)

    """
}