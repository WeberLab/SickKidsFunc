#########################################################################
# Master csv parser
# Fills in empty cells in $FILEog if needed, if 3 spaces in a row, you
# need to re-run the empty cell filling command.
# Takes variable-age input (e.g. birthagev01) and outputs an arrayy of all
# v01 ages. So if you also pass in subjectage then you can marry up any
# variable to any subject
#e.g.

#listage=$(bash ${highDir}code/parse-csv-function.sh scanage${age})
#listsubject=$(bash ${highDir}code/parse-csv-function.sh subject${age})

#count=1
#for i in ${listsubject[@]}; do
#if [[ ${i} == ${subjectid} ]]; then
#agescan=$(echo ${listage} | cut -d " " -f ${count})
#fi
#count=$((count+1))
#done

#If the .csv headers change you just need to change to order of the while read line
#########################################################################


#FILEog=/Users/johanndrayne/Desktop/FDlt1mm_wSucrose_bestT1T2Data.csv
#FILElt1mminitial=/Users/johanndrayne/Desktop/FDlt1mm_wSucrose_bestT1T2Data2.csv
FILE=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/PretermSucroseSubjectinfo_new.csv
#FILE=/mnt/WeberLab/Projects/NeonateSucrose/SickKids/subject_info.csv

#sed 's/ *,/,/g' ${FILEog} | sed 's/,,/,NA,/g' > ${FILElt1mminitial}
#sed 's/ *,/,/g' ${FILElt1mminitial} | sed 's/,,/,NA,/g' > ${FILElt1mm}

#rm -r ${FILElt1mminitial}

INPUT="${FILE}"
OLDIFS=$IFS
IFS=','
list=(subjectv01 t1filenamev01 t2filenamev01 birthagev01 scanagev01 grefilenamev01 t1Checkedv01 t2Checkedv01 scan_lengthv01
      subjectv11 t1filenamev11 t2filenamev11 birthagev11 scanagev11 grefilenamev11 t1Checkedv11 t2Checkedv11 scan_lengthv11
      subjectv02 t1filenamev02 t2filenamev02 birthagev02 scanagev02 grefilenamev02 t1Checkedv02 t2Checkedv02 scan_lengthv02
      subjectv12 t1filenamev12 t2filenamev12 birthagev12 scanagev12 grefilenamev12 t1Checkedv12 t2Checkedv12 scan_lengthv12)


subjectv01=()
t1filenamev01=()
t2filenamev01=()
grefilenamev01=()
birthagev01=()
scanagev01=()
t1Checkedv01=()
t2Checkedv01=()
scan_lengthv01=()

subjectv11=()
t1filenamev11=()
t2filenamev11=()
grefilenamev11=()
birthagev11=()
scanagev11=()
t1Checkedv11=()
t2Checkedv11=()
scan_lengthv11=()

subjectv02=()
t1filenamev02=()
t2filenamev02=()
grefilenamev02=()
birthagev11=()
scanagev11=()
t1Checkedv02=()
t2Checkedv02=()
scan_lengthv02=()

subjectv12=()
t1filenamev12=()
t2filenamev12=()
grefilenamev01=()
birthagev12=()
scanagev12=()
t1Checkedv12=()
t2Checkedv12=()
scan_lengthv12=()


[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

while read SubjectNumber V birthage scanage FD scan_length t1FileName t1Info t1Checked t2FileName t2Info t2Checked x1 x2
do

        if [[ $V == "v01" ]]; then
                subjectv01+=($SubjectNumber)
                t1filenamev01+=($t1FileName)
                t2filenamev01+=($t2FileName)
                grefilenamev01+=($x1)
		birthagev01+=($birthage)
		scanagev01+=($scanage)
		t1Checkedv01+=($t1Checked)
		t2Checkedv01+=($t2Checked)
		scan_lengthv01+=(${scan_length})

        elif [[ $V == "v11" ]]; then
                subjectv11+=($SubjectNumber)
                t1filenamev11+=($t1FileName)
                t2filenamev11+=($t2FileName)
                grefilenamev11+=($x1)
		birthagev11+=($birthage)
		scanagev11+=($scanage)
                t1Checkedv11+=($t1Checked)
                t2Checkedv11+=($t2Checked)
		scan_lengthv11+=(${scan_length})

        elif [[ $V == "v02" ]]; then
                subjectv02+=($SubjectNumber)
                t1filenamev02+=($t1FileName)
                t2filenamev02+=($t2FileName)
                grefilenamev02+=($x1)
		birthagev02+=($birthage)
		scanagev02+=($scanage)
                t1Checkedv02+=($t1Checked)
                t2Checkedv02+=($t2Checked)
		scan_lengthv02+=(${scan_length})

        elif [[ $V == "v12" ]]; then
                subjectv12+=($SubjectNumber)
                t1filenamev12+=($t1FileName)
                t2filenamev12+=($t2FileName)
                grefilenamev12+=($x1)
		birthagev12+=($birthage)
		scanagev12+=($scanage)
                t1Checkedv12+=($t1Checked)
                t2Checkedv12+=($t2Checked)
		scan_lengthv12+=(${scan_length})

        fi

done < $INPUT
IFS=$OLDIFS




for i in ${list[@]}; do
if [[ $1 == $i ]]; then
var=$i[@]
echo ${!var}
fi
done
