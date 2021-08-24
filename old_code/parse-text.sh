###########################################################################################
#Function that outputs array of all T1 scan of passed Subject e.g. MS040002_V01
###########################################################################################

FILE=PretermCare_list_of_all_series.txt

pares-func() {

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



###########################################################################################
#Creates a Folder based on T1 images that have not been converted and converts them to
#nifti
###########################################################################################
age=v11

picture_file="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/T1Pictures/${age}/"
mkdir /mnt/WeberLab/Projects/NeonateSucrose/SickKids/TempPicture
mkdir /mnt/WeberLab/Projects/NeonateSucrose/SickKids/TempPicture/${age}
temp_picture="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/TempPicture/${age}/"
final="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Rawtemp/${age}/"

for sub in $picture_file*; do
id=$(basename $sub)
file_content=$( cat $FILE )
regex="[0-9]{8}_${id}_V${age:1}"

if [[ "$file_content" =~ $regex ]]; then

mkdir ${temp_picture}${id}
arr=$(pares-func "${id}_V${age:1}"; echo ${array[*]})


for file in $arr; do
length=$(ls ${sub} | wc -l)
count=0

for image in $sub/*; do
if [[ $image != *"${id}_${file}"* ]]; then
count=$(($count+1))
fi

if [[ $count -eq $length ]]; then
echo "${id} -> ${file}"
dcm2niix \
-o ${temp_picture}/${id}/ \
-f ${id}_${file}  \
-b y \
-v y \
-z y \
/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/${age}/${id}/${file}
fi
done

done


fi
done



###########################################################################################
#Creates a folder of .png for quality inspection from previous section
###########################################################################################



for i in $temp_picture*; do
sub=$(basename $i)
#echo "On Picture ${sub}"
mkdir ${final}${sub}

for j in $i/*; do
base=$(basename $j)
baseclip=${base%%.nii.gz}
echo ${j}
if [[ ${base} == *".nii.gz" ]] && [[ ${base: -8:1} != "a" ]]; then
picture="${final}${sub}/${sub}_${baseclip}.png"
slicer ${j} -S 3 1300 ${picture}
fi

done
done
