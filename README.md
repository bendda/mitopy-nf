# mitopy-nf

Nextflow implementation of mitopy pipeline. Allows for running the pipeline efficiently on multiple samples.

## How to run

### Prerequisities

To run the pipeline, please install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html) and [Docker](https://docs.docker.com/get-docker/) on your system.

### Input params

* `--alignments` Path to directory containing alignment files (BAM/CRAM format) and respective index files index files 
* `--mt-reference [rCRS|RSRS]` (default: rCRS) Mitochondrial reference genome.
* `--reference-fa` Path to reference genome FASTA. Only required when alignments are in CRAM format. FASTA index and dictionary have to be in the same directory.
* `--outdir` (default: ./outputs) Output directory 

### Run pipeline

```
# Help
nextflow run bendda/mitopy-nf -r main -latest --help
```
```
# Run on  example BAM alignment files located in example_data/ directory
nextflow run bendda/mitopy-nf -r main -latest \
    --alignments 'example_data/*.{bam,bai}' \
    --outdir results

```

### Run on [DNAnexus](https://documentation.dnanexus.com/user/running-apps-and-workflows/running-nextflow-pipelines)

[Import pipeline via CLI](https://documentation.dnanexus.com/user/running-apps-and-workflows/running-nextflow-pipelines#import-via-cli)

```
$ dx build --nextflow \
  --repository https://github.com/bendda/mitopy-nf \
  --destination project-xxxx:/applets/mitopy-nf
```

[Running a Nextflow Pipeline Applet via CLI](https://documentation.dnanexus.com/user/running-apps-and-workflows/running-nextflow-pipelines#import-via-cli)

```
$ dx run project-xxxx:/applets/mitopy-nf \
  -ialignments="dx://project-xxxx:/inputs/*.{bam,bai}" \
  -ioutdir="dx://project-xxxx:/results/" \
  --brief -y
```

### Outputs 

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
├── haplogroup_report
│   ├── sample_haplogroup.txt
├── variant_calls
│   ├── sample.vcf
│   ├── sample.vcf.idx
└── visualization
    ├── sample.html

```