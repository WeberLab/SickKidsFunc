###############################################################
# Motion corrects fmri image by registering it to its avergae
# Creates avergae fMRI rigid -> affine registration to average
# Register fMRI to 4D average
###############################################################

highDir=/mnt/WeberLab/projects/NeonateSucrose/SickKids/
derDir=${highDir}derivatives/

outDir=${derDir}motioncorrectedfmri/
[[ -d ${outDir} ]] || mkdir ${outDir}
[[ -d ${outDir}v01 ]] || mkdir ${outDir}v01
[[ -d ${outDir}v02 ]] || mkdir ${outDir}v02


# to exclude scans marked in csv with data points < ${datapoints}
# 0 = do not exclude && 1 = exclude
exclude=0
datapoints=100


# to run on single subject include && [[ ${subject} == "MS040058" ]] in the
# if statement
single_subject="MS040058"


motionInfo=${derDir}motioncorrectedfmri_fail.txt
rm -r ${motionInfo}
touch ${motionInfo}



################################################################################
# Loop through Raw5 for the func scans and create temp folder
################################################################################
for ages in ${highDir}Raw5/*; do
age=$(basename ${ages})
listsubject=$(bash ${highDir}code/parse_csv_master.sh subject${age})
listscanlength=$(bash ${highDir}code/parse_csv_master.sh scanlength${age})


for subjects in ${ages}/*; do
subject=$(basename ${subjects})
count=1
for i in ${listsubject[@]}; do
if [[ ${i} == ${subject} ]]; then
scan_length=$(echo ${listscanlength} | cut -d " " -f ${count})
fi
count=$((count+1))
done

[[ ${exclude} == '0' ]] && scan_length=$((datapoints+1))



for fmri in ${subjects}/func/*; do

# remove && [[ ${baseid} == "MS040058" ]] if you want to run on all subjects
if [[ ${fmri: -6: 6} == nii.gz ]] && [[ ${scan_length} -gt ${datapoints} ]] && [[ ${subject} == "MS040058" ]]; then


nm=${derDir}temp_motioncorrection/${age}/${subject}/
mkdir ${derDir}temp_motioncorrection/
mkdir ${derDir}temp_motioncorrection/${age}/
mkdir ${nm}



################################################################################
# Creating initial average image
################################################################################
initialavg=${nm}InitialAverage.nii.gz

antsMotionCorr -d 3 -a $fmri -o $initialavg
echo "Initial average image"



################################################################################
# First Affine motion correction to average image
################################################################################
FirstAffineMotion=FirstAffineMotionCor

antsMotionCorr  -d 3 \
-o [ ${nm}${FirstAffineMotion}, ${nm}FirstAffineWarped.nii.gz, ${nm}${FirstAffineMotion}Averaged.nii.gz] \
-m MI[${initialavg}, ${fmri}, 1 , 32 , Regular, 0.2] \
-t Rigid[ 0.1 ] \
-u 1 \
-e 1 \
-s 1x1x0 \
-f 4x2x1 \
-i 100x50x20 \
-n 3 \
-w 1
echo "Affine motion correction"

#rm -f ${nm}affinemotcorMOCOparams.csv



################################################################################
# Creating average from firstAffineWarped
################################################################################
antsMotionCorr -d 3 -a ${nm}FirstAffineWarped.nii.gz -o ${nm}AverageFirstAffineWarped.nii.gz
echo "Initial average image"



################################################################################
# Second Affine motion correction to average image
################################################################################
SecondAffineMotion=SecondAffineMotionCorMMM

antsMotionCorr  -d 3 \
-o [ ${nm}${SecondAffineMotion}, ${nm}SecondAffineMMMWarped.nii.gz, ${nm}${SecondAffineMotion}Averaged.nii.gz] \
-m MI[${nm}${FirstAffineMotion}Averaged.nii.gz, ${nm}FirstAffineWarped.nii.gz, 1 , 32 , Regular, 0.2 ] \
-t Affine[ 0.1 ] \
-u 1 \
-e 1 \
-s 1x1x0 \
-f 4x2x1 \
-i 100x50x20 \
-n 3 \
-w 1
echo "Second MMM Affine motion correction"



#################################################################################
# Parse header information to find number of time points
#################################################################################
hislice=`PrintHeader $fmri | grep Dimens | cut -d ',' -f 4 | cut -d ']' -f 1`
tr=`PrintHeader $fmri | grep "Voxel Spac" | cut -d ',' -f 4 | cut -d ']' -f 1`
echo "Header information parsed"



#################################################################################
# Replicate 3D image $hislice times to create new 4D image
#################################################################################
fxd=${nm}AffineAvg4D.nii.gz
ImageMath 3 $fxd ReplicateImage ${nm}${SecondAffineMotion}Averaged.nii.gz $hislice $tr 0
echo "Replicated 3D slices to form 4D image"



################################################################################
# Run SyN to map the time series to this fixed space
################################################################################
deform=Deformed

antsRegistration --dimensionality 4 \
      --float 0 \
      -r ${nm}${SecondAffineMotion}Warp.nii.gz \
      --output   [${nm}${deform},${nm}${deform}Warped.nii.gz] \
      --interpolation Linear \
      --use-histogram-matching 1 \
      --winsorize-image-intensities [0.005,0.995] \
      --transform Rigid[0.1] \
      --metric MI[${fxd},$fmri,1, 64, Regular, 0.3] \
      --convergence [5000x2000x200,1e-10,20] \
      --shrink-factors 4x2x1 \
      --smoothing-sigmas 3x1x0vox \
      --transform Affine[0.1] \
      --metric MI[${fxd},$fmri,1, 64, Regular, 0.3] \
      --convergence [5000x2000x200,1e-10,20] \
      --shrink-factors 4x2x1 \
      --smoothing-sigmas 3x1x0vox \
      --use-estimate-learning-rate-once 1

echo "Map created"

outSub=${outDir}${age}/_${subject}motioncorrected.nii.gz

antsApplyTransforms -d 4 \
-o ${outSub} \
-t ${nm}${deform}0Warp.nii.gz  \
-r ${nm}${SecondAffineMotion}Warp.nii.gz \
-i ${nm}SecondAffineMMMWarped.nii.gz
echo "Transformation applied to original fmri"


[[ -f  ${outSub} ]] && [[ ${scan_length} -gt ${datapoints} ]] && echo "${age} ${subject}" >> ${motionInfo}

fi
done
done
done

# remove the temporary files folder
rm -r ${nm}
