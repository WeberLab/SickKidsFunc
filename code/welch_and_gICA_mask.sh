#!/bin/bash
# This script looks at the output of group ICA and takes the networks specified in networks and binarises them
# It can also add different networks together
# Using these networks it will then mask the already output welch images from welchDir and save the average H
# values of each mask in ${infofile}

highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/
fwhm=8
welchDir=${derDir}welch_and_masking_fwhm_${fwhm}/


ICADir=${derDir}group_ICA_FWHM_${fwhm}/
outDir=${derDir}ICA_group_bin_masks_FWHM_${fwhm}/
[[ -d ${outDir} ]] || mkdir ${outDir}
[[ -d ${outDir}v01 ]] || mkdir ${outDir}v01
[[ -d ${outDir}v02 ]] || mkdir ${outDir}v02


infofile=${derDir}mean_welch_in_networks_FWHM_${fwhm}.csv
touch ${infofile}
echo "subject,age,visual_m,visual_std,motor_m,motor_std,lateral_r_m,lateral_r_std,brain_stem_m,brain_stem_std,salient_m,salient_std,frontal_m,frontal_std,lateral_l_m,lateral_l_std,hindbrain_m,hindbrain_std,posterior_m,posterior_std" > ${infofile}



####################################################################
# split up melodic file in ${ICAdir} to separate out networks
####################################################################
melodicFile=${ICADir}melodic_IC.nii.gz

fslsplit ${melodicFile} ${outDir}melodic_IC_ -t

#networks to keep
networks=(1 2 3 4 5 8 9 12 13 14)



####################################################################
# binarise masks based on above networks array
####################################################################
for n in ${networks[@]}; do
new_n=$(printf "%04d\n" $n)
binFile=${outDir}melodic_IC_${new_n}.nii.gz
fslmaths ${binFile} -thr 5 -bin ${outDir}bin_mask_${new_n}
done



####################################################################
# add masks together
####################################################################
network1=9
network2=13

new_network1=$(printf "%04d\n" $network1)
new_network2=$(printf "%04d\n" $network2)

net1File=${outDir}bin_mask_${new_network1}.nii.gz
net2File=${outDir}bin_mask_${new_network2}.nii.gz

fslmaths ${net1File} -add ${net2File} -bin ${outDir}bin_mask_${new_network1}_${new_network2}.nii.gz



####################################################################
# binary masks equal to each network
####################################################################
bin_visual=${outDir}bin_mask_0001.nii.gz
bin_motor=${outDir}bin_mask_0002.nii.gz
bin_lateral_r=${outDir}bin_mask_0003.nii.gz
bin_brain_stem=${outDir}bin_mask_0004.nii.gz
bin_salient=${outDir}bin_mask_0005.nii.gz
bin_frontal=${outDir}bin_mask_0008.nii.gz
bin_lateral_l=${outDir}bin_mask_0009_0013.nii.gz
bin_hindbrain=${outDir}bin_mask_0012.nii.gz
bin_posterior=${outDir}bin_mask_0014.nii.gz



####################################################################
# mask welch outputs and save mean and std to .csv
####################################################################
for ages in ${welchDir}*; do
age=$(basename $ages)

for subjects in ${ages}/*; do
start=$SECONDS
subject=$(basename $subjects)

subDir=${outDir}${age}/${subject}/
mkdir ${subDir}

welch_func=${subjects}/func_normal_resampled_Hurst_Welch.nii.gz

welch_visual=${subDir}welch_visual.nii.gz
welch_motor=${subDir}welch_motor.nii.gz
welch_lateral_r=${subDir}welch_lateral_r.nii.gz
welch_brain_stem=${subDir}welch_brain_stem.nii.gz
welch_salient=${subDir}welch_salient.nii.gz
welch_frontal=${subDir}welch_frontal.nii.gz
welch_lateral_l=${subDir}welch_lateral_l.nii.gz
welch_hindbrain=${subDir}welch_hindbrain.nii.gz
welch_posterior=${subDir}welch_posterior.nii.gz

fslmaths ${welch_func} -mul ${bin_visual} ${welch_visual}
fslmaths ${welch_func} -mul ${bin_motor} ${welch_motor}
fslmaths ${welch_func} -mul ${bin_lateral_r} ${welch_lateral_r}
fslmaths ${welch_func} -mul ${bin_brain_stem} ${welch_brain_stem}
fslmaths ${welch_func} -mul ${bin_salient} ${welch_salient}
fslmaths ${welch_func} -mul ${bin_frontal} ${welch_frontal}
fslmaths ${welch_func} -mul ${bin_lateral_l} ${welch_lateral_l}
fslmaths ${welch_func} -mul ${bin_hindbrain} ${welch_hindbrain}
fslmaths ${welch_func} -mul ${bin_posterior} ${welch_posterior}



#################################################################################
# add information to the infofile csv
#################################################################################
echo -n "${subject},${age}," >> ${infofile}

echo -n `fslstats ${welch_visual} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_visual} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_motor} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_motor} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_lateral_r} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_lateral_r} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_brain_stem} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_brain_stem} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_salient} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_salient} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats  ${welch_frontal} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats  ${welch_frontal} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats  ${welch_lateral_l} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats  ${welch_lateral_l} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats  ${welch_hindbrain} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats  ${welch_hindbrain} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_posterior} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_posterior} -n -S` >> ${infofile}
echo "," >> ${infofile}



end=$SECONDS
time_taken=$( jq -n ${end}-${start} )
echo "----- ${subject} finished. Time taken = ${time_taken} minutes-----"

done
done
