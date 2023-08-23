#!/bin/bash

# ensure script fails if any command fails
set -e

# fetch input/output path from command line parameters
if [[ $# -lt 4 ]]; then
    echo "Expected 4 arguments"
    echo "Usage: ./synb0_disco_pipeline.bash FS_LICENSE INPUTS_NIFTI INPUTS_B0 INPUTS_ACQPARAMS OUTPUTS [--notopup] [--stripped]"
    exit 1
fi

FS_LICENSE="$1"; shift
INPUTS_NIFTI="$1"; shift
INPUTS_B0="$1"; shift
INPUTS_ACQPARAMS="$1"; shift
OUTPUTS="$1"; shift

TOPUP=1
MNI_T1_1_MM_FILE=/extra/atlases/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz

for arg in "$@"
do
    case $arg in
        -i|--notopup)
            TOPUP=0
	        ;;
    	-s|--stripped)
	        MNI_T1_1_MM_FILE=/extra/atlases/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz
            ;;
    esac
done

# Copy/link freesurfer in a temporary folder, in order to replace the license file
export FREESURFER_HOME="$(mktemp -d -t freesurfer-XXXXX)"
trap 'rm -rf -- "$FREESURFER_HOME"' EXIT
echo "Setting FREESURFER_HOME=$FREESURFER_HOME"

ln -s /extra/freesurfer/* "${FREESURFER_HOME}"
cp -f "${FS_LICENSE}" "${FREESURFER_HOME}/license.txt"

# Set path for executable
export PATH=$PATH:/extra

# Set up freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# Set up FSL
. /extra/fsl/etc/fslconf/fsl.sh
export PATH=$PATH:/extra/fsl/bin
export FSLDIR=/extra/fsl

# Set up ANTS
export ANTSPATH=/extra/ANTS/bin/ants/bin/
export PATH=$PATH:$ANTSPATH:/extra/ANTS/ANTs/Scripts

# Set up pytorch
source /extra/pytorch/bin/activate

# Prepare input
bash -e /extra/prepare_input.sh "${INPUTS_B0}" "${INPUTS_NIFTI}" $MNI_T1_1_MM_FILE /extra/atlases/mni_icbm152_t1_tal_nlin_asym_09c_2_5.nii.gz "${OUTPUTS}"

# Run inference
NUM_FOLDS=5
for i in $(seq 1 $NUM_FOLDS);
  do echo Performing inference on FOLD: "$i"
  python3.6 /extra/inference.py "${OUTPUTS}"/T1_norm_lin_atlas_2_5.nii.gz "${OUTPUTS}"/b0_d_lin_atlas_2_5.nii.gz "${OUTPUTS}"/b0_u_lin_atlas_2_5_FOLD_"$i".nii.gz /extra/dual_channel_unet/num_fold_"$i"_total_folds_"$NUM_FOLDS"_seed_1_num_epochs_100_lr_0.0001_betas_\(0.9\,\ 0.999\)_weight_decay_1e-05_num_epoch_*.pth
done

# Take mean
echo Taking ensemble average
fslmerge -t "${OUTPUTS}"/b0_u_lin_atlas_2_5_merged.nii.gz "${OUTPUTS}"/b0_u_lin_atlas_2_5_FOLD_*.nii.gz
fslmaths "${OUTPUTS}"/b0_u_lin_atlas_2_5_merged.nii.gz -Tmean "${OUTPUTS}"/b0_u_lin_atlas_2_5.nii.gz

# Apply inverse xform to undistorted b0
echo Applying inverse xform to undistorted b0
antsApplyTransforms -d 3 -i "${OUTPUTS}"/b0_u_lin_atlas_2_5.nii.gz -r "${INPUTS_B0}" -n BSpline -t ["${OUTPUTS}"/epi_reg_d_ANTS.txt,1] -t ["${OUTPUTS}"/ANTS0GenericAffine.mat,1] -o "${OUTPUTS}"/b0_u.nii.gz

# Smooth image
echo Applying slight smoothing to distorted b0
fslmaths "${INPUTS_B0}" -s 1.15 "${OUTPUTS}"/b0_d_smooth.nii.gz

if [[ $TOPUP -eq 1 ]]; then
    # Merge results and run through topup
    echo Running topup
    fslmerge -t "${OUTPUTS}"/b0_all.nii.gz "${OUTPUTS}"/b0_d_smooth.nii.gz "${OUTPUTS}"/b0_u.nii.gz
    topup -v --imain="${OUTPUTS}"/b0_all.nii.gz --datain="${INPUTS_ACQPARAMS}" --config=b02b0.cnf --iout="${OUTPUTS}"/b0_all_topup.nii.gz --out="${OUTPUTS}"/topup --subsamp=1,1,1,1,1,1,1,1,1 --miter=10,10,10,10,10,20,20,30,30 --lambda=0.00033,0.000067,0.0000067,0.000001,0.00000033,0.000000033,0.0000000033,0.000000000033,0.00000000000067 --scale=0
fi


# Done
echo FINISHED!!!
