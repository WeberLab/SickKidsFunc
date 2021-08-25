#!/bin/bash
highDir='/home/johann.drayne/'
dataDir='/mnt/WeberLab/Projects/NeonateSucrose/SickKids/'

subfile=${highDir}dhcp_func/training_subjects.txt

infofile=${highDir}dhcp_func/group_run_failures.txt
rm -r ${infofile}
touch ${infofile}

######################################################
# Run on subjects in Raw5
######################################################
#age="v02"
#for subjects in ${dataDir}Raw5/${age}/*; do
#subject=$(basename ${subjects})
#echo "------------------------------- ${subject} Started -------------------------------"
#nice -10 python ${highDir}dhcp_func/dhcp_func.py ${age} ${subject}
#[[ -d ${highDir}dhcp_func/dhcp_func_output/${age}/sub-${subject}/ses-session1/qc ]] || echo "${subject} failed" >> ${infofile}
#done



######################################################
# Run on subjects in ${subfile} more control
######################################################
while IFS= read -r line
do

age=$(echo "${line}" | cut -d "," -f 1)
sub=$(echo "${line}" | cut -d "," -f 2)
if [[ ${age} == "v01" ]] || [[ ${age} == "v02" ]]; then
echo "${age} & ${sub}"
nice -10 python ${highDir}dhcp_func/dhcp_func.py ${age} ${sub}
fi
done < ${subfile}



while IFS= read -r line
do
age=$(echo "${line}" | cut -d "," -f 1)
sub=$(echo "${line}" | cut -d "," -f 2)
if [[ ${age} == "v01" ]] || [[ ${age} == "v02" ]]; then
[[ -d ${highDir}dhcp_func/dhcp_func_output_fullrun/${age}/sub-${subject}/ses-session1/qc ]] || echo "${age} - ${sub} failed" >> ${infofile}
fi
done < ${subfile}
