age="v01"


toplevel="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/"
data="${toplevel}TempTemplateConstruction${age}/"
output_stripped="${toplevel}skull_strip_${age}/"
output_picture="${toplevel}skull_strip_picture_${age}/"

mkdir ${output_stripped}
mkdir ${output_picture}

total=$(ls $data | wc -l)
count=0
#for file in ${data}*; do
#count=$((count + 1))
#filename=$(basename $file)
#output="${output_stripped}${filename}"
#
#runROBEX.sh $file $output
#echo "${count}/${total}"
#
#done


count=0
for i in ${output_stripped}*; do
count=$((count + 1))
filename=$(basename $i)
base=${filename%%.nii.gz}
output="${output_picture}${base}"

slicer ${i} "${data}${filename}" -S 3 1300 "${output}.png"
echo "${count}/${total}"

done
