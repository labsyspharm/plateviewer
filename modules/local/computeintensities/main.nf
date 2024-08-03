process COMPUTEINTENSITIES {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
    //     'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), stdout, emit: intensities
    path "versions.yml"    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = [
        task.ext.args ?: '',
        "-j $task.cpus",
        "-i $input",
    ].join(' ')

    """
    compute_intensities.py $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plateviewer: 1.0.0
    END_VERSIONS
    """

}
