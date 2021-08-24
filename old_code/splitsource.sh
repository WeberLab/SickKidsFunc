#/mnt/WeberLab/Projects/NeonateSucrose/SickKids/code
#####################################################################
#This script looks at the source data (dicom files) in $source and
#copies them into ~/../Raw2 based on their suffix (i.e v**)
#The script then renames them leaving obly the subject ID
#####################################################################
source="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/sourcedata/"

mkdir /mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v01
mkdir /mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v02
mkdir /mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v11
mkdir /mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v12

v01="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v01/"
v02="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v02/"
v11="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v11/"
v12="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/v12/"

number=$(ls -l $source | grep "^d" | wc -l)

count=1


for d in $source*; do


if [[ ${d:(-2):2}  == "01" ]]; then
cp -r $d $v01
echo "${d} is cped in SickKids/Raw2/v01"


elif [[ ${d:(-2):2}  == "02" ]]; then
cp -r $d $v02
echo "${d} is cped in SickKids/Raw2/v02"


elif [[ ${d:(-2):2}  == "11" ]]; then
cp -r $d $v11
echo "${d} is cped in SickKids/Raw2/v11"


else
cp -r $d $v12
echo "${d} is cped in SickKids/Raw2/v02"


fi
echo "file ${count} of ${number} has been copied"
count=$((count + 1)) 

done


directory2="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/"


for f in $directory2* ; do

for i in "$f"/*; do
str=${i:(-12):8}

mv -v "$i" "${f}/${str}"

done

done
