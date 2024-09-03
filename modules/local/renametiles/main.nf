import nextflow.extension.FilesEx

process RENAMETILES {
    input:
    tuple val(meta), val(input)

    output:
    tuple val(meta), path('*.jpg'), emit: images
    path "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    exec:

    def maxLevel = input.collect{ it.getName(it.getNameCount() - 2) as String as int }.max()
    meta << [levels: maxLevel]

    input.each{
        def (_, level, base) = (it =~ $//(\d+)/([^/]+\.jpg)/$)[0]
        def newName = "${maxLevel - (level as int)}_${base}"
        FilesEx.mklink(it, [overwrite: true], task.workDir.resolve(newName))
    }

    file("${task.workDir}/versions.yml").text = """\
    "${task.process}":
        renametiles: 1.0.2
    """.stripIndent()
}
