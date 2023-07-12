#!/bin/sh

#  Script.sh
#  
#
#  Created by Maryam Tayebi on 01/04/21.
#  
# Run hd-bet for multiple subjects
source /hpc/mtay316/vir_envs/hpc5-py3/bin/activate

for i in 26  ;
do

hd-bet -i T1_W_post/${i}/Post_${i}.nii.gz -o T1_W_post/T1_Brain/Post_${i}_brain -tta 0 -mode fast -device cpu
  
done


# 01 02 03 04 05 07 09 10 11 14 16 18 22 24 29 30 32 33 38 39 42 44
