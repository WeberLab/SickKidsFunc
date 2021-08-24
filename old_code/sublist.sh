#!/bin/bash
find ./sourcedata/ -maxdepth 1 -type d > ./code/directories.txt
awk '{print $NF}' FS=/ ./code/directories.txt > ./code/tmp.txt
cat ./code/tmp.txt | sort > ./code/directories.txt
