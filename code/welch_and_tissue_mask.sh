#!/bin/bash
#This file looks at all the subjects in ${inputDir} and adds them to ${initial_csv}
#If the subject has a func scan then the FD will be computed and added
#The length of the scan in seconds will also be added
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/


fwhm=8
smoothDir=${derDir}smoothed_${fwhm}_normalised/


dseg_ref=${derDir}dhcp_func_output/v02/sub-MS040064/ses-session1/qc/standard-dseg-1.5mm.nii.gz



outDir=${derDir}welch_and_masking_fwhm_${fwhm}/
[[ -d ${outDir} ]] || mkdir ${outDir}
[[ -d ${outDir}v01 ]] || mkdir ${outDir}v01
[[ -d ${outDir}v02 ]] || mkdir ${outDir}v02



infofile=${derDir}mean_welch_in_tissues_FWHM_${fwhm}.csv
touch ${infofile}
echo "subject,age,csf mean,csf std,gm cort mean,gm cort std,wm mean,wm std,cereb mean,cereb std,gm deep mean,gm deep std,gm cort mean no-overlap,gm cort std no-overlap,wm mean no-overlap,wm std no-overlap" > ${infofile}



#if run_welch=0 assumes welch has already been run and will just create the masks
run_welch=1



#################################################################################
# starting to loop through subjects from the smoothed folder
#################################################################################
for ages in ${smoothDir}*; do
age=$(basename $ages)

for subjects in ${ages}/*; do
start=`date +%M`
subject=$(basename $subjects)
func_dhcpDir=${derDir}dhcp_func_output/${age}/sub-${subject}/ses-session1/

func_image=${subjects}/func_normal_resampled.nii.gz

subDir=${subjects}/ses-session1/

sub_outDir=${outDir}${age}/${subject}/
[[ -d ${sub_outDir} ]] || mkdir ${sub_outDir}/



echo "----- ${subject} started-----"


#################################################################################
# running welch on the normalised func image from the smoothed directory
#################################################################################
if [[ ${run_welch} -eq 1 ]]; then

[[ -f ${sub_outDir}func_normal_resampled_Hurst_Welch.nii.gz ]] || nice -10 python ${highDir}fractal/welch.py ${func_image} ${sub_outDir}
fi

welch_func=${sub_outDir}func_normal_resampled_Hurst_Welch.nii.gz

dseg=${func_dhcpDir}import/T2w_dseg.nii.gz
dseg_standard=${sub_outDir}dseg_in_standard.nii.gz
dseg_standard_samp=${sub_outDir}dseg_in_standard_sampled.nii.gz



#################################################################################
# thresholding out the separate tissue labels from the dseg file
#################################################################################
csf_func=${sub_outDir}csf_in_func
gm_cort_func=${sub_outDir}gm_cort_seg_in_func
wm_func=${sub_outDir}wm_in_func
cereb_func=${sub_outDir}cereb_in_func
gm_deep_func=${sub_outDir}gm_deep_seg_in_func

fslmaths ${dseg} -thr 1 -uthr 1 ${csf_func}
fslmaths ${dseg} -thr 2 -uthr 2 ${gm_cort_func}
fslmaths ${dseg} -thr 3 -uthr 3 ${wm_func}
fslmaths ${dseg} -thr 6 -uthr 6 ${cereb_func}
fslmaths ${dseg} -thr 7 -uthr 7 ${gm_deep_func}



#################################################################################
# warping each map into standard space
#################################################################################
csf_standard=${sub_outDir}csf_in_standard
gm_cort_standard=${sub_outDir}gm_cort_seg_in_standard
wm_standard=${sub_outDir}wm_in_standard
cereb_standard=${sub_outDir}cereb_in_standard
gm_deep_standard=${sub_outDir}gm_deep_seg_in_standard

warp_to_standard=${func_dhcpDir}reg/struct_to_standard/struct_to_standard_warp.nii.gz

applywarp \
--ref=${dseg_ref} \
--in=${csf_func} \
--out=${csf_standard} \
--warp=${warp_to_standard} \
--interp=spline

applywarp \
--ref=${dseg_ref} \
--in=${gm_cort_func} \
--out=${gm_cort_standard} \
--warp=${warp_to_standard} \
--interp=spline

applywarp \
--ref=${dseg_ref} \
--in=${wm_func} \
--out=${wm_standard} \
--warp=${warp_to_standard} \
--interp=spline

applywarp \
--ref=${dseg_ref} \
--in=${cereb_func} \
--out=${cereb_standard} \
--warp=${warp_to_standard} \
--interp=spline

applywarp \
--ref=${dseg_ref} \
--in=${gm_deep_func} \
--out=${gm_deep_standard} \
--warp=${warp_to_standard} \
--interp=spline



#################################################################################
# resample each warped map into standard space
#################################################################################
csf_standard_samp=${sub_outDir}csf_in_standard_samp
gm_cort_standard_samp=${sub_outDir}gm_cort_seg_in_standard_samp
wm_standard_samp=${sub_outDir}wm_in_standard_samp
cereb_standard_samp=${sub_outDir}cereb_in_standard_samp
gm_deep_standard_samp=${sub_outDir}gm_deep_seg_in_standard_samp

welch_func_ref=${welch_func}

flirt -in ${csf_standard} -ref ${welch_func_ref} -out ${csf_standard_samp} -applyxfm
flirt -in ${gm_cort_standard} -ref ${welch_func_ref} -out ${gm_cort_standard_samp} -applyxfm
flirt -in ${wm_standard} -ref ${welch_func_ref} -out ${wm_standard_samp} -applyxfm
flirt -in ${cereb_standard} -ref ${welch_func_ref} -out ${cereb_standard_samp} -applyxfm
flirt -in ${gm_deep_standard} -ref ${welch_func_ref} -out ${gm_deep_standard_samp} -applyxfm



#################################################################################
# threshold the warped masks
#################################################################################
csf_standard_bin=${sub_outDir}csf_in_standard_bin
gm_cort_standard_bin=${sub_outDir}gm_cort_in_standard_bin
wm_standard_bin=${sub_outDir}wm_in_standard_bin
cereb_standard_bin=${sub_outDir}cereb_in_standard_bin
gm_deep_standard_bin=${sub_outDir}gm_deep_in_standard_bin

thres_val=0.5

fslmaths ${csf_standard_samp} -thr ${thres_val} -bin ${csf_standard_bin}
fslmaths ${gm_cort_standard_samp} -thr ${thres_val} -bin ${gm_cort_standard_bin}
fslmaths ${wm_standard_samp} -thr ${thres_val} -bin ${wm_standard_bin}
fslmaths ${cereb_standard_samp} -thr ${thres_val} -bin ${cereb_standard_bin}
fslmaths ${gm_deep_standard_samp} -thr ${thres_val} -bin ${gm_deep_standard_bin}



#################################################################################
#remove temporary mask working out
#################################################################################
rm -r ${csf_func}.nii.gz
rm -r ${gm_cort_func}.nii.gz
rm -r ${wm_func}.nii.gz
rm -r ${cereb_func}.nii.gz
rm -r ${gm_deep_func}.nii.gz

rm -r ${csf_standard}.nii.gz
rm -r ${gm_cort_standard}.nii.gz
rm -r ${wm_standard}.nii.gz
rm -r ${cereb_standard}.nii.gz
rm -r ${gm_deep_standard}.nii.gz

rm -r ${csf_standard_samp}.nii.gz
rm -r ${gm_cort_standard_samp}.nii.gz
rm -r ${wm_standard_samp}.nii.gz
rm -r ${cereb_standard_samp}.nii.gz
rm -r ${gm_deep_standard_samp}.nii.gz



#################################################################################
#mask the welch image
#################################################################################
welch_csf=${sub_outDir}welch_func_csf
welch_gm_cort=${sub_outDir}welch_func_gm_cort
welch_wm=${sub_outDir}welch_func_wm
welch_cereb=${sub_outDir}welch_func_cereb
welch_gm_deep=${sub_outDir}welch_func_gm_deep

fslmaths ${welch_func} -mul ${csf_standard_bin} ${welch_csf}
fslmaths ${welch_func} -mul ${gm_cort_standard_bin} ${welch_gm_cort}
fslmaths ${welch_func} -mul ${wm_standard_bin} ${welch_wm}
fslmaths ${welch_func} -mul ${cereb_standard_bin} ${welch_cereb}
fslmaths ${welch_func} -mul ${gm_deep_standard_bin} ${welch_gm_deep}



#################################################################################
# extra masking to takeout overlap between GM and WM
#################################################################################
wm_gm_overlap_mask=${sub_outDir}wm_gm_overlap_mask
fslmaths ${wm_standard_bin} -mas ${gm_cort_standard_bin} ${wm_gm_overlap_mask}

wm_standard_bin_no_overlap=${sub_outDir}wm_in_standard_bin_no_overlap
gm_cort_standard_bin_no_overlap=${sub_outDir}gm_cort_in_standard_bin_no_overlap

fslmaths ${wm_standard_bin} -sub ${wm_gm_overlap_mask} ${wm_standard_bin_no_overlap}
fslmaths ${gm_cort_standard_bin} -sub ${wm_gm_overlap_mask} ${gm_cort_standard_bin_no_overlap}

welch_wm_no_overlap=${sub_outDir}welch_func_wm_no_overlap
welch_gm_cort_no_overlap=${sub_outDir}welch_func_gm_cort_no_overlap

fslmaths ${welch_func} -mul ${wm_standard_bin_no_overlap} ${welch_wm_no_overlap}
fslmaths ${welch_func} -mul ${gm_cort_standard_bin_no_overlap} ${welch_gm_cort_no_overlap}



#################################################################################
# add information to the infofile csv
#################################################################################
echo -n "${subject},${age}," >> ${infofile}

echo -n `fslstats ${welch_csf} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_csf} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_gm_cort} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_gm_cort} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_wm} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_wm} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_cereb} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_cereb} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_gm_deep} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_gm_deep} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats  ${welch_gm_cort_no_overlap} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats  ${welch_gm_cort_no_overlap} -n -S` >> ${infofile}
echo -n "," >> ${infofile}

echo -n `fslstats ${welch_wm_no_overlap} -n -M` >> ${infofile}
echo -n "," >> ${infofile}
echo -n `fslstats ${welch_wm_no_overlap} -n -S` >> ${infofile}
echo "," >> ${infofile}



end=`date +%M`
time_taken=$( jq -n ${end}-${start} )
echo "----- ${subject} finished. Time taken = ${time_taken} minutes-----"
done
done




