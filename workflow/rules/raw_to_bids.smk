from pathlib import Path

include: "list_scans.smk"

MAPPING = list_scans(config["datadir"], config["ethics_prefix"])
SUBJECTS, SESSIONS = zip(*MAPPING)

rule all:
    localrule: True
    input:
        expand(
            expand(
                "{{resultsdir}}/bids/sub-{subject}/ses-{session}",
                zip,
                subject=SUBJECTS,
                session=SESSIONS,
            ),
            resultsdir=config["resultsdir"],
        )

rule unzip:
    input:
        expand("{datadir}/{{folder}}.zip", datadir=config['datadir'])
    output:
        directory(expand("{datadir}/{{folder}}", datadir=config['datadir']))
    shell:
        "unzip -q -d {output} {input}"

rule tidy_dicoms:
    input:
        lambda wildards: MAPPING[(wildards.subject, wildards.session)]
    output:
        directory("{resultsdir}/tidy/sub_{subject}/ses_{session}")
    run:
        output_folder = Path(output[0])
        for dicom_file in Path(input[0]).rglob("*.dcm"):
            target_folder = output_folder / dicom_file.parent.name
            target_folder.mkdir(parents=True, exist_ok=True)
            (target_folder / dicom_file.name).symlink_to(dicom_file)

checkpoint heudiconv:
    input:
        "{resultsdir}/tidy/sub_{subject}/ses_{session}"
    output:
        directory("{resultsdir}/bids/sub-{subject}/ses-{session}"),
        directory("{resultsdir}/bids/.heudiconv/{subject}/ses-{session}")
    container:
        "docker://ghcr.io/jennan/heudiconv:jpeg2000_ci"
    threads: config["heudiconv"]["threads"]
    resources:
        cpus=lambda wildcards, threads: threads,
        mem_mb=config["heudiconv"]["mem_mb"],
        time_min=config["heudiconv"]["time_min"]
    shell:
        "heudiconv "
        "--dicom_dir_template '{wildcards.resultsdir}/tidy/sub_{{subject}}/ses_{{session}}/*/*' "
        "--outdir {wildcards.resultsdir}/bids "
        "--heuristic {config[heudiconv][heuristic]} "
        "--subjects {wildcards.subject} "
        "--ses {wildcards.session} "
        "--converter dcm2niix "
        "--bids "
        "--overwrite"
