#!/bin/bash

FILE='FDlt1mm_wSucrose_bestT1Data.csv'
toplevel='/mnt/WeberLab/Projects/NeonateSucrose/SickKids/'

INPUT="${toplevel}${FILE}"
OLDIFS=$IFS
IFS=','
subjectv01=()
filenamev01=()
subjectv11=()
filenamev11=()
subjectv02=()
filenamev02=()
subjectv12=()
filenamev12=()

[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

while read SubjectNumber V FD FileName Question Neck fMRI T1 Checked Stevens Notes T1Use
do
	if [ ! -z "$FileName" ] && [[ ${T1Use:0:1} == "0" ]]; then
	echo "TRUE"
        if [[ $V == "v01" ]]; then
                subjectv01+=($SubjectNumber)
                filenamev01+=($FileName)
        elif [[ $V == "v11" ]]; then
                subjectv11+=($SubjectNumber)
                filenamev11+=($FileName)
        elif [[ $V == "v02" ]]; then
                subjectv02+=($SubjectNumber)
                filenamev02+=($FileName)
        elif [[ $V == "v12" ]]; then
                subjectv12+=($SubjectNumber)
                filenamev12+=($FileName)
        fi
	fi
done < $INPUT
IFS=$OLDIFS



datasource="${toplevel}Raw2/"
dataoutputlevel="${toplevel}Raw4/"

mkdir $dataoutputlevel

ages=("v01" "v11" "v02" "v12")



for age in ${ages[@]}; do
mkdir "${dataoutputlevel}${age}"
subject=()

if [[ $age == "v01" ]]; then
	subject=("${subjectv01[@]}")
	file=("${filenamev01[@]}")
elif [[ $age == "v11" ]]; then
	subject=("${subjectv11[@]}")
        file=("${filenamev11[@]}")
elif [[ $age == "v02" ]]; then
        subject=("${subjectv02[@]}")
        file=("${filenamev02[@]}")
elif [[ $age == "v12" ]]; then
        subject=("${subjectv12[@]}")
        file=("${filenamev12[@]}")
fi



count=0
for sub in ${subject[@]}; do
mkdir "${dataoutputlevel}${age}/${sub}"
mkdir "${dataoutputlevel}${age}/${sub}/anat"
mkdir "${dataoutputlevel}${age}/${sub}/func"
echo "${age}_${sub}"

dcm2niix \
-o ${dataoutputlevel}${age}/${sub}/anat/ \
-f ${sub}_${file[$count]} \
-b y \
-z y \
${datasource}${age}/${sub}/${file[$count]}
#echo "${datasource}${age}/${sub}/${file[$count]} --> ${dataoutputlevel}${age}/${sub}/anat/${sub}_${file[$count]}"

if [ -d "${datasource}${age}/${sub}/${file[$count]}/" ]; then
echo "${datasource}${age}/${sub}/${file[$count]} --> exists"
else
echo "${datasource}${age}/${sub}/${file[$count]} --> DOESN'T EXIST"
fi


for x in ${datasource}/${age}/${sub}/*; do
base=$(basename $x)
if [[ $base == *"fMRI"* ]]; then
dcm2niix \
-o ${dataoutputlevel}${age}/${sub}/func/ \
-f ${sub}_${base} \
-b y \
-z y \
${datasource}${age}/${sub}/${base}
#echo "${datasource}${age}/${sub}/${base} --> ${dataoutputlevel}${age}/${sub}/func/${sub}_${base}"
fi

done



count=$((count + 1))
done
done

