#!/bin/bash
#Looks at subjects in ${inputDir} under the given age and modality
# Will add scan to .txt depending on if scan is to be excluded or not


highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/
inputDir=${highDir}Raw6/

#chOOSE ${age} v01/v02 and ${modality} t1/t2
age=v01
modality=t1

# to exclude scans marked in csv as don't use.
# 0 = do not exclude && 1 = exclude
exclude=0

# if the template is getting clipped use a reference image
# 0 = do not use reference && 1 = use provided reference image
reference=0
reference_image=""

templateInfo=${derDir}template_info_${age}_${modality}.csv
templateFail=${derDir}template_fail_${age}_${modality}.txt
templateDir=${derDir}template_${age}_${modality}/

rm -r ${templateInfo}
rm -r ${templateFail}

touch ${templateInfo}
touch ${templateFail}
[[ -d ${templateDir} ]] || mkdir ${templateDir}

listscan=$(bash ${highDir}code/parse_csv_master.sh ${modality}filename${age})
listsubject=$(bash ${highDir}code/parse_csv_master.sh subject${age})
listexclude=$(bash ${highDir}code/parse_csv_master.sh ${modality}Checked${age})

for subjects in ${inputDir}${age}/*; do
subject=$(basename $subjects)

#################################################################################
# parse master csv for scan name and exclusion criteria
# if exclude==0 set ${scan_exclude} to 0, so every scan is included in template
#################################################################################
count=1
for i in ${listsubject[@]}; do
if [[ ${i} == ${subject} ]]; then
scan=$(echo ${listscan} | cut -d " " -f ${count})
scan_exclude=$(echo ${listexclude} | cut -d " " -f ${count})
fi
count=$((count+1))
done

[[ ${exclude} == '0' ]] && scan_exclude=0


#################################################################################
# add scan names to ${templateInfo}
#################################################################################
full_scan=${subjects}/${modality}/${subject}_${scan}.nii.gz
[[ -f ${full_scan} ]] || echo "${age} ${subject} ${full_scan}" >> ${templateFail}
[[ -f ${full_scan} ]] && [[ ${exclude} == '0' ]] && echo "${full_scan}" >> ${templateInfo}


done


#################################################################################
# run template function with reference or not
#################################################################################
if [[ ${reference} -eq 0 ]]; then

${ANTSPATH}/antsMultivariateTemplateConstruction2.sh \
  -d 3 \
  -a 1 \
  -o ${templateDir} \
  -i 5 \
  -g 0.25 \
  -j 16 \
  -c 0 \
  -k 1 \
  -w 1 \
  -n 1 \
  -r 1 \
  -l 1 \
  -m CC \
  -t SyN \
  -y 0 \
  ${templateInfo}

else

${ANTSPATH}/antsMultivariateTemplateConstruction2.sh \
  -d 3 \
  -a 1 \
  -o ${templateDir} \
  -i 5 \
  -g 0.25 \
  -j 16 \
  -c 0 \
  -k 1 \
  -w 1 \
  -n 1 \
  -r 1 \
  -l 1 \
  -m CC \
  -t SyN \
  -y 0 \
  -z ${reference_image} \
  ${templateInfo}

fi



# delete .txt file that holds the scan names used in the template
rm -r ${templateInfo}
