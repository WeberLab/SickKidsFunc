#echo "${age}/${subject}  has filename  ${file}" >> ${filename}

source="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/Raw2/"
filename="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/namechecker.txt"
not1file="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/no-t1-scan-subjects.txt"
not2file="/mnt/WeberLab/Projects/NeonateSucrose/SickKids/no-fmri-scan-subjects.txt"
#touch ${filename}
#touch ${not1file}
touch ${not2file}

for i in $source*; do
age="$(basename $i)"

for k in $i/*; do
subject="$(basename $k)"
echo "On ${age}/${subject}"
scan1=0
scan2=0

for j in $k/*; do
file="$(basename $j)"
if [[ $file != *"fMRI"* ]] && [[ $file != *"T1"* ]] && [[ $file != *"t1"* ]] && [[ $file != *"t2"* ]] && [[ $file != *"gre"* ]] && [[ $file != *"T2"* ]]; then
echo "${scan}"
fi

if [[ $file == *"T1"* ]] || [[ $file == *"t1"* ]]; then
scan1=1
fi

if [[ $file == *"fMRI"* ]]; then
scan2=1
fi

done

for x in $k/*; do
file1="$(basename $x)"
#if [[ $scan1 -eq 0 ]]; then
#echo "${age}/${subject}  has filename  ${file1}" >> ${not1file}
#fi
done

if [[ $scan2 -eq 0 ]]; then
echo "${age}/${subject}" >> ${not2file}
fi

done
done
