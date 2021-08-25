#!/bin/bash
# used to check Power Spectrum Densities
# takes inputs from welch_and_tissue_mask.sh

highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/

fwhm=8

highGM=${derDir}welch_and_masking_fwhm_${fwhm}/
smoothDir=${derDir}smoothed_${fwhm}_normalised/
tempDir=${derDir}temp_PSD_png_fwhm_${fwhm}/

outDir=${derDir}PSD_png_FWHM_${fwhm}/
[[ -d ${outDir} ]] || mkdir ${outDir}
[[ -d ${outDir}v01 ]] || mkdir ${outDir}v01
[[ -d ${outDir}v02 ]] || mkdir ${outDir}v02
[[ -d ${tempDir} ]] || mkdir ${tempDir}

for ages in ${highGM}*; do
age=$(basename $ages)

for subjects in ${ages}/*; do
subject=$(basename $subjects)
tempSub=${tempDir}${age}_${subject}_masked.nii.gz

binGM=${subjects}/gm_cort_in_standard_bin_no_overlap.nii.gz
func=${smoothDir}${age}/${subject}/func_normal_resampled.nii.gz
echo "------------------"
fslmaths ${func} -mas ${binGM} ${tempSub}

nice -10 python ${highDir}fractal/PSD.py ${tempSub} ${outDir}${age}/

#rm -r ${tempSub}
done
done
