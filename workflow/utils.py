from pathlib import Path

import yaml
from snakemake.io import glob_wildcards


def filter_session(resultsdir, subject, session, entity):
    qc_file = Path(
        f"{resultsdir}/bids/derivatives/mriqc/"
        f"/sub-{subject}_ses-{session}_{entity}_qc.yaml"
    )
    qc_data = yaml.safe_load(qc_file.read_text())
    qc_fields = [field for field in qc_data if field.endswith("_qc")]
    is_valid = all(qc_data[field] for field in qc_fields)

    return is_valid


def list_sessions(resultsdir):
    patterns = glob_wildcards(
        f"{resultsdir}/bids/derivatives/mriqc/"
        "/sub-{subject}_ses-{session}_{entity}_qc.yaml"
    )

    subjects, sessions, entities = [], [], []
    for subject, session, entity in zip(*patterns):
        if filter_session(resultsdir, subject, session, entity):
            subjects.append(subject)
            sessions.append(session)
            entities.append(entity)

    return subjects, sessions, entities
