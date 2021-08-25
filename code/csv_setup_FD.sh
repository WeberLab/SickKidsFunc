#!/bin/bash
#This file looks at all the subjects in ${inputDir} and adds them to ${initial_csv}
#If the subject has a func scan then the FD will be computed and added
#The length of the scan in seconds will also be added


highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
inputDir=${highDir}Raw6/

FDDir=${highDir}FD_parfiles/
[[ -d ${FDDir} ]] || mkdir ${FDDir}
[[ -d ${FDDir}v01/ ]] || mkdir ${FDDir}v01/
[[ -d ${FDDir}v11/ ]] || mkdir ${FDDir}v11/
[[ -d ${FDDir}v02/ ]] || mkdir ${FDDir}v02/
[[ -d ${FDDir}v12/ ]] || mkdir ${FDDir}v12/


initial_csv=${highDir}subject_info.csv
touch ${initial_csv}
echo "Subject ID,AGE,Birth age,Scan Age,FD,Func Length(s),T1,t1 Image comment,t1 1=don't use,T2,t2 Image comment,t2 1=don't use,gre," > ${initial_csv}


for ages in ${inputDir}*; do
age=$(basename $ages)

for subjects in ${ages}/*; do
subject=$(basename $subjects)
[[ -d ${FDDir}${age}/${subject} ]] || mkdir ${FDDir}${age}/${subject}


if [ "$(ls -A ${subjects}/func)" ]; then

for scans in ${subjects}/func/*.nii.gz; do

scan=$(basename $scans)
scan_strip=${scan%%.nii.gz}
outFile=${FDDir}${age}/${subject}/${subject}

mcflirt -in ${scans} -out ${outFile} -stats -mats -plots
FD=$(/home/aweber/Scripts/Misc/FD.r ${FDDir}${age}/${subject}/*.par)

hislice=`PrintHeader ${scans} | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1`
tr=`PrintHeader ${scans} | grep "Voxel Spac" | cut -d ',' -f 4 | cut -d ']' -f 1`
timesec=$((hislice*tr))


echo "${subject},${age},0,0,${FD},${timesec},0,0,0,0,0,0,0," >> ${initial_csv}
done
else
echo "${subject},${age},0,0,nan,nan,0,0,0,0,0,0,0," >> ${initial_csv}
fi


done
done
