#!/bin/bash
# This script looks at the output of group ICA and takes the networks specified in networks and binarises them
# It can also add different networks together
# Using these networks it will then mask the already output welch images from welchDir and save the average H
# values of each mask in ${infofile}

highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/
fwhm=8
welchDir=${derDir}welch_and_masking_fwhm_${fwhm}/


outDir=${derDir}bin_network_tissue_func_FWHM_${fwhm}/
[[ -d ${outDir} ]] || mkdir ${outDir}
[[ -d ${outDir}v01 ]] || mkdir ${outDir}v01
[[ -d ${outDir}v02 ]] || mkdir ${outDir}v02


infofile=${derDir}std_welch_in_networks_FWHM_${fwhm}.csv
touch ${infofile}
echo "subject,age,gm_cort_std,visual_std,motor_std,lateral_r_std,brain_stem_std,salient_std,frontal_std,lateral_l_std,hindbrain_std,posterior_std" > ${infofile}



####################################################################
# split up melodic file in ${ICAdir} to separate out networks
####################################################################
#ICADir=${derDir}group_ICA_FWHM_${fwhm}/

#melodicFile=${ICADir}melodic_IC.nii.gz

#fslsplit ${melodicFile} ${outDir}melodic_IC_ -t

##networks to keep
#networks=(1 2 3 4 5 8 9 12 13 14)



#####################################################################
## binarise masks based on above networks array
#####################################################################
#for n in ${networks[@]}; do
#new_n=$(printf "%04d\n" $n)
#binFile=${outDir}melodic_IC_${new_n}.nii.gz
#fslmaths ${binFile} -thr 5 -bin ${outDir}bin_mask_${new_n}
#done
#
#
#####################################################################
## add masks together
#####################################################################
#network1=9
#network2=13
#
#new_network1=$(printf "%04d\n" $network1)
#new_network2=$(printf "%04d\n" $network2)
#
#net1File=${outDir}bin_mask_${new_network1}.nii.gz
#net2File=${outDir}bin_mask_${new_network2}.nii.gz
#
#fslmaths ${net1File} -add ${net2File} -bin ${outDir}bin_mask_${new_network1}_${new_network2}.nii.gz


####################################################################
# binary masks equal to each network
####################################################################
netDir=${derDir}ICA_group_bin_masks_FWHM_${fwhm}/

bin_visual=${netDir}bin_mask_0001.nii.gz
bin_motor=${netDir}bin_mask_0002.nii.gz
bin_lateral_r=${netDir}bin_mask_0003.nii.gz
bin_brain_stem=${netDir}bin_mask_0004.nii.gz
bin_salient=${netDir}bin_mask_0005.nii.gz
bin_frontal=${netDir}bin_mask_0008.nii.gz
bin_lateral_l=${netDir}bin_mask_0009_0013.nii.gz
bin_hindbrain=${netDir}bin_mask_0012.nii.gz
bin_posterior=${netDir}bin_mask_0014.nii.gz



####################################################################
# mask welch outputs and save std to .csv
####################################################################
for ages in ${welchDir}*; do
age=$(basename $ages)

for subjects in ${ages}/*; do
start=$SECONDS
subject=$(basename $subjects)

if [[ ${age} == "v02" ]]; then
if [[ ${subject} == "SK040011" ]] || [[ ${subject} == "SK040020" ]] || [[ ${subject} == "SK040021" ]] || [[ ${subject} == "SK040023" ]] || [[ ${subject} == "SK040025" ]] || [[ ${subject} == "SK040026" ]] || [[ ${subject} == "SK040029" ]] || [[ ${subject} == "SK040032" ]] || [[ ${subject} == "SK040035" ]] || [[ ${subject} == "SK040036" ]] || [[ ${subject} == "SK040037" ]] || [[ ${subject} == "SK040038" ]] || [[ ${subject} == "SK040042" ]] || [[ ${subject} == "SK040043" ]] || [[ ${subject} == "SK040046" ]] || [[ ${subject} == "SK040050" ]] || [[ ${subject} == "SK040051" ]] || [[ ${subject} == "SK040052" ]] || [[ ${subject} == "SK040054" ]] || [[ ${subject} == "SK040058" ]] || [[ ${subject} == "SK040059" ]] || [[ ${subject} == "SK040060" ]] || [[ ${subject} == "SK040061" ]]; then


subDir=${outDir}${age}/${subject}/
mkdir ${subDir}

# find smoothed and resampled func image
smoothDir=${derDir}smoothed_${fwhm}_normalised/${age}/${subject}/
func_image=${smoothDir}/func_normal_resampled.nii.gz

# find GM binary mask
gmDir=${welchDir}${age}/${subject}/
bin_gm_cort=${gmDir}gm_cort_in_standard_bin_no_overlap.nii.gz

func_gm_cort=${subDir}func_gm_cort.nii.gz
func_visual=${subDir}func_visual.nii.gz
func_motor=${subDir}func_motor.nii.gz
func_lateral_r=${subDir}func_lateral_r.nii.gz
func_brain_stem=${subDir}func_brain_stem.nii.gz
func_salient=${subDir}func_salient.nii.gz
func_frontal=${subDir}func_frontal.nii.gz
func_lateral_l=${subDir}func_lateral_l.nii.gz
func_hindbrain=${subDir}func_hindbrain.nii.gz
func_posterior=${subDir}func_posterior.nii.gz


fslmaths ${func_image} -mul ${bin_gm_cort} ${func_gm_cort}
fslmaths ${func_image} -mul ${bin_visual} ${func_visual}
fslmaths ${func_image} -mul ${bin_motor} ${func_motor}
fslmaths ${func_image} -mul ${bin_lateral_r} ${func_lateral_r}
fslmaths ${func_image} -mul ${bin_brain_stem} ${func_brain_stem}
fslmaths ${func_image} -mul ${bin_salient} ${func_salient}
fslmaths ${func_image} -mul ${bin_frontal} ${func_frontal}
fslmaths ${func_image} -mul ${bin_lateral_l} ${func_lateral_l}
fslmaths ${func_image} -mul ${bin_hindbrain} ${func_hindbrain}
fslmaths ${func_image} -mul ${bin_posterior} ${func_posterior}



####################################################################
# use fslmaths to find standard deviation across time
####################################################################
std_gm_cort=${subDir}std_gm_cort.nii.gz
std_visual=${subDir}std_visual.nii.gz
std_motor=${subDir}std_motor.nii.gz
std_lateral_r=${subDir}std_lateral_r.nii.gz
std_brain_stem=${subDir}std_brain_stem.nii.gz
std_salient=${subDir}std_salient.nii.gz
std_frontal=${subDir}std_frontal.nii.gz
std_lateral_l=${subDir}std_lateral_l.nii.gz
std_hindbrain=${subDir}std_hindbrain.nii.gz
std_posterior=${subDir}std_posterior.nii.gz

fslmaths ${func_gm_cort} -Tstd ${std_gm_cort}
fslmaths ${func_visual} -Tstd ${std_visual}
fslmaths ${func_motor} -Tstd ${std_motor}
fslmaths ${func_lateral_r} -Tstd ${std_lateral_r}
fslmaths ${func_brain_stem} -Tstd ${std_brain_stem}
fslmaths ${func_salient} -Tstd ${std_salient}
fslmaths ${func_frontal} -Tstd ${std_frontal}
fslmaths ${func_lateral_l} -Tstd ${std_lateral_l}
fslmaths ${func_hindbrain} -Tstd ${std_hindbrain}
fslmaths ${func_posterior} -Tstd ${std_posterior}



#################################################################################
# add information to the infofile csv
#################################################################################
echo -n "${subject},${age}," >> ${infofile}

echo -n `fslstats ${std_gm_cort} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${std_visual} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${std_motor} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${std_lateral_r} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${std_brain_stem} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${std_salient} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats  ${std_frontal} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats  ${std_lateral_l} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats  ${std_hindbrain} -n -M` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${std_posterior} -n -M` >> ${infofile}
echo "," >> ${infofile}


end=$SECONDS
time_taken=$( jq -n ${end}-${start} )
echo "----- ${subject} finished. Time taken = ${time_taken} seconds-----"

fi
fi
done
done
