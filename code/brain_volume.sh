#!bin/bash
############################################################################
# prints the volume onto terminal. Saving to a .csv has not been set up as
# the code runs very quickly. i.e. 150 subjects ~20 seconds
############################################################################
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/

#dhcpanatDir=${derDir}dhcp_anat/runfull${age}/

age=v01
dhcpanatDir=${highDir}dhcptesting/

tempDir=${derdir}temp_volume_maps/
[[ -d ${tempDir} ]] || mkdir ${tempDir}
[[ -d ${tempDir}v01 ]] || mkdir ${tempDir}v01
[[ -d ${tempDir}v02 ]] || mkdir ${tempDir}v02

############################################################################
# looping through output subjects from dHCP anat pipeline
############################################################################
for ages in ${highDir}Raw5/*; do
age=$(basename ${ages})

if [[ ${age} == "v01" ]] || [[ ${age} == "v02" ]]; then
for subjects in ${ages}/*; do
subject=$(basename ${subjects})
[[ -d ${tempDir}${age}/${subject} ]] || mkdir ${tempDir}${age}/${subject}


############################################################################
# finding the skull stripped t2 and segmented anatomical image
############################################################################
sesid=session1
subid=${subject}

workingdseg=${dhcpanatDir}runfull${age}/workdir/${subid}-${sesid}/segmentations/${subid}-${sesid}_tissue_labels
derivdseg=${dhcpanatDir}runfull${age}/derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_drawem_tissue_labels
[[ -f ${workingdseg}.nii.gz ]] && dseg=${workingdseg} || dseg=${derivdseg}

workingt2=${dhcpanatDir}runfull${age}/workdir/${subid}-${sesid}/restore/T2/${subid}-${sesid}_restore_brain
derivt2=${dhcpanatDir}runfull${age}/derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_T2w_restore_brain
[[ -f ${workingt2}.nii.gz ]] && t2=${workingt2} || t2=${derivt2}


############################################################################
# thresholding out the tissues from ${dseg}
############################################################################
gm_cort=${tempDir}${age}/${subject}/gm_cort_seg

fslmaths ${dseg} -thr 2 -uthr 2 ${gm_cort}


############################################################################
# finding the volumes
############################################################################
# whole brain volume
t2_stats=$(fslstats ${t2} -V)
t2_volume=$(echo ${t2_stats} | cut -d " " -f 2)

# GM cortical volume
gm_cort_stats=$(fslstats ${gm_cort} -V)
gm_volume=$(echo ${gm_cort_stats} | cut -d " " -f 2)


# echo volume onto terminal
echo "${subject}, ${gm_volume}"

done
fi
done

rm -r ${tempDir}
