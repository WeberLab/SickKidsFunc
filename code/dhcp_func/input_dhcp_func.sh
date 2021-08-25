highDir="${HOME}/"
dataDir='/mnt/WeberLab/Projects/NeonateSucrose/SickKids/'
derivDir='${HOME}/dhcp_func/'
#dhcpanat=${dataDir}dhcptesting/runfull/
age=$2
#age="v02"
dhcpanat=${dataDir}derivatives/dhcp_anat/runfull${age}/
rawDir=${dataDir}Raw5/


############################################################################
# subject info files setup
############################################################################
subid=$1
age=$2
#subid="MS040064"
#age="v02"

sesid='session1'
[[ -d  ${derivDir}dhcp_func_input ]] || mkdir ${derivDir}dhcp_func_input

highoutputDir=${derivDir}dhcp_func_input/${age}/
[[ -d ${highoutputDir} ]] || mkdir ${highoutputDir}

outputDir=${highoutputDir}${subid}/
[[ -d ${outputDir} ]] && rm -r ${outputDir} && mkdir ${outputDir} || mkdir ${outputDir}

slicetimefile=${outputDir}slicetiming.txt
rm -r ${slicetimefile}
touch ${slicetimefile}

slicetempfile=${outputDir}slicetemp.txt
rm -r ${slicetempfile}
touch ${slicetempfile}

sliceorderfile=${outputDir}slicetime.txt
rm -r ${sliceorderfile}
touch ${sliceorderfile}

infofile=${outputDir}info.txt
rm -r ${infofile}
touch ${infofile}


############################################################################
# parsing scanage, birthage, t1, t2, phase from .csv file
############################################################################
listscanage=$(bash ${dataDir}code/parse_csv_master.sh scanage${age})
listbirthage=$(bash ${dataDir}code/parse_csv_master.sh birthage${age})
listsubject=$(bash ${dataDir}code/parse_csv_master.sh subject${age})
#listt1file=$(bash ${dataDir}code/parse-csv-function.sh t1filename${age})
#listt2file=$(bash ${dataDir}code/parse-csv-function.sh t2filename${age})
listgrefile=$(bash ${dataDir}old_code/parse_csv_master.sh grefilename${age})

count=1
for i in ${listsubject[@]}; do
if [[ ${i} == ${subid} ]]; then
scan_pma=$(echo ${listscanage} | cut -d " " -f ${count})
birth_ga=$(echo ${listbirthage} | cut -d " " -f ${count})
#t1=$(echo ${listt1file} | cut -d " " -f ${count})
#t2=$(echo ${listt2file} | cut -d " " -f ${count})
gre=$(echo ${listgrefile} | cut -d " " -f ${count})
fi
count=$((count+1))
done


#phase=${dataData}gredcm-to-nifti/${age}/${subid}/${gre}.nii.gz
phase=${rawDir}${age}/${subid}/gre/${subid}_${gre}.nii.gz


echo "${birth_ga}" >> ${infofile}
echo "${scan_pma}" >> ${infofile}
#scan_pma = scan age
#birth_ga = birth age
#t1 = t1 file
#t2 = t2 file
#gre = phase file


############################################################################
# finding the func image
############################################################################
for i in ${dataDir}Raw5/${age}/${subid}/func/*.nii.gz; do
func=${i}
done

[[ -f ${func} ]] || echo "Func does not exist"

#func = func file


############################################################################
# from dHCP anat pipeline output
# finding the t1, t2,  stripped t2 brain and dseg brain
############################################################################
workingt1=${dhcpanat}workdir/${subid}-${sesid}/restore/T1/${subid}-${sesid}_restore
derivt1=${dhcpanat}derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_T1w_restore
[[ -f ${workingt1}.nii.gz ]] && t1=${workingt1} || t1=${derivt1}

workingt2=${dhcpanat}workdir/${subid}-${sesid}/restore/T2/${subid}-${sesid}_restore
derivt2=${dhcpanat}derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_T2w_restore
[[ -f ${workingt2}.nii.gz ]] && t2=${workingt2} || t2=${derivt2}

workingt2strip=${dhcpanat}workdir/${subid}-${sesid}/restore/T2/${subid}-${sesid}_restore_brain
derivt2strip=${dhcpanat}derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_T2w_restore_brain
[[ -f ${workingt2strip}.nii.gz ]] && t2strip=${workingt2strip} || t2strip=${derivt2strip}

workingdseg=${dhcpanat}workdir/${subid}-${sesid}/segmentations/${subid}-${sesid}_tissue_labels
derivdseg=${dhcpanat}derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_drawem_tissue_labels
[[ -f ${workingdseg}.nii.gz ]] && dseg=${workingdseg} || dseg=${derivdseg}

workingmask=${dhcpanat}workdir/${subid}-${sesid}/masks/${subid}-${sesid}
derivmask=${dhcpanat}derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_brainmask_drawem
[[ -f ${workingmask}.nii.gz ]] && mask=${workingmask} || mask=${derivmask}

#anat = skull stripped t2
#dseg = labelled t2 image


############################################################################
# finsing the sbref image (mean of func -> output of ANTs motion correction)
############################################################################
sbref=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/derivatives/motioncorrectedfmri/${age}/_${subid}motioncorrected.nii.gz

antsMotionCorr -d 3 -a ${sbref} -o ${outputDir}sbref.nii.gz

#sbref = mean of functional image


############################################################################
# finding the magnitude image and creating the fieldmap
############################################################################
#for i in ${dataDir}gredcm-to-nifti/${age}/${subid}/*e1.nii.gz; do
#mag=${i%%e1.nii.gz}
#done
for i in ${rawDir}${age}/${subid}/gre/*e1.nii.gz; do
mag=${i%%e1.nii.gz}
done

phase=${phase%%.nii.gz}
output=${outputDir}fmap_rads

#putting phase image into radians
phasenorm=${outputDir}phase_normal
phaserad=${outputDir}phase_inrads
ImageMath 3 ${phasenorm}.nii.gz Normalize ${phase}.nii.gz
fslmaths ${phasenorm} -mul 6.28318 ${phaserad}

fslmaths ${phase} -div 2 ${phaserad}

# should be tight
magbet=${outputDir}fmap_brainmask
bet ${mag}e1 ${magbet} -f 0.7

# getting echo spacing from magnitude file
echoe1=$(jq .EchoTime ${mag}e1.json)
echoe2=$(jq .EchoTime ${mag}e2.json)
dif=$( jq -n ${echoe1}-${echoe2} )
dif=$( echo "scale=10; ${dif} * 1000" | bc )
[[ ${dif:0:1} == '-' ]] && dif=${dif:1: -1}

#creating fieldmap
# change the input after SIEMENS to determine the phase image
fsl_prepare_fieldmap SIEMENS ${phaserad} ${magbet} ${output} ${dif} --nocheck


#fmap_rads = fieldmap


############################################################################
# parsing echospacing and creatig slice time file from func .json file
############################################################################
#creating slice timing file
for file in ${dataDir}Raw5/${age}/${subid}/func/*.json; do

numfmri=$(jq .ShimSetting ${file})
echospacing=$(jq .EffectiveEchoSpacing ${file})
slicetime=$(jq .SliceTiming ${file})

echo "${echospacing}" >> ${infofile}

count=1
arr2=()
for value in ${slicetime[@]}; do

if [[ ${#value} -gt 1 ]] && [[ ${value:(-1)} == "," ]]; then
var1=$( echo ${value::$(( ${#value} - 1 ))} )
newvar=$( echo ${var1#-} )
arr2+=("${newvar}")
echo "${newvar}" >> ${slicetimefile}
fi


if [[ ${value:(-1)} != "," ]] && [[ ${value:(-1)} != "]" ]] && [[ ${value:(-1)} != "[" ]]; then
newvar=$( echo ${value#-} )
arr2+=("${newvar}")
echo "${newvar}" >> ${slicetimefile}
fi

count=$((count+1))
done


sort -nu ${slicetimefile} | awk 'NR == FNR {rank[$0] = NR; next} {print rank[$0]}' - ${slicetimefile} > ${slicetempfile}

awk '{$1=$1-1; print}' ${slicetempfile} > ${sliceorderfile}

rm -r ${slicetempfile}


#getting shim settings
count=1
arr=()
for value in ${numfmri[@]}; do

if [[ ${#value} -gt 1 ]] && [[ ${value:(-1)} == "," ]]; then
var1=$( echo ${value::$(( ${#value} - 1 ))} )
newvar=$( echo ${var1#-} )
arr+=("${newvar}")
fi

if [[ ${value:(-1)} != "," ]] && [[ ${value:(-1)} != "]" ]] && [[ ${value:(-1)} != "[" ]]; then
newvar=$( echo ${value#-} )
arr+=("${newvar}")
fi

count=$((count+1))
done

done


#############################################################################
## rigidly registering T1 to T2
#############################################################################
#antsRegistration --dimensionality 3 --float 0 \
#        --output  [${outputDir}t1, ${outputDir}t1.nii.gz] \
#        --interpolation Linear \
#        --winsorize-image-intensities [0.005,0.995] \
#        --use-histogram-matching 0 \
#        --initial-moving-transform [${t2}.nii.gz,${t1}.nii.gz,1] \
#        --transform Rigid[0.1] \
#        --metric MI[${t2}.nii.gz,${t1}.nii.gz,1,64,Regular,0.4] \
#        --convergence [5000x1000x500x200,1e-6,10] \
#        --shrink-factors 8x4x2x1 \
#        --smoothing-sigmas 3x2x1x0vox \
#        --transform Affine[0.1] \
#        --metric MI[${t2}.nii.gz,${t1}.nii.gz,1,64,Regular,0.4] \
#        --convergence [5000x1000x500x200,1e-6,10] \
#        --shrink-factors 8x4x2x1 \
#        --smoothing-sigmas 3x2x1x0vox
#
#
#
#rm -r ${outputDir}t10GenericAffine.mat
#
#
#
#

############################################################################
# adding files into the output directory
############################################################################
[[ -f ${outputDir}t1.nii.gz ]] || cp ${t1}.nii.gz ${outputDir}t1.nii.gz
[[ -f ${outputDir}t2.nii.gz ]] || cp ${t2}.nii.gz ${outputDir}t2.nii.gz
[[ -f ${outputDir}func.nii.gz ]] || cp ${func} ${outputDir}func.nii.gz
[[ -f ${outputDir}dseg.nii.gz ]] || cp ${dseg}.nii.gz ${outputDir}dseg.nii.gz
[[ -f ${outputDir}mag.nii.gz ]] || cp ${mag}e1.nii.gz ${outputDir}mag.nii.gz
[[ -f ${outputDir}mask.nii.gz ]] || cp ${mask}.nii.gz ${outputDir}mask.nii.gz

# scan_pma = info.txt
# birth_ga = info.txt
# echo_spacing = info.txt
# phase encoding direction = ??
# func order = slicetime.txt
# fieldmap = fmap_rads
# t1 in t2 space = t1.nii.gz
# t2 mask = mask.nii.gz
# sbref = sbref.nii.gz

