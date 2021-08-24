#!/bin/bash

FILE='FDlt1mm_wSucrose.csv'
toplevel='/mnt/WeberLab/Projects/NeonateSucrose/SickKids/'

INPUT="${toplevel}${FILE}"
OLDIFS=$IFS
IFS=','
subjectv01=()
subjectv11=()
subjectv02=()
subjectv12=()
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read SubjectNumber V FD
do
	if [[ $V == "v01" ]]; then
		subjectv01+=($SubjectNumber)
	elif [[ $V == "v11" ]]; then
		subjectv11+=($SubjectNumber)
	elif [[ $V == "v02" ]]; then
		subjectv02+=($SubjectNumber)
	elif [[ $V == "v12" ]]; then
		subjectv12+=($SubjectNumber)
	fi
done < $INPUT
IFS=$OLDIFS

#for p in ${subjectv12[@]}; do
#echo $p
#done

#unset subject[0]

level="${toplevel}Raw3/"

path1="${toplevel}T1Pictures/"
path2="${path1}v01/"
path3="${path1}v11/"
path4="${path1}v02/"
path5="${path1}v12/"

mkdir $path1
mkdir $path2
mkdir $path3
mkdir $path4
mkdir $path5

for k in $level*; do
age=$(basename $k)

for i in $k/*; do
sub=$(basename $i)
value=0
subject=()


if [[ $age == "v01" ]]; then
	subject=("${subjectv01[@]}")
elif [[ $age == "v11" ]]; then
	subject=("${subjectv11[@]}")
elif [[ $age == "v02" ]]; then
        subject=("${subjectv02[@]}")
elif [[ $age == "v12" ]]; then
        subject=("${subjectv12[@]}")
fi


for x in ${subject[@]}; do

if [[ $x == "${sub}" ]] && [[ $value -eq 0 ]]; then
mkdir ${path1}${age}/${sub}
value=1

for j in $i/anat/*;do
base=$(basename $j)
baseclip=${base%%.nii.gz}

if [[ ${base} == *".nii.gz" ]] && [[ ${base: -8:1} != "a" ]]; then
picture="${path1}${age}/${sub}/${baseclip}.png"
slicer ${j} -S 3 1300 ${picture}
fi
done
fi
done


done
done

