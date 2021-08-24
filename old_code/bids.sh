#!/bin/bash

###Written by Alexander Weber
###Jan 2021

###Exit if an error occurs
set -e

###Scaffold, first step
###Commented because this is often done before running this script
#dcm2bids_scaffold

###Define pathways
toplvl=/mnt/WeberLab/Projects/NeonateSucrose/SickKids

###Create dataset_description.json
jo -p "Name"="SickKids Data and Mount Sinai" "BIDSVersion"="1.0.2" > dataset_description.json

subjectlist=${toplvl}/code/directories.txt

touch participants.csv
echo "SubjectNumber,Participant" > participants.csv

count=1

while read -r subject;
do
    printf -v j "%03d" $count
    printf "\n\n Now running BIDS on Participant ${subject} as Subject number ${j}\n\n"

    ###use dcm2bids helper to convert dicom to nifti in temporary folder
    dcm2bids_helper -d ${toplvl}/sourcedata/${subject}/

    ###build dcm2bids_config.json file to tell bids what files to convert and how to organize them
    ###T1w is not labelled in a regular way unfortunately
    ###fMRI isn't either
    ###I can't figure out how to grab the gre field map other than to label it as dwi
    ###
    jo -p descriptions=$(jo -a $(jo dataType=anat modalityLabel=T1w criteria=$(jo SeriesDescription=T1*)) $(jo dataType=func modalityLabel=bold customLabels=task-rest TaskName=rest criteria=$(jo SeriesDescription=fMRI*) $(jo dataType=dwi modalityLabel=dwi criteria=$(jo SeriesDescription=gre_field_mapping*)))) > ${toplvl}/code/dcm2bids_config.json

    dcm2bids -d ${toplvl}/sourcedata/${subject} -p $j -c ${toplvl}/code/dcm2bids_config.json

    echo "${j},${subject}" >> participants.csv

    count=$[$count +1]
done < $subjectlist
