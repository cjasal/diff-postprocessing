#!/bin/sh

#  Whole_CST_registration.sh
#  
#
#  Created by mary tayebi on 16.02.2022.
#  " Inputs: T1.nii.gz , data.nii.gz , bvecs , bvals

# 1 2 3 4 5 6 7 8 9 10 11 12 14 15 16 18 20 21 22 23 24 26 29 30 32 33 35 36 37 38 39 41 42 43 44 45

for i in  22 ;

do

echo "*******************  START PROCESSING   Pre_${i}  *********************"


singularity run -e \
-B /eresearch/resmed/mtay316/DTI/Concussion_Phase2/Preseason/Processing/b0_synth/INPUTS/Pre_${i}:/INPUTS \
-B /eresearch/resmed/mtay316/DTI/Concussion_Phase2/Preseason/Processing/b0_synth/OUTPUTS/Pre_${i}:/OUTPUTS \
-B /eresearch/resmed/mtay316/DTI/Concussion_Phase2/Preseason/Processing/b0_synth/license.txt:/extra/freesurfer/license.txt \
/hpc/mtay316/B0_synth/synb0-disco_v3.0.sif


echo "De-noising"
mrconvert BIDS/Pre_${i}/dwi/Pre_${i}_dwi.nii -fslgrad BIDS/Pre_${i}/dwi/Pre_${i}_dwi.bvec BIDS/Pre_${i}/dwi/Pre_${i}_dwi.bval BIDS_Processing/Pre_${i}/dwi_${i}.mif

dwidenoise BIDS_Processing/Pre_${i}/dwi_${i}.mif BIDS_Processing/Pre_${i}/dwi_denoise_${i}.mif -noise BIDS_Processing/Pre_${i}/noise_${i}.mif
mrconvert BIDS_Processing/Pre_${i}/dwi_brain_mask_${i}.nii.gz BIDS_Processing/Pre_${i}/dwi_mask_${i}.mif

echo "Bias field correction"
dwibiascorrect fsl BIDS_Processing/Pre_${i}/dwi_denoise_${i}.mif BIDS_Processing/Pre_${i}/dwidnbc_${i}.mif -mask BIDS_Processing/Pre_${i}/dwi_mask_${i}.mif -bias BIDS_Processing/Pre_${i}/bias_${i}.mif

echo "Ringing artifcat correction"
mrdegibbs BIDS_Processing/Pre_${i}/dwidnbc_${i}.mif BIDS_Processing/Pre_${i}/dwidnbcdegibbs_${i}.mif

mrconvert BIDS_Processing/Pre_${i}/dwidnbcdegibbs_${i}.mif BIDS_Processing/Pre_${i}/dwidnbcdg_${i}.nii.gz


# NOTE: Remeber to put the index.txt and acqparams.txt files in the right folder

echo "Eddy current correction"

scp DWI_W_pre/Pre_${i}/index.txt BIDS_Processing/Pre_${i}

eddy_cuda9.1 --imain=BIDS_Processing/Pre_${i}/dwidnbcdg_${i}.nii.gz --mask=BIDS_Processing/Pre_${i}/dwi_brain_mask_${i} --index=BIDS_Processing/Pre_${i}/index.txt --acqp=b0_synth/INPUTS/acqparams.txt --bvecs=BIDS/Pre_${i}/dwi/Pre_${i}_dwi.bvec --bvals=BIDS/Pre_${i}/dwi/Pre_${i}_dwi.bval --fwhm=0 --topup=b0_synth/OUTPUTS/Pre_${i}/topup --flm=quadratic --cnr_maps --out=BIDS_Processing/Pre_${i}/eddy_unwarped_${i} --repol --mporder=6 -v



echo "*******************  FINISH PROCESSING   Pre_${i}  *********************"


done
