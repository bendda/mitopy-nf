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
        --reference-fa      STR         Path to reference genome FASTA. Only required if input alignments are in CRAM format.
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

    alignments = Channel.fromFilePairs(params.alignments).map { it ->
        def bam = it[1].find { f -> f.name.endsWith('bam') || f.name.endsWith('cram') }
        def bai = it[1].find { f -> f.name.endsWith('bai') || f.name.endsWith('crai')}
        [it[0], bam, bai] 
    
    }

    // preprocess alignments
    PREPROCESS_BAM(alignments, params.ref_fasta)

    // align to mt reference
    ALIGN_MT_DEFAULT(PREPROCESS_BAM.out.ubam, params.mt_reference, false)

    // align to shifted mt reference
    ALIGN_MT_SHIFTED(PREPROCESS_BAM.out.ubam, params.mt_reference, true)

    // call variants in non-control region
    CALL_MT_DEFAULT(ALIGN_MT_DEFAULT.out.aligned_bam, params.mt_reference, false)

    // call variants in control region 
    CALL_MT_SHIFTED(ALIGN_MT_SHIFTED.out.aligned_bam, params.mt_reference, true)

    // collect vcfs and stats
    vcf_channel = CALL_MT_DEFAULT.out.vcf.join(CALL_MT_SHIFTED.out.vcf)
    vcf_stats_channel = CALL_MT_DEFAULT.out.stats.join(CALL_MT_SHIFTED.out.stats)

    // merge calls
    MERGE_CALLS(vcf_channel.join(vcf_stats_channel), params.mt_reference)

    // filter and normalize raw variant calls
    POSTPROCESS_CALLS(MERGE_CALLS.out.merged_vcf, MERGE_CALLS.out.merged_stats, params.mt_reference)

    // annotate variants
    ANNOTATE(POSTPROCESS_CALLS.out.vcf)

    // get coverage
    GET_COVERAGE(ALIGN_MT_DEFAULT.out.aligned_bam, ALIGN_MT_SHIFTED.out.aligned_bam, ALIGN_MT_DEFAULT.out.aligned_bai, ALIGN_MT_SHIFTED.out.aligned_bai)

    // visualize variants
    VISUALIZE(POSTPROCESS_CALLS.out.vcf, GET_COVERAGE.out.cov_csv)

    // identify haplogroup
    IDENTIFY_HAPLOGROUP(POSTPROCESS_CALLS.out.vcf, params.mt_reference)
    
}


