process COMPUTEINTENSITIES {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
    //     'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path('*_intensities.csv'), path('*_intensities_all.csv'), emit: intensities
    path "versions.yml"                                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def ch = meta.channel
    def args = [
        task.ext.args ?: '',
        "-j $task.cpus",
        "-i $input",
        "-o ch${ch}_intensities.csv",
        "-c ch${ch}_intensities_all.csv",
    ].join(' ')

    """
    compute_intensities.py $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plateviewer: 1.0.0
    END_VERSIONS
    """

}
