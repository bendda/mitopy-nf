# work-in-progress


# Test files

Small WGS bam  (3.3 GB)
``` 
wget https://storage.googleapis.com/gatk-test-data/wgs_bam/NA12878_24RG_b37/NA12878_24RG_small.b37.bam
wget https://storage.googleapis.com/gatk-test-data/wgs_bam/NA12878_24RG_b37/NA12878_24RG_small.b37.bai

```

Medium WGS bam (12.8 GB)
```
wget https://storage.googleapis.com/gatk-test-data/wgs_bam/NA12878_24RG_b37/NA12878_24RG_med.b37.bam
wget https://storage.googleapis.com/gatk-test-data/wgs_bam/NA12878_24RG_b37/NA12878_24RG_med.b37.bai

```

# Input params

* `--alignments` Path to directory containing alignment files (BAM/CRAM format) + index files 
* `--mt-reference [rCRS|RSRS]` (default: rCRS) Mitochondrial reference genome.
* `--reference-fa` Path to reference genome FASTA. Only required when alignments are in CRAM format 
* `--outdir` (default: ./outputs) Output directory 

# How to run

```
# Help
nextflow run bendda/mitopy-nf -r main --help

# Run on bam alignment files located in TEST/ directory
nextflow run bendda/mitopy-nf -r main \
    --alignments 'TEST/*.{bam, bai}' \
    --outdir results

```

# Run on [DNAnexus](https://documentation.dnanexus.com/user/running-apps-and-workflows/running-nextflow-pipelines)

[Import pipeline via CLI](https://documentation.dnanexus.com/user/running-apps-and-workflows/running-nextflow-pipelines#import-via-cli)

```
$ dx build --nextflow \
  --repository https://github.com/bendda/mitopy-nf \
  --destination project-xxxx:/applets/mitopy-nf

Started builder job job-aaaa
Created Nextflow pipeline applet-zzzz

```

[Running a Nextflow Pipeline Applet via CLI](https://documentation.dnanexus.com/user/running-apps-and-workflows/running-nextflow-pipelines#import-via-cli)

```
$ dx run project-xxxx:/applets/mitopy-nf \
  -ialignments="dx://project-xxxx:/inputs/*.{bam,bai}" \
  -ioutdir="dx://project-xxxx:/outputs/"
  --brief -y

job-bbbb

```



# Outputs 

```
outputs/
├── alignments
│   ├── sample_.bam
│   ├── sample.bam.bai
│   ├── sample_multiqc.html 
│   ├── sample.wgs.metrics.txt
│   ├── sample_shifted.bam
│   ├── sample_shifted.bam.bai
│   ├── sample_shifted_multiqc.html 
│   ├── sample_shifted.wgs.metrics.txt
├── annotation
│   ├── sample_annotated.csv
│   ├── sample_annotated.vcf
├── coverage
│   ├── sample_coverage.csv 
│   ├── sample_coverage.html 
├── haplogroup_report
│   ├── sample_haplogroup.txt
├── variant_calls
│   ├── sample.vcf
│   ├── sample.vcf.idx
└── visualization
    ├── sample.html

```