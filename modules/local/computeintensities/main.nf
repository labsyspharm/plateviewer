process COMPUTEINTENSITIES {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
    //     'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path('intensities.csv'),     emit: intensities
    tuple val(meta), path('intensities_all.csv'), emit: intensities_all
    path "versions.yml",                          emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def ch = meta.channel
    def args = [
        task.ext.args ?: '',
        "-j $task.cpus",
        "-i $input",
        "-o intensities.csv",
        "-c intensities_all.csv",
    ].join(' ')

    """
    compute_intensities.py $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plateviewer: 1.0.0
    END_VERSIONS
    """

}
