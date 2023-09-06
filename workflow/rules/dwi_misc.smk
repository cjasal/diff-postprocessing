rule convert_pre_denoise:
    input:
        "{resultsdir}/bids/sub-{subject}/ses-{session}"
    output:
        "{resultsdir}/bids/derivatives/dwi_preprocessing/derivatives/misc/sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_{entity}_dwi.mif"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    shell:
        "mrconvert {input}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_{wildcards.entity}_dwi.nii.gz "
        "-fslgrad {input}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_{wildcards.entity}_dwi.bvec "
        "{input}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_{wildcards.entity}_dwi.bval "
        "{output}"

rule denoise:
    input:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwi.mif",
    output:
        denoised="{derivatives}/sub-{subject}_ses-{session}_{entity}_dwi_denoise.mif",
        noise="{derivatives}/sub-{subject}_ses-{session}_{entity}_noise.mif"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    threads: config["denoise"]["threads"]
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["denoise"]["mem_mb"],
        time_min=config["denoise"]["time_min"]
    shell:
        "dwidenoise -nthreads {threads} {input} {output.denoised} -noise {output.noise}"

rule fslroi:
    input:
        "{resultsdir}/bids/sub-{subject}/ses-{session}"
    output:
        "{resultsdir}/bids/derivatives/dwi_preprocessing/derivatives/misc/sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_{entity}_nodif.nii.gz"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    shell:
        "fslroi {input}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_{wildcards.entity}_dwi.nii.gz "
        "{output} 0 1"

rule bet:
    input:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_nodif.nii.gz"
    output:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwi_brain_mask.nii.gz"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    shell:
        "bet {input} {output}"

rule convert_pre_bias:
    input:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwi_brain_mask.nii.gz"
    output:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwi_mask.mif"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    shell:
        "mrconvert {input} {output}"

rule bias_correction:
    message: "Bias field correction"
    input:
        data="{derivatives}/sub-{subject}_ses-{session}_{entity}_dwi_denoise.mif",
        mask="{derivatives}/sub-{subject}_ses-{session}_{entity}_dwi_mask.mif",
    output:
        debiased="{derivatives}/sub-{subject}_ses-{session}_{entity}_dwidnbc.mif",
        bias="{derivatives}/sub-{subject}_ses-{session}_{entity}_bias.mif"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    shell:
        "dwibiascorrect fsl {input.data} {output.debiased} -mask {input.mask} -bias {output.bias}"

rule ringing_correction:
    message: "Ringing artifact correction"
    input:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwidnbc.mif"
    output:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwidnbcdegibbs.mif"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    threads: config["ringing_correction"]["threads"]
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["ringing_correction"]["mem_mb"],
        time_min=config["ringing_correction"]["time_min"]
    shell:
        # TODO not working "mrdegibbs -nthreads {threads} {input} {output}"
        "cp {input} {output}"

rule convert_post_ringing:
    input:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwidnbcdegibbs.mif"
    output:
        "{derivatives}/sub-{subject}_ses-{session}_{entity}_dwidnbcdg.nii.gz"
    container:
        "docker://mrtrix3/mrtrix3:3.0.4"
    shell:
        "mrconvert {input} {output}"

rule synb0_disco:
    input:
        bids="{resultsdir}/bids/sub-{subject}/ses-{session}",
        b0="{resultsdir}/bids/derivatives/dwi_preprocessing/derivatives/misc/sub-{subject}/ses-{session}/dwi/sub-{subject}_ses-{session}_{entity}_nodif.nii.gz"
    output:
        directory("{resultsdir}/bids/derivatives/dwi_preprocessing/derivatives/synb0_disco/sub-{subject}_ses-{session}_{entity}")
    container:
        "docker://leonyichencai/synb0-disco:v3.0"
    threads: config["synb0_disco"]["threads"]
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["synb0_disco"]["mem_mb"],
        time_min=config["synb0_disco"]["time_min"]
    shell:
        "workflow/scripts/synb0_disco_pipeline.bash "
        "{config[fs_license]} "
        "{input.bids}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_{wildcards.entity}_T1w.nii.gz "
        "{input.b0} "
        "{config[acqparams]} "
        "{output}"
