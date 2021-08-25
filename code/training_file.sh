#!/bin/bash
#Looks at subjects in ${dhcpDir} and set up the FIX folder to create the training file.
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/
dhcpDir=${derDir}dhcp_func_output/



#################################################################################
## start looping through subjects
#################################################################################
for ages in ${dhcpDir}*; do
age=$(basename $ages)


for subjects in ${ages}/*; do
fix_input=${subjects}/ses-session1/fix_input/
mkdir ${fix_input}


workDir=${subjects}/ses-session1/
ica=${subjects}/ses-session1/ica/



#filtered_func_data.nii.gz
ln ${ica}func_filtered.nii.gz ${fix_input}filtered_func_data.nii.gz

#  filtered_func_data.ica
ln -s ${ica} ${fix_input}filtered_func_data.ica

#  mc/prefiltered_func_data_mcf.par
motparam="${workDir}mcdc/func_mcdc_motion.tsv"

mkdir ${fix_input}mc
parfile=${fix_input}mc/prefiltered_func_data_mcf.par
touch ${parfile}

while IFS= read -r line
do
x=$(echo ${line} | cut -d " " -f 1)
y=$(echo ${line} | cut -d " " -f 2)
z=$(echo ${line} | cut -d " " -f 3)
rotx=$(echo ${line} | cut -d " " -f 4)
roty=$(echo ${line} | cut -d " " -f 5)
rotz=$(echo ${line} | cut -d " " -f 6)

if [[ "${x}" != "X" ]]; then
echo ${rotx} ${roty} ${rotz} ${x} ${y} ${z} >> ${parfile}
fi

done < "$motparam"


#  mask.nii.gz
ln ${ica}mask.nii.gz ${fix_input}mask.nii.gz

#  mean_func.nii.gz
ln ${ica}mean.nii.gz ${fix_input}mean_func.nii.gz

#  reg/example_func.nii.gz
reg=${fix_input}reg/
mkdir ${reg}
ln ${workDir}import/func0.nii.gz ${reg}example_func.nii.gz

#  reg/highres.nii.gz
ln ${workDir}import/T2w.nii.gz ${reg}highres.nii.gz

#  reg/highres2example_func.mat
ln ${workDir}reg/func-mcdc_to_struct/func-mcdc_to_struct_invaffine.mat ${reg}highres2example_func.mat



done



/usr/local/fix/fix -t training -l ${dhcpDir}*/*/*/ica

