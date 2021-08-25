#!/bin/bash


###########################################################################################
# parse-'some modality'() outputs array of all scans of passed subject e.g.MS040056_V01
# Nifti images are created from these scans and are stored in raw1 variable folder
# in the hierarchy raw1/${age}/${subject}/${modality}/${scans}
# madalities are named t1, t2, gre, func this can be change by updating lines 177-181
###########################################################################################

FILE=../PretermCare_list_of_all_series.txt

sourceDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/sourcedata/
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
raw1=${highDir}Raw6/

fail_dcm_info=${highDir}failed_dcm_conversions.txt
touch ${fail_dcm_info}


mkdir ${raw1}
mkdir ${raw1}v01/
mkdir ${raw1}v11/
mkdir ${raw1}v12/
mkdir ${raw1}v02/


################################################################################
# t1 parse function
################################################################################
parse-t1() {

parse=0
start_read=0
count=`grep -c "$1" $FILE`
array=()

while read p && [[ $parse -eq 0  ]] && [[ $count -ne 0 ]]; do

if [[ $p == *$1* ]]; then
start_read=1
fi

if [[ $start_read -eq 1 ]] && [[ $p != 3DT1 ]] && [[ $p != 2DT2 ]] && [[ $p != *$1* ]]; then
array+=($p)
fi

if [[ $p == 2DT2 ]] && [[ $start_read -eq 1 ]]; then
start_read=0
count=$(($count-1))
fi

done<$FILE

}


################################################################################
# t2 parse function
################################################################################
parse-t2() {

parse=0
start_read=0
count=`grep -c "$1" $FILE`
array=()

while read p && [[ $parse -eq 0  ]] && [[ $count -ne 0 ]]; do

if [[ $p == *$1* ]]; then
start_read=1
fi

if [[ $start_read -eq 1 ]] && [[ $p == 2DT2 ]]; then
start_parse=1
fi

if [[ $start_parse -eq 1 ]] && [[ $p != 2DT2 ]] && [[ $p != field_map ]] && [[ $p != *$1* ]]; then
array+=($p)
fi

if [[ $p == field_map ]] && [[ $start_read -eq 1 ]]; then
start_read=0
start_parse=0
count=$(($count-1))
fi

done<$FILE

}



################################################################################
# field-map parse function
################################################################################
parse-gre() {

parse=0
start_read=0
count=`grep -c "$1" $FILE`
array=()

while read p && [[ $parse -eq 0  ]] && [[ $count -ne 0 ]]; do

if [[ $p == *$1* ]]; then
start_read=1
fi

if [[ $start_read -eq 1 ]] && [[ $p == field_map ]]; then
start_parse=1
fi

if [[ $start_parse -eq 1 ]] && [[ $p != field_map ]] && [[ $p != fMRI ]] && [[ $p != *$1* ]]; then
array+=($p)
fi

if [[ $p == fMRI ]] && [[ $start_read -eq 1 ]]; then
start_read=0
start_parse=0
count=$(($count-1))
fi

done<$FILE

}


################################################################################
# fMRI parse function
################################################################################
parse-fmri() {

parse=0
start_read=0
count=`grep -c "$1" $FILE`
array=()

while read p && [[ $parse -eq 0  ]] && [[ $count -ne 0 ]]; do

if [[ $p == *$1* ]]; then
start_read=1
fi

if [[ $start_read -eq 1 ]] && [[ $p == fMRI ]]; then
start_parse=1
fi

if [[ $start_parse -eq 1 ]] && [[ $p != fMRI ]] && [[ $p != excluded ]] && [[ $p != *$1* ]]; then
array+=($p)
fi

if [[ $p == excluded ]] && [[ $start_read -eq 1 ]]; then
start_read=0
start_parse=0
count=$(($count-1))
fi

done<$FILE

}



################################################################################
# go through source data to find files to convert into nifti
################################################################################

for folders in ${sourceDir}*; do
subject_code=${folders: -12}
subject=${subject_code:0:8}
age=${folders: -2}

echo "----- ${subject_code} -----"
subject_folder=${raw1}v${age}/${subject}/

t1_folder=${subject_folder}t1
t2_folder=${subject_folder}t2
gre_folder=${subject_folder}gre
func_folder=${subject_folder}func

mkdir ${subject_folder}
mkdir ${t1_folder}
mkdir ${t2_folder}
mkdir ${gre_folder}
mkdir ${func_folder}


#Looks at all t1 scans gives by parse-t2() and converts them to nifti
for t1 in $(parse-t1 "${subject}_V${age}"; echo ${array[*]}); do

t1_raw=${folders}/${t1}
t1_dcm=${t1_folder}/${subject}_${t1}.nii.gz

dcm2niix \
-o ${t1_folder} \
-f ${subject}_${t1} \
-z y \
${t1_raw}

[[ -f ${t1_dcm} ]] || echo "${subject_code} ${t1} FAILED" > ${fail_dcm_info}

done


#Looks at all t2 scans gives by parse-t2() and converts them to nifti
for t2 in $(parse-t2 "${subject}_V${age}"; echo ${array[*]}); do

t2_raw=${folders}/${t2}
t2_dcm=${t2_folder}/${subject}_${t2}.nii.gz

dcm2niix \
-o ${t2_folder} \
-f ${subject}_${t2} \
-z y \
${t2_raw}

[[ -f ${t2_dcm} ]] || echo "${subject_code} ${t2} FAILED" > ${fail_conv_info}

done


#Looks at all gre scans gives by parse-t2() and converts them to nifti
for gre in $(parse-gre "${subject}_V${age}"; echo ${array[*]}); do

gre_raw=${folders}/${gre}
gre_dcm=${t2_folder}/${subject}_${gre}.nii.gz

dcm2niix \
-o ${gre_folder} \
-f ${subject}_${gre} \
-z y \
${gre_raw}

[[ -f ${gre_dcm} ]] || echo "${subject_code} ${gre} FAILED" > ${fail_conv_info}

done



#Looks at all func scans gives by parse-t2() and converts them to nifti
for func in $(parse-fmri "${subject}_V${age}"; echo ${array[*]}); do

func_raw=${folders}/${func}
func_dcm=${func_folder}/${subject}_${func}.nii.gz

dcm2niix \
-o ${func_folder} \
-f ${subject}_${func} \
-z y \
${func_raw}

[[ -f ${func_dcm} ]] || echo "${subject_code} ${func} FAILED" > ${fail_conv_info}

done


#echo "${subject_code} ${subject} ${age}"

done
