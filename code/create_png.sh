#!/bin/bash
###########################################################################################
# looks at scans in ${inputDir} under specified ${modality} (either t1, t2, gre, func)
# and creates a png folder ${pngDir} containing png of slices of the brain to determine
# the best quality scan
###########################################################################################

highDir=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/
inputDir=${highDir}Raw6/

#choose modality to create the PNGs' for t1/t2/gre
modality=t2

pngDir=${highDir}Raw_${modality}_png/


[[ -d ${pngDir} ]] || mkdir ${pngDir}
[[ -d ${pngDir}v01/ ]] || mkdir ${pngDir}v01/
[[ -d ${pngDir}v11/ ]] || mkdir ${pngDir}v11/
[[ -d ${pngDir}v02/ ]] || mkdir ${pngDir}v02/
[[ -d ${pngDir}v12/ ]] || mkdir ${pngDir}v12/


for ages in ${inputDir}*; do
age=$(basename $ages)

for subjects in ${ages}/*; do
subject=$(basename $subjects)
[[ -d ${pngDir}${age}/${subject}/ ]] || mkdir ${pngDir}${age}/${subject}/

for scans in ${subjects}/${modality}/*.nii.gz; do
scan=$(basename $scans)
scan_strip=${scan%%.nii.gz}
png_str=${pngDir}${age}/${subject}/${scan_strip}.png
#slicer ${scans} -S 3 1300 ${png_str}
echo "slicer ${scans} -S 3 1300 ${png_str}"
done
done
done
