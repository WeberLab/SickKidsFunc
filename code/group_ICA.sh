#!/bin/bash
# Create subject file by looking at the outputs in ${smoothDir} based on ${fwhm}
# reun group ICA on these subjects with the ${refMask} and the output in ${outDir}
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/


fwhm=8
refMask=${highDir}40w_dHCP_template_mask.nii.gz


smoothDir=${derDir}smoothed_${fwhm}_normalised/


outDir=${derDir}group_ICA_FWHM_${fwhm}
[[ -d ${outDir} ]] || mkdir ${outDir}


subFile=${derDir}group_ICA_sub_info__FWHM_${fwhm}.txt
rm -r ${subFile}
touch ${subFile}



#################################################################################
# starting to loop through subjects from the smoothed folder
#################################################################################
for ages in ${smoothDir}*; do
age=$(basename ${ages})

for subjects in ${smoothDir}${age}/*; do

func=${subjects}/func_normal_resampled.nii.gz
[[ -f ${func} ]] && echo "${func}" >> ${subFile}

done
done




melodic \
 -i ${subFile} \
 -o ${outDir} \
 --tr=3.0 \
 --nobet \
 -a concat \
 -m ${refMask} \
 --report \
 --Oall \
 -d 20



