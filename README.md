# DTI processing workflow

This repository provides a Snakemake workflow to preprocess diffusion MRI data.


## Installation

*If you are using the [NeSI](https://www.nesi.org.nz) platform, please follow the [NeSI related documentation](NESI.md).*

To run this workflow on your workstation, you need to install the following softwares:

- `mamba`, a fast cross-platform package manager (see [installation instructions](https://mamba.readthedocs.io/en/latest/installation.htm))
- `apptainer`, a container system (see [installation instructions](https://apptainer.org/docs/admin/main/installation.html))
- `snakemake`, the workflow management system (see [installation instructions](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html))
- `git`, the distributed version control system (see [download page](https://git-scm.com/downloads))

Clone this repository using:

```
git clone https://github.com/MataiMRI/diff-processing.git
```

Then edit the configuration file `config/config.yml`, setting the following entries:

- the ethics prefix `ethics_prefix` for your input files,
- the input data folder `datadir`,
- the results folder `resultsdir`,
- the path to your Freesurfer license `fs_license`,
- the path to the aquisition parameter file `aqcparams` and the index file `index` (see [--acqp](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy/UsersGuide#A--acqp) and [--index](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/eddy/UsersGuide#A--index) sections in eddy user guide).
- the path to your `heudiconv` heuristic script (`heuristic` entry under `heudiconv` section).

You may want to edit other entries, in particular:

- for each software, compute resources (time, memory and threads) can be adjusted,
- for some software, additional command line arguments.

Once this configuration is finished, you can run `snakemake` to start the workflow.

Use a dry-run to check that installation and configuration is working:

```
snakemake -n
```


## Formats

The workflow assumes that input scan data are:

- folders or .zip files (you can mix both),
- stored in the `datadir` folder configured `config/config.yml`,
- they are named using the convention `<ethics_prefix>_<subject>_<session>`, where
  - `<ethics_prefix>` is set in [`config/config.yml`](config/config.yml),
  - `<session>` can be omitted, but will then be considered as `a`.

Within a input folder (or .zip file), only the parent folder of DICOM files will be kept when tidying the data.
Any other level of nesting will be ignored.

Once the workflow has completed, results are organised as follows:

```
<resultsdir>
└── bids
    ├── derivatives
    │   └── mriqc
    │       ├── logs
    │       │   └── ...  # log files in case MRIQC crashes
    │       ├── sub-<subject>
    │       │   ├── figures
    │       │   │   ├── sub-<subject>_ses-<session>_<entities>_<suffix>.svg
    │       │   │   └── ...
    │       │   └── ses-<session>
    │       │       ├── <modality>
    │       │       │   └── sub-<subject>_ses-<session>_<entities>_<suffix>.json
    │       │       └── ...
    │       ├── dataset_description.json
    │       ├── quality_control.tsv
    │       ├── sub-<subject>_ses-<session>_qc.yaml
    │       ├── sub-<subject>_ses-<session>_<entities>_<suffix>.html
    │       └── ...
    ├── sub-<subject>
    │   └── ses-<session>
    │       ├── <modality>
    │       │   ├── sub-<subject>_ses-<session>_<entities>_<suffix>.json
    │       │   ├── sub-<subject>_ses-<session>_<entities>_<suffix>.nii.gz
    │       │   └── ...
    │       ├── ...
    │       └── sub-<subject>_ses-<session>_scans.tsv
    ├── CHANGES
    ├── dataset_description.json
    ├── README
    └── scans.json
```

where

- `<resultsdir>` is the results directory configured in `config/config.yaml`
- `<subject>` is a subject,
- `<session>` is a subject's session,
- `<modality>` is a modality (e.g. `anat` or `dwi`),
- `<entities>` are BIDs entities (`task`, `run`, etc.),
- `<suffix>` is a BIDs suffix, either `T1w`, `T2w`, `dwi` or `bold`.

TODO explain the QC files (copy from tidySnake?)

TODO detail the key output files


## Workflow

The complete workflow consists of multiple steps depicted in the following graph.

![Workflow graph](rulegraph.png)

*Workflow graph generated with `snakemake --rulegraph | dot -Tpng > rulegraph.png`.*

The role of each step is the following:

- TODO explain each step (copy some from tidySnake?)

When possible, each step is run independently for each run, task and session of a subject.


## Useful Snakemake options

View steps within workflow using rulegraph:

```
snakemake --forceall --rulegraph | dot -Tpdf > rulegraph.pdf
```

Use the [*local* profile](profiles/local/config.yaml), presetting many options to run the workflow locally:

```
snakemake --profile profiles/local
```

Inform `snakemake` of the maximum amount of memory available on the workstation:

```
snakemake --resources mem=48GB
```

Keep incomplete files (useful for debugging) from fail jobs, instead of wiping them:

```
snakemake --keep-incomplete
```

Run the pipeline until a certain file or rule, e.g. the `bias_correction` rule:

```
snakemake --until bias_correction
```

All these options can be combined and used with a profile, for example:

```
snakemake --profile profiles/local --keep-incomplete --until bias_correction
```

Unlock the folder, in case `snakemake` had to be interrupted abruptly previously:

```
snakemake --unlock
```

*Note: This last hint will be mentioned to you by `snakemake` itself.
Use it only when recommended to to so ;-).*


## Formats

The workflow assumes that input scan data are:

- folders or .zip files (you can mix both),
- stored in the `datadir` folder configured [`config/config.yml`](config/config.yml),
- they are named using the convention `<ethics_prefix>_<subject>_<session>`, where

  - `<ethics_prefix>` is set in [`config/config.yml`](config/config.yml),
  - `<session>` can be omitted, but will then be considered as `a`.

Within a input folder (or .zip file), only the parent folder of DICOM files will be kept when tidying the data.
Any other level of nesting will be ignored.


## Maintenance

TODO replace with currently available environments

The conda environment file [workflow/envs/mri.yaml](workflow/envs/mri.yaml) with pinned versions is generated from a version without versions [workflow/envs/mri_base.yaml](workflow/envs/mri_base.yaml).

You can update it using:

```
conda env create -f workflow/envs/mri_base.yaml -p ./mri_env
conda env export -p ./mri_env --no-builds | grep -v '^prefix:' > workflow/envs/mri.yaml
conda env remove -p ./mri_env
```
