# File summary
The following will list some Bash issues that Johann Drayne overcame at BCCHR from January-August 2021 and worked examples of code which resolved them.

**NOTE:** My biggest Bash tip is to pay close attention to syntax. Especially if you are big into Pythonic styling:
* Python: greeting = "Hello World!"
* Bash: greeting="Hello World!"
Inconspicuous spaces in Bash cause annoying errors.  

## List of Issues

1. Acquiring subject data from spreadsheet throughout pipeline 
2. 'Bashify' your `if` statement
3. Parsing `.json` file
4. Bash maths
5. Turning list of numbers into indexes (smallest - largest) 
6. Saving a terminal command output as a variable
7. Writing to .csv




## 1. Acquiring subject data from spreadsheet throughout pipeline 

**NOTE**: This may not be the best way of parsing values from a study specific spreadsheet, but it is simple enough to understand and it  works. However, it would probably be useful to become familiar with `awk` and the `parse_csv_master.sh` would probably not be needed.

For this method to work, the `.csv`:
* Cannot have empty cells. Enter NaN or nan if you need to
* Cannot include `,` within cells, the cells are split by commas and having extra ones will not return the correct column you were asking for
To automatically fill in empty cells you can `sed 's/ *,/,/g' ${FILE_master} | sed 's/,,/,NA,/g' > ${FILE_filled}` 
However, this method only works if the cell after an empty cell has been filled. You will have to run the command twice to fill in rows with more than one empty cell side by side. 

The master script is `parse_csv_master.sh` and an example of code to parse out any specific variable. Can be found in `dhcp_func/input_dhcp_func.sh` line 48.

    listscanage=$(bash ${dataDir}code/parse_csv_master.sh scanage${age})
    listbirthage=$(bash ${dataDir}code/parse_csv_master.sh birthage${age})
    listsubject=$(bash ${dataDir}code/parse_csv_master.sh subject${age})
    listgrefile=$(bash ${dataDir}old_code/parse_csv_master.sh grefilename${age})
    
    count=1
    
    for i in ${listsubject[@]}; do
    
    if [[ ${i} == ${subid} ]]; then
    
    scan_pma=$(echo ${listscanage} | cut -d " " -f ${count})
    birth_ga=$(echo ${listbirthage} | cut -d " " -f ${count})
    gre=$(echo ${listgrefile} | cut -d " " -f ${count})
    
    fi
    
    count=$((count+1))
    done


## 2. 'Bashify' your `if` statement
I use this to cleanly write if statements. I find this most useful with:
*  `mkdir` or `cp` commands in a pipeline script
*  looking for a file that may be in multiple locations

### Basic idea
|| == or
&& == and

Whenever you provide the double square brackets [[]] this is evaluated as a truth statement. If you have a truth then whatever is after a || will not run as the truth has been satisfied, conversely whatever is after a && will run.
Moreover, if you have a false then whatever is after a || will run as the truth has not been satisfied, conversely whatever is after a && will not run.



### `mkdir` or `cp` commands
`[[ -d  ${derivDir}dhcp_func_input ]] || mkdir ${derivDir}dhcp_func_input`

If `${derivDir}dhcp_func_input` exists, do nothing. If it does not exist, then `mkdir` the folder. This is useful for stopping the annoying `folder exists` warning. 

`[[ -d  ${outputDir} ]] && rm -r ${outputDir}  && mkdir ${outputDir}  || mkdir ${outputDir}`
If `${outputDir}` exists, delete the whole folder then `mkdir` the folder. If it does not exist `rm -r ${outputDir}` will become False then the next `mkdir ${outputDir}` will become False and so the final  `mkdir ${outputDir}` will run due to the `||` (or statement).

### Locating the path to a file
This is useful for finding the correct path to the dHCP anatomical outputs as sometimes they can be in `workdir` or `derivatives`
An example of the main files begin line 97 `dhcp_func/input_dhcp_func.sh`

    workingt1=${dhcpanat}workdir/${subid}-${sesid}/restore/T1/${subid}-${sesid}_restore
    derivt1=${dhcpanat}derivatives/sub-${subid}/ses-${sesid}/anat/sub-${subid}_ses-${sesid}_T1w_restore
    [[ -f ${workingt1}.nii.gz ]] && t1=${workingt1} || t1=${derivt1}

Now the correct path to the dHCP T1 scan will be stored in `${t1}`




## 3. Parsing `.json` file
*Reason:* To automatically find the TR or Shim Settings or Echo Spacing of the scan in question. 
**NOTE**: You may need to install the package jq, this requires root privileges.

### Where to find 
`dhcp_func/input_dhcp_func.sh`
line 172, block starting with 
`# parsing echospacing and creatig slice time file from func .json file`

#### Parse Echo Spacing
`echospacing=$(jq .EffectiveEchoSpacing ${file})`

#### Parse Shim Setting
`echospacing=$(jq .ShimSetting ${file})`
However, this will return something like `[-10053,-2620,-2577,430,188,-1228,694,289]` so to turn this into a Bash array I did:

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

#### Parse Shim Setting
Instead of creating a Bash array from the `.json` it would be more useful to add the variables into a `.txt` file where other scripts can easily parse out the values. 

    touch ${slicetimefile}
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

## 4. Bash maths
Bash is definitely sub-optimal to use for math. However, basic operations can certainly be accomplished. There are many different ways to do non-integer maths in Bash (e.g. `jq`, `bc` or `awk`), I am not qualified to advise on the best option. I personally use `jq` but I do not know the advantages/disadvantages.

Here is a list of [ridiculously extensive alternatives,](https://stackoverflow.com/questions/12722095/how-do-i-use-floating-point-arithmetic-in-bash) enjoy trying to decide which one to use. : D
**NOTE**: You may need to install the package jq, this requires root privileges.

### Automatically padding an image to a specific dimension.

    test=$(fslhd ${file} | awk '/dim[0-9]/ { print $2 }' )
    
    dim1=$( echo ${test} | cut -d' ' -f2 )
    dim2=$( echo ${test} | cut -d' ' -f3 )
    dim3=$( echo ${test} | cut -d' ' -f4 )
    dim1add=$(((( 192 - dim1 )) / 2 ))
    dim2add=$(((( 192 - dim2 )) / 2 ))
    dim3add=$(((( 192 - dim3 )) / 2 ))
    
    3dZeropad -prefix ${sub}/anat/${baseclip} -L ${dim1add} -R ${dim1add} -A ${dim2add} -P ${dim2add} -I ${dim3add} -S ${dim3add} ${file}
    3dAFNItoNIFTI -prefix ${tempDirectory}${baseclip}.nii.gz ${sub}/anat/${baseclip}+orig.BRIK

### basic integer
    E=1296863.27001857757568359375
    S=21997
    F=$(($E/$S))

### jq
    E=1296863.27001857757568359375
    S=21997
    F=$( jq -n $E/$S)

### bc

    E=1296863.27001857757568359375
    S=21997
    F=$(echo "$E / $S" |bc)
    F=$(echo "scale=20; $E / $S" |bc)
    
  `"scale=20"` specifies 20 d.p. the default is 0 d.p.

### awk

    E=1296863.27001857757568359375
    S=21997
    F=$(echo $E $S | awk '{print $1/$2}')

## 5. Turning list of numbers into indexes (smallest - largest) 
*Reason:* To automatically find the slice order of acquisition. The dHCP pipeline for example want to know the indexes of slice acquisition order.  
**NOTE**: You may need to install the package jq, this requires root privileges.
**NOTE**: you will also need to create or have `${slicetimefile}`. This is covered in one of the sub-topics in **4. Parsing `.json` file**

### Where to find 
`dhcp_func/input_dhcp_func.sh`
line 172, block starting with 
`# parsing echospacing and creatig slice time file from func .json file`

	touch ${sliceorderfile}
	touch ${slicetempfile}
    sort -nu ${slicetimefile} | awk 'NR == FNR {rank[$0] = NR; next} {print rank[$0]}' - ${slicetimefile} > ${slicetempfile}
    awk '{$1=$1-1; print}' ${slicetempfile} > ${sliceorderfile}
    rm -r ${slicetempfile}


## 6. Saving a terminal command output as a variable
*Reason:* You want to call a variable numerous times, or somehow use the output of a function as an input to another. 
There are many ways to save a variable.

### Time taken to run a script
Used in `welch_and_tissue_mask.sh`

    start=`date +%M`
    end=`date +%M`
    time_taken=$( jq -n ${end}-${start} )
    echo  "----- Time taken = ${time_taken} minutes-----"

### Saving output from `fslstats`
Line 117 in `post_smooth_normal.sh`
`func_q50=$(fslstats ${func_masked} -k ${mask} -p 50)`


### Padding a number with zeros 
e.g. You have 9 and 13 but want 0009 and 0013 respectively. 
Line 55 in `welch_and_gICA_mask.sh`


    network1=9
    network2=13
    
    new_network1=$(printf "%04d\n" $network1)
    new_network2=$(printf "%04d\n" $network2)


## 7. Writing to .csv
*Reason:* This is useful if your pipeline takes a long time to run and so saving it to a `.csv` is useful.

### Writing many to same row 
Begins line 120 in `welch_and_gICA_mask.sh`

    touch ${infofile}
    
    echo -n "${subject},${age}," >> ${infofile}
    
    echo -n `fslstats ${welch_visual} -n -M` >> ${infofile}
    echo -n "," >> ${infofile}
    echo -n `fslstats ${welch_visual} -n -S` >> ${infofile}
    echo -n "," >> ${infofile}
    
    echo -n `fslstats ${welch_motor} -n -M` >> ${infofile}
    echo -n "," >> ${infofile}
    echo -n `fslstats ${welch_motor} -n -S` >> ${infofile}
    echo "," >> ${infofile}

When the `-n` flag is added the the newline character (`\n` ) is not added and so you can echo more variables onto the same `.csv` row. 

> Written with [StackEdit](https://stackedit.io/).
