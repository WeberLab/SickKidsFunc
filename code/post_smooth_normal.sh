#!/bin/bash
#This file looks at all the subjects in ${inputDir} and adds them to ${initial_csv}
#If the subject has a func scan then the FD will be computed and added
#The length of the scan in seconds will also be added
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/

dhcpDir=${derDir}dhcp_func_output/
single_age="v02"


# for no smoothing, set fwhm=0
fwhm=3
normmean=10000

standard_ref=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/derivatives/dhcp_func_output/v02/sub-MS040064/ses-session1/qc/standard-1.5mm.nii.gz

outDir=${derDir}smoothed_${fwhm}_normalised/

[[ -d ${outDir} ]] || mkdir ${outDir}
[[ -d ${outDir}v01 ]] || mkdir ${outDir}v01
[[ -d ${outDir}v02 ]] || mkdir ${outDir}v02



if [[ ${fwhm} -eq 0 ]]; then
smooth_var=2
else
smooth_var=1
fi



#################################################################################
## start looping through subjects
#################################################################################
for ages in ${dhcpDir}*; do
age=$(basename $ages)
if [[ ${age} == ${single_age} ]]; then

for subjects in ${ages}/*; do
subject_base=$(basename $subjects)
subject=${subject_base:4}

subDir=${subjects}/ses-session1/
sub_outDir=${outDir}${age}/${subject}/
[[ -d ${sub_outDir} ]] || mkdir ${sub_outDir}/

if [[ -f ${outDir}${age}/${subject}/func_normal_resampled.nii.gz ]]; then
continue
fi

echo "----- ${subject} started-----"
start=`date +%M`


#################################################################################
## warp func into standard space & resample
#################################################################################
func_mc_warp=${subDir}reg/func-mc_to_standard/func-mc_to_standard_warp.nii.gz
func_mcdc_warp=${subDir}reg/func-mcdc_to_standard/func-mcdc_to_standard_warp.nii.gz
[[ -f ${func_mc_warp} ]] && func_warp=${func_mc_warp} || func_warp=${func_mcdc_warp}

func_img_old=${sub_outDir}warpedfunc_to_standard.nii.gz
applywarp \
--ref=${standard_ref} \
--in=${subDir}denoise/func_clean.nii.gz \
--out=${func_img_old} \
--warp=${func_warp} \
--interp=spline

func_mc_ref=${subDir}reg/func-mc_to_standard/func-mc_to_standard_img.nii.gz
func_mcdc_ref=${subDir}reg/func-mcdc_to_standard/func-mcdc_to_standard_img.nii.gz
[[ -f ${func_mc_ref} ]] && func_ref=${func_mc_ref} || func_ref=${func_mcdc_ref}
echo "Step 1 of 3"

func_img=${func_img_old}



################################################################################
# warp func mask to standard space
################################################################################
mask_img_old=${sub_outDir}warpedfunc_to_standard_mask.nii.gz
applywarp \
--ref=${standard_ref} \
--in=${subDir}denoise/mask.nii.gz \
--out=${mask_img_old} \
--warp=${func_warp} \
--interp=spline

echo "Step 2 of 3"



################################################################################
# binarise warped mask and mask warped func
################################################################################
mask_old=${sub_outDir}func_mask_old.nii.gz
func_mean=${sub_outDir}func_mean.nii.gz

fslmaths ${mask_img_old} -thr 0.5 -bin ${mask_old}
fslmaths ${func_img} -Tmean ${func_mean}

mask=${sub_outDir}func_mask_old.nii.gz

echo "Step 3 of 3"



################################################################################
# find values at different thresholds
################################################################################
func_masked=${func_img}
func_q2=$(fslstats ${func_masked} -k ${mask} -p 2)
func_q98=$(fslstats ${func_masked} -k ${mask} -p 98)
func_q50=$(fslstats ${func_masked} -k ${mask} -p 50)



################################################################################
# set up input parameters for susan
################################################################################
sigma=$( jq -n ${fwhm}/2.355)
inter_thr=$( jq -n ${func_q50}-${func_q2})
susan_thr=$( jq -n ${inter_thr}*0.75)

if [[ ${smooth_var} -eq 1 ]]; then
func_smooth=${sub_outDir}funcsmooth
susan ${func_masked} ${susan_thr} ${sigma} 3 1 1 ${func_mean} ${susan_thr} ${func_smooth}
else
func_smooth=${func_img}
fi



################################################################################
# FEAT-style intensity normalisation
################################################################################
func_normal=${sub_outDir}func_normal
scaling=$( jq -n ${normmean}/${func_q50})
fslmaths ${func_smooth} -mul ${scaling} ${func_normal}

flirt -in ${func_normal} -ref ${func_ref} -out ${sub_outDir}func_normal_resampled -applyxfm

rm -r ${func_img_old}
rm -r ${mask_img_old}
rm -r ${mask_old}
rm -r ${func_mean}
rm -r ${func_masked}
rm -r ${sub_outDir}funcsmooth_usan_size.nii.gz


end=`date +%M`
time_taken=$( jq -n ${end}-${start} )
echo "----- ${subject} finished. Time taken = ${time_taken} minutes-----"
done
fi
done

