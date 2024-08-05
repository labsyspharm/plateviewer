process DZPLATEVIEWER {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
    //     'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val(meta), path(input, stageAs: 'images/*'), val(intensities)

    output:
    tuple val(meta), path('output/*'), emit: output

    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def ch = meta.channel
    def args = task.ext.args ?: ''

    """
    makeplatemontage.py \\
        images \\
        -o output \\
        -r $task.cpus \\
        -p 12 8 \\
        -w 3 3 \\
        -m 2048 2048 \\
        -t 1024 \\
        -c $ch \\
        -f ch$ch \\
        -I $intensities.Vmin $intensities.Vmax \\
        --pattern '*_{well}_s{field+1}_w{channel}????????-*.tif'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dzplateviewer: 1.0.0
    END_VERSIONS
    """

}
