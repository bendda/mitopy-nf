process PREPROCESS_BAM {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(bam), path(bai)
    val ref_fasta  
    
    output:
    tuple val(sampleId), path ('*_unmapped.bam'), emit: ubam
    
    """
    if [ "${ref_fasta}" == "" ]; then
        mitopy preprocess --bai ${bai} ${bam}
    else
        mitopy preprocess --bai ${bai} --reference-fa ${ref_fasta} ${bam}
    fi
    """
}


process ALIGN_MT {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(ubam)
    val mt_ref
    val shifted
    
    output:
    tuple val(sampleId), path('*_dedup.bam'), emit: aligned_bam
    tuple val(sampleId), path('*_dedup.bam.bai'), emit: aligned_bai
    path '*.wgs.metrics.txt', emit: wgs_metrics
    path '*_multiqc.html', emit: multiqc
    
    """
    mitopy align --ncores ${task.cpus} --mt-ref ${mt_ref} --shifted ${shifted} ${ubam}
    """
}


process CALL_MT {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(bam)
    val mt_ref
    val shifted
    
    output:

    tuple val(sampleId), path('*.vcf'), emit: vcf
    tuple val(sampleId), path('*.vcf.idx'), emit: vcf_idx
    tuple val(sampleId), path('*.vcf.stats'), emit: stats
    
    """
    mitopy call --mt-ref ${mt_ref} --shifted ${shifted} ${bam}
    """
}


process MERGE_CALLS {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(vcf), path(vcf_shifted), path(stats), path(stats_shifted)
    val mt_ref
    
    output:
    tuple val(sampleId), path('*_merged.vcf'), emit: merged_vcf
    tuple val(sampleId), path('*_merged.vcf.idx'), emit: merged_vcf_idx
    tuple val(sampleId), path('*_merged.vcf.stats'), emit: merged_stats
    
    """
    mitopy merge --mt-ref ${mt_ref} --stats ${stats} --stats-shifted ${stats_shifted} ${vcf} ${vcf_shifted}
    """
}


process POSTPROCESS_CALLS {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(vcf)
    tuple val(sampleId), path(stats)
    val mt_ref

    output:
    tuple val(sampleId), path('*_postprocessed.vcf'), emit: vcf
    tuple val(sampleId), path('*_postprocessed.vcf.idx'), emit: vcf_idx
    
    """
    mitopy postprocess ${task.ext.args} --mt-ref ${mt_ref} --stats ${stats} ${vcf}
    """
}


process ANNOTATE {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(vcf)
    
    output:
    path '*_annotated.vcf', emit: vcf
    path '*_annotated.csv', emit: csv
    
    """
    mitopy annotate ${vcf}
    """
}


process VISUALIZE {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(vcf)
    tuple val(sampleId), path(cov_csv)
    
    output:
    path '*.html', emit: vis_html
    
    """
    mitopy visualize --coverage-csv ${cov_csv} ${vcf}
    """
}


process GET_COVERAGE {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(bam)
    tuple val(sampleId), path(bam_shifted)
    tuple val(sampleId), path(bai)
    tuple val(sampleId), path(bai_shifted)
    
    output:
    tuple val(sampleId), path('*.csv'), emit: cov_csv
    path '*.html', emit: cov_htm
    
    """
    mitopy per-base-coverage --mt-bai ${bai} --shifted-mt-bai ${bai_shifted} ${bam} ${bam_shifted}
    """
}


process IDENTIFY_HAPLOGROUP {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(vcf)
    val mt_ref
    
    output:
    path '*_haplogroup.txt', emit: haplogroup

    """
    mitopy identify-haplogroup --mt-ref ${mt_ref} ${vcf}
    """
}