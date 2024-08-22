/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { COMPUTEINTENSITIES     } from '../modules/local/computeintensities'
include { DZPLATEVIEWER          } from '../modules/local/dzplateviewer'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_plateviewer_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

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

    COMPUTEINTENSITIES.out.intensities
        .map{ meta, csv -> [meta, csv.splitCsv(header: true).first()] }
        .join(ch_channel_images)
        .map{ meta, intensities, images -> [meta, images, intensities] }
        .dump(tag: 'DZPLATEVIEWER_in')
        | DZPLATEVIEWER
    ch_versions = ch_versions.mix(DZPLATEVIEWER.out.versions)

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
