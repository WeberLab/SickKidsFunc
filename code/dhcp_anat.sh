#!/bin/bash
######################################################˚
# Uses dHCP anatomical docker image to segment brains
# from images in Raw5 folder
# Step 1) N4 correction
# Step 2) Register T1 to T2
# Step 3) Run dHCP pipeline
# choose age and if you need to run on a single subject
######################################################˚
highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
inputDir=${highDir}Raw5/
derDir=${highDir}derivatives/

age=v01

curDir=${HOME}/dhcp_anat_out/
dataDir=${curDir}runfull${age}/

single_run_subject="MS040023"

mkdir ${curDir}
cd ${curDir}
mkdir ${dataDir}

# to exclude scans marked in csv as don't use.
# 0 = do not exclude && 1 = exclude
exclude=0

for subject in ${inputDir}${age}/*; do
subjectid=$(basename ${subject})

# uncomment next line and second last fi line to run on all the subjects
if [[ ${subjectid} == ${single_run_subject} ]]; then


######################################################˚
# Subject age from using parse-csv-function.sh
######################################################˚
listsubject=$(bash ${highDir}code/parse_csv_master.sh subject${age})
listage=$(bash ${highDir}code/parse_csv_master.sh scanage${age})
listt1scan=$(bash ${highDir}code/parse_csv_master.sh t1filename${age})
listt2scan=$(bash ${highDir}code/parse_csv_master.sh t2filename${age})
listexclude=$(bash ${highDir}code/parse_csv_master.sh t1Checked${age})

count=1
for i in ${listsubject[@]}; do
if [[ ${i} == ${subjectid} ]]; then
agescan=$(echo ${listage} | cut -d " " -f ${count})
scant1=$(echo ${listt1scan} | cut -d " " -f ${count})
scant2=$(echo ${listt2scan} | cut -d " " -f ${count})
scan_exclude=$(echo ${listexclude} | cut -d " " -f ${count})
fi
count=$((count+1))
done

if [[ ${exclude} -eq 1 ]] && [[ ${scan_exclude} == "1" ]]; then
continue
else
ogt1=${subject}/t1/${subjectid}_${scant1}.nii.gz
ogt2=${subject}/t2/${subjectid}_${scant2}.nii.gz
fi


baset1=$(basename ${ogt1})
baset2=$(basename ${ogt2})

tempDir=${curDir}temp_dhcp_working_${subjectid}/
mkdir ${tempDir}


######################################################˚
# N4 correction
######################################################˚
N4t1=${tempDir}N4_${subjectid}t1.nii.gz
N4t2=${tempDir}N4_${subjectid}t2.nii.gz

N4BiasFieldCorrection -d 3 -i ${ogt1} -o ${N4t1}
N4BiasFieldCorrection -d 3 -i ${ogt2} -o ${N4t2}

cp -f ${N4t2} ${dataDir}
t1=${dataDir}N4_Warped${baset1}
t2=${dataDir}N4_${baset2}
mv ${dataDir}N4_${subjectid}t2.nii.gz ${t2}

cd ${highDir}code



######################################################˚
# Register T1 to T2, uncomment other lines for affine
# and SyN registration
######################################################˚
echo "----- Starting Registration ${subjectid} -----"

antsRegistration --dimensionality 3 --float 0 \
        --output [${tempDir},${t1}] \
        --interpolation Linear \
        --winsorize-image-intensities [0.005,0.995] \
        --use-histogram-matching 0 \
        --initial-moving-transform [${N4t2},${N4t1},1] \
        --transform Rigid[0.08] \
        --metric MI[${N4t2},${N4t1},1,64,Regular,0.20] \
        --convergence [5000x2500x1000x500,1e-10,10] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 0x0x0x0vox


##	--verbose 1
##
##        --transform Affine[0.08] \
##        --metric MI[${N4t2},${N4t1},1,64,Regular,0.25] \
##        --convergence [1000x1000x500x200,1e-10,10] \
##        --shrink-factors 8x4x2x1 \
##        --smoothing-sigmas 3x2x1x0vox
##
##        --transform SyN[0.08,3,0] \
##        --metric MI[${N4t2},${N4t1},1,64,Regular,0.25] \
##        --convergence [300x2000x100x500,1e-10,10] \
##        --shrink-factors 8x4x2x1 \
##        --smoothing-sigmas 3x2x1x0vox \
##        --verbose 1

echo "----- Registration completed for ${subjectid} -----"

rm -r ${tempDir}


######################################################˚
# Run docker image
######################################################˚
echo "----- dHCP starting for ${subjectid} -----"
#
#docker run --rm -t \
#    -u $(id -u):$(id -g) \
#    -v ${curDir} \
#    -v ${dataDir}:${dataDir} \
#    -w ${dataDir} \
#    biomedia/dhcp-structural-pipeline:latest ${subjectid} session1 ${agescan} -T1 N4_Warped${baset1} -T2 N4_${baset2} -t 16



fi
done


mkdir ${derDir}dhcp_anat
cp -r ${dataDir} ${derDir}dhcp_anat/


