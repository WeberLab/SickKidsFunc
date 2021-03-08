#-o output directory
#-f filename %p=protocol %f=folder name
#-b BIDS sidecar
#-i ignore  tderived, localizer and 2D images
#-v verbose
#-z compression

mkdir /mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw3

source="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/"

output="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw3/"

count=0

for i in $source*; do

mkdir $output$(basename $i)


for k in $i/*; do

mkdir $output$(basename $i)/$(basename $k)
mkdir $output$(basename $i)/$(basename $k)/func
mkdir $output$(basename $i)/$(basename $k)/anat
func=0
anat=0


for j in $k/*; do

echo "Subject ${count}"
count=$((count + 1))
file="$(basename $j)"



if [[ $file == *"T1"* ]] || [[ $file == *"t1"* ]]; then

anat=$((anat + 1))

dcm2niix \
-o ${output}$(basename $i)/$(basename $k)/anat \
-f $(basename $k)_${file} \
-b y \
-v y \
-z y \
$k/$file

fi


if [[ $file == *"fMRI"* ]]; then

func=$((func + 1))

dcm2niix \
-o ${output}$(basename $i)/$(basename $k)/func \
-f $(basename $k)_${file}  \
-b y \
-v y \
-z y \
$k/$file

fi


done
done
done

