process DZPLATEVIEWER {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
    //     'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val(meta), path(input, stageAs: 'input/*'), val(intensities), val(wellDims)

    output:
    tuple val(meta), path('*_files/*/*.jpg'), emit: images
    tuple val(meta), path('*.dzi')  , emit: dzi
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def ch = meta.channel
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: 'output'

    """
    makeplatemontage.py \\
        input \\
        -o . \\
        -r $task.cpus \\
        -p 12 8 \\
        -w $wellDims.width $wellDims.height \\
        -m 2048 2048 \\
        -t 1024 \\
        -c $ch \\
        -f $prefix \\
        -I $intensities.Vmin $intensities.Vmax \\
        --pattern '*_{well}_s{field+1}_w{channel}????????-*.tif' \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dzplateviewer: 1.0.0
    END_VERSIONS
    """

}
