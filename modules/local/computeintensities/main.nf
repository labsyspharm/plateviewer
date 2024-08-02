process COMPUTEINTENSITIES {
    label ''

    conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
    //     'biocontainers/YOUR-TOOL-HERE' }"

    input:
    path input

    output:
    stdout               emit: output
    path "versions.yml", emit: versions

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
