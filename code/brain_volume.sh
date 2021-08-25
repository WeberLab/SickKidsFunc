#!bin/bash
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/

#dhcpanatDir=${derDir}dhcp_anat/runfull${age}/

age=v01
dhcpanatDir=${highDir}dhcptesting/


############################################################################
# looping through output subjects from dHCP anat pipeline
############################################################################
for ages in ${highDir}Raw5/*; do
age=$(basename ${ages})

if [[ ${age} == "v01" ]] || [[ ${age} == "v02" ]]; then
for subjects in ${ages}/*; do
subject=$(basename ${subjects})



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

t2_stats=$(fslstats ${t2} -V)
t2_volume=$(echo ${t2_stats} | cut -d " " -f 2)

echo "${subject}, ${t2_volume}"

done
fi
done
