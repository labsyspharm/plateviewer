/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { COMPUTEINTENSITIES     } from '../modules/local/computeintensities'
include { DZPLATEVIEWER          } from '../modules/local/dzplateviewer'
include { RENAMETILES            } from '../modules/local/renametiles'
include { MINERVASTORY           } from '../modules/local/minervastory'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_plateviewer_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

import groovy.xml.XmlParser


def parseDzi(Path xml_file) {
    def p = new XmlParser().parseText(xml_file.text)
    return [width: p.Size[0].@Width as int, height: p.Size[0].@Height as int]
}

def getWellDimensions(int numSites) {
    def width = Math.ceil(Math.sqrt(numSites)) as int
    def height = Math.ceil(numSites / width) as int
    return [width: width, height: height]
}


workflow PLATEVIEWER {

    take:
    images

    main:

    ch_versions = Channel.empty()

    images
        .map{ meta, image -> [meta.subMap('channel'), image] }
        .groupTuple()
        .dump(tag: 'ch_channel_images')
        .set{ ch_channel_images }

    ch_channel_images
        | COMPUTEINTENSITIES
    ch_versions = ch_versions.mix(COMPUTEINTENSITIES.out.versions)

    ch_channel_images
        .join(
            COMPUTEINTENSITIES.out.intensities
                .map{ meta, csv -> [meta, csv.splitCsv(header: true).first()] }
        )
        .combine(
            images
                .map{ meta, image -> meta.site as int }
                .max()
                .map{ getWellDimensions(it) }
        )
        .dump(tag: 'DZPLATEVIEWER_in')
        | DZPLATEVIEWER
    ch_versions = ch_versions.mix(DZPLATEVIEWER.out.versions)

    DZPLATEVIEWER.out.images
        | RENAMETILES
    ch_versions = ch_versions.mix(RENAMETILES.out.versions)

    DZPLATEVIEWER.out.dzi
        .first()
        .map{ meta, dzi -> parseDzi(dzi) }
        .combine(
            RENAMETILES.out.images
                .map{ meta, images -> meta }
        )
        .map{ meta1, meta2 ->
            def meta = meta1 + meta2
            def c = meta.remove('channel')
            [meta, [channel: c]]
        }
        .groupTuple()
        .dump(tag: 'MINERVASTORY_in')
        | MINERVASTORY
    ch_versions = ch_versions.mix(MINERVASTORY.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
