#!/bin/bash
#find ./sourcedata/ -maxdepth 1 -type d > ./code/directories.txt
find ./Raw3/ -name "*_rest_*.nii.gz" -type f > ./code/funcdir.txt
#awk '{print $NF}' FS=/ ./code/funcdir.txt > ./code/ftmp.txt
cat ./code/funcdir.txt | sort > ./code/ftmp.txt
#cat ./code/ftmp.txt | cut -d"/" -f2 > ./code/funcdir.txt
cp ./code/ftmp.txt ./code/funcdir.txt
