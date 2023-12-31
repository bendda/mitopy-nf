include { PREPROCESS_BAM; 
            MERGE_CALLS; 
            POSTPROCESS_CALLS; 
            ANNOTATE; 
            VISUALIZE;
            GET_COVERAGE;
            IDENTIFY_HAPLOGROUP } from './modules.nf'

include { ALIGN_MT as ALIGN_MT_DEFAULT } from './modules.nf'
include { ALIGN_MT as ALIGN_MT_SHIFTED } from './modules.nf'
include { CALL_MT as CALL_MT_DEFAULT } from './modules.nf'
include { CALL_MT as CALL_MT_SHIFTED } from './modules.nf'



def help(){
    log.info """
    Mitochondrial variant detection and analysis pipeline

    Usage:
        nextflow run bendda/mitopy-nf [options]

    Script Options:
        --alignments        REGEX       Path to the directory with alignments in BAM or CRAM format.
        --mt-reference      STR         Mitochondrial reference genome. Currently, rCRS and RSRS references are supported (default: $params.mt_reference)
        --reference-fa      STR         Path to reference genome FASTA. Only required if input alignments are in CRAM format. FASTA index and dictionary have to be in the same directory.
        --outdir            DIR         Path for output (default: $params.outdir)
    """.stripIndent()
}


workflow {

    if (params.help) {
        help()
        exit 1
    }

    if (!params.alignments) {
        println("--alignments param required. Please provide path to alignment files.")
        exit 1
    }    

    // prepare reference genome
    reference = [[], [], []]
    if (params.reference_fa) {
        fasta = file("${params.reference_fa}", type:'file', checkIfExists:true)
        dict  = file("${fasta.getParent()}/${fasta.baseName}.dict", type:'file', checkIfExists:true)
        index = file("${params.reference_fa}.fai", type:'file', checkIfExists:true)

        reference = [fasta, dict, index]
    }


    alignments = Channel.fromFilePairs(params.alignments).map { it ->
        def bam = it[1].find { f -> f.name.endsWith('bam') || f.name.endsWith('cram') }
        def bai = it[1].find { f -> f.name.endsWith('bai') || f.name.endsWith('crai')}
        [it[0], bam, bai] 
    
    }

    // preprocess alignments
    PREPROCESS_BAM(alignments, reference)

    // align to mt reference
    ALIGN_MT_DEFAULT(PREPROCESS_BAM.out.ubam, params.mt_reference, false)

    // align to shifted mt reference
    ALIGN_MT_SHIFTED(PREPROCESS_BAM.out.ubam, params.mt_reference, true)

    // call variants in non-control region
    CALL_MT_DEFAULT(ALIGN_MT_DEFAULT.out.aligned_bam, params.mt_reference, false)

    // call variants in control region 
    CALL_MT_SHIFTED(ALIGN_MT_SHIFTED.out.aligned_bam, params.mt_reference, true)

    // merge calls
    vcf_channel = CALL_MT_DEFAULT.out.vcf.join(CALL_MT_SHIFTED.out.vcf)
    MERGE_CALLS(vcf_channel, params.mt_reference)

    // filter and normalize raw variant calls
    POSTPROCESS_CALLS(MERGE_CALLS.out.merged_vcf, params.mt_reference)

    // annotate variants
    ANNOTATE(POSTPROCESS_CALLS.out.vcf)

    // get coverage
    bam_channel = ALIGN_MT_DEFAULT.out.aligned_bam.join(ALIGN_MT_SHIFTED.out.aligned_bam)
    GET_COVERAGE(bam_channel)

    // visualize variants
    vis_channel = POSTPROCESS_CALLS.out.vcf.join(GET_COVERAGE.out.cov_csv)
    VISUALIZE(vis_channel)

    // identify haplogroup
    IDENTIFY_HAPLOGROUP(POSTPROCESS_CALLS.out.vcf, params.mt_reference)
    
}


