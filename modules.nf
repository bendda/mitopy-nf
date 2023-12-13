process PREPROCESS_BAM {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(bam), path(bai)
    tuple path(fasta), path(dict), path(index)
    
    output:
    tuple val(sampleId), path ('*_unmapped.bam'), emit: ubam
    
    """
    if [ "${fasta}" == "" ]; then
        mitopy preprocess --bai ${bai} ${bam}
    else
        mitopy preprocess --bai ${bai} --reference-fa ${fasta} ${bam}
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
    tuple val(sampleId), path('*_dedup.bam'), path('*_dedup.bam.bai'), emit: aligned_bam
    
    """
    mitopy align --ncores ${task.cpus} --mt-ref ${mt_ref} --shifted ${shifted} ${ubam}
    """
}


process CALL_MT {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(bam), path(bai)
    val mt_ref
    val shifted
    
    output:

    tuple val(sampleId), path('*.vcf'), path('*.vcf.idx'), path('*.vcf.stats'), emit: vcf
    
    """
    mitopy call --mt-ref ${mt_ref} --shifted ${shifted} ${bam}
    """
}


process MERGE_CALLS {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(vcf), path(vcf_idx), path(stats), path(vcf_shifted), path(vcf_idx_shifted), path(stats_shifted)
    val mt_ref
    
    output:
    tuple val(sampleId), path('*_merged.vcf'), path('*_merged.vcf.idx'), path('*_merged.vcf.stats'),  emit: merged_vcf
    
    """
    mitopy merge --mt-ref ${mt_ref} --stats ${stats} --stats-shifted ${stats_shifted} ${vcf} ${vcf_shifted}
    """
}


process POSTPROCESS_CALLS {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(vcf), path(vcf_idx), path(stats)
    val mt_ref

    output:
    tuple val(sampleId), path('*_postprocessed.vcf'),  emit: vcf
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
    tuple val(sampleId), path(vcf), path(cov_csv)
    
    output:
    path '*.html', emit: vis_html
    
    """
    mitopy visualize --coverage-csv ${cov_csv} ${vcf}
    """
}


process GET_COVERAGE {
    tag "$sampleId"

    input:
    tuple val(sampleId), path(bam), path(bai), path(bam_shifted), path(bai_shifted)
    
    output:
    tuple val(sampleId), path('*.csv'), emit: cov_csv
    path '*.html', emit: cov_html
    
    """
    mitopy coverage --mt-bai ${bai} --shifted-mt-bai ${bai_shifted} ${bam} ${bam_shifted}
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