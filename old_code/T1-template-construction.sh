#!/bin/sh

# d = dimension
# a = image statistic (default 1)
# i = Iteration limit
# g = G radient step size
# j = Number of cpu cores (default 2)
# c = control for parallel computation
# k = number of modalities (default 1)
# w = modality weights (default 1)
# f = shrink factor
# s = smoothing factor
# q = max iterations for each pairwise iteration
# n = N4BiasFieldCorrection of moving image 0 == off (default 1)
# r = rigid body registration of inputs before creating template 0 == off (default 0) Useful when no initial template
# l = use linear registration during pairwise registration (default 1)
# m = type of similarity metric (default CC)
# t = type of transformation (default SyN)
#  -f 16x12x8x4x2x1 \
#  -s 4x4x4x2x1x0 \
#  -q 100x100x100x70x50x10 \
data="v02"

highDirectory="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/"
dataDirectory="${highDirectory}Raw4/${data}/"
tempDirectory="${highDirectory}TempTemplateConstruction${data}/"
outputPath="${highDirectory}derivatives/Template${data}/"

mkdir ${tempDirectory}
mkdir ${outputPath}


for sub in ${dataDirectory}*; do
for file in ${sub}/anat/*; do
base=$(basename ${file})
baseclip=${base%%.nii.gz}
found=0
if [[ ${base} == *".nii.gz" ]] && [[ ${base: -8:1} != "a" ]] && [[ ${found} -eq 0 ]]; then
cp ${file} ${tempDirectory}
found=1
fi

done
done


${ANTSPATH}/antsMultivariateTemplateConstruction2.sh \
  -d 3 \
  -a 1 \
  -o ${outputPath} \
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
  ${tempDirectory}*
