#!/bin/bash

###Written by Alexander Weber
###Jan 2021

###Exit if an error occurs
set -e

###Define pathways
toplvl=/mnt/WeberLab/Projects/NeonateSucrose/SickKids

###

subjectlist=${toplvl}/code/funcdir.txt

touch FD.csv
echo "SubjectNumber,V,FD" > FD.csv

while read -r subject;
do
    printf "\n\n MCLIFT on file ${subject}\n\n"
    v=$(echo $subject | cut -d"/" -f3)
    subid=$(echo $subject | cut -d"/" -f4)
    ###
    mkdir -p ${toplvl}/derivatives/func/$v/${subid}
    mcflirt -in ${toplvl}/Raw3/$v/${subid}/func/${subid}_rest_run1.nii.gz -stats -mats -plots
    mv ${toplvl}/Raw3/$v/${subid}/func/*_mcf* ${toplvl}/derivatives/func/$v/${subid}/
    FD=$(FD.r ${toplvl}/derivatives/func/$v/${subid}/*.par)
    echo "${subid},${v},${FD}" >> FD.csv

done < $subjectlist
