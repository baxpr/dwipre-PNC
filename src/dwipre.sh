#!/bin/bash

### PREPROCESSING SCRIPT FOR PNC_V3 DTI DATA

## These assumptions are hardcoded for this data:
#	- the position of b0s in series (35 vol = 1, 12, 23; 36 vol = 1, 12, 23, 36)
#	- acqparams file (phase encoding of A -> P and readout times; 0 -1 0 0.05)
#	- index file (correspondence between volume and acqparams; 65 x 1's)

## Input files from xnat:
#	- DTI_2x32_35.nii.gz/bval/bvec (run #1)
#	- DTI_2x32_36.nii.gz/bval/bvec (run #2)

## Major output files are:
#	- dwmri.nii.gz = b0 (avg of 7) + dwi run #1 (32 dir) + dwi run #2 (32 dir), raw data
#	- b0.nii.gz = b0 file (average of 7)
#	- b0_brain.nii.gz = skull-stripped b0 file (average of 7)
#	- b0_brain_mask.nii.gz = binary mask from b0_brain.nii.gz
#	- bval.bval = bvals in same order as dwmri.nii.gz 65 vol series
#	- bvec.bvec = bvecs in same order as dwmri.nii.gz 65 vol series
#	- eddy_results.nii.gz = eddy corrected dwi series
# 	- eddy_results.eddy_cnr_maps.nii.gz = snr for b0s, cnr for dwis
#	- eddy_results.eddy_parameters = the first six columns correspond to subject movement (three translations, three rotations)

## QC plots are:
#	- bet_qc.png = lightbox plot of b0.nii.gz with red skull-stripped mask outline
#	- 



## b0 normalization for 35 volume run
fslsplit DTI_2x32_35.nii.gz dwi35_

# get mean b0 value
b0_1=$(fslstats dwi35_0000.nii.gz -M)
b0_2=$(fslstats dwi35_0011.nii.gz -M)
b0_3=$(fslstats dwi35_0022.nii.gz -M)
b0_mean=$(awk "BEGIN {print ($b0_1 + $b0_2 + $b0_3) / 3}")

# apply b0 intensity normalization
array=( dwi35_* )
echo "${array[@]}"

for i in "${array[@]}"
do
   fslmaths $i -div $b0_mean $i
done

# concatenate volumes
fslmerge -t dwi35.nii.gz dwi35_*

# save individual b0s
cp dwi35_0000.nii.gz b0_35_1.nii.gz
cp dwi35_0011.nii.gz b0_35_2.nii.gz
cp dwi35_0022.nii.gz b0_35_3.nii.gz
rm dwi35_*




## b0 normalization for 36 volume run
fslsplit DTI_2x32_36.nii.gz dwi36_

# get mean b0 value
b0_1=$(fslstats dwi36_0000.nii.gz -M)
b0_2=$(fslstats dwi36_0011.nii.gz -M)
b0_3=$(fslstats dwi36_0022.nii.gz -M)
b0_4=$(fslstats dwi36_0035.nii.gz -M)
b0_mean=$(awk "BEGIN {print ($b0_1 + $b0_2 + $b0_3 + $b0_4) / 4}")

# apply b0 intensity normalization
array=( dwi36_* )
echo "${array[@]}"

for i in "${array[@]}"
do
   fslmaths $i -div $b0_mean $i
done

# concatenate volumes
fslmerge -t dwi36.nii.gz dwi36_*

# save individual b0s
cp dwi36_0000.nii.gz b0_36_1.nii.gz
cp dwi36_0011.nii.gz b0_36_2.nii.gz
cp dwi36_0022.nii.gz b0_36_3.nii.gz
cp dwi36_0035.nii.gz b0_36_4.nii.gz
rm dwi36_*




## concatenate dwi runs for eddy
fslmerge -t dwmri.nii.gz dwi35.nii.gz dwi36.nii.gz 
rm dwi3* 





## coregister b0s to 1st b0 in run #1
flirt -in b0_35_2.nii.gz -ref b0_35_1.nii.gz -out b0_35_2.nii.gz -omat b0_35_2_coreg.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp trilinear

flirt -in b0_35_3.nii.gz -ref b0_35_1.nii.gz -out b0_35_3.nii.gz -omat b0_35_3_coreg.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp trilinear

flirt -in b0_36_1.nii.gz -ref b0_35_1.nii.gz -out b0_36_1.nii.gz -omat b0_36_1_coreg.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp trilinear

flirt -in b0_36_2.nii.gz -ref b0_35_1.nii.gz -out b0_36_2.nii.gz -omat b0_36_2_coreg.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp trilinear

flirt -in b0_36_3.nii.gz -ref b0_35_1.nii.gz -out b0_36_3.nii.gz -omat b0_36_3_coreg.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp trilinear

flirt -in b0_36_4.nii.gz -ref b0_35_1.nii.gz -out b0_36_4.nii.gz -omat b0_36_4_coreg.mat -bins 256 -cost corratio -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp trilinear

flirt -in b0_35_2.nii.gz -applyxfm -init b0_35_2_coreg.mat -out b0_35_2_coreg.nii.gz -paddingsize 0.0 -interp trilinear -ref b0_35_1.nii.gz
flirt -in b0_35_3.nii.gz -applyxfm -init b0_35_3_coreg.mat -out b0_35_3_coreg.nii.gz -paddingsize 0.0 -interp trilinear -ref b0_35_1.nii.gz
flirt -in b0_36_1.nii.gz -applyxfm -init b0_36_1_coreg.mat -out b0_36_1_coreg.nii.gz -paddingsize 0.0 -interp trilinear -ref b0_35_1.nii.gz
flirt -in b0_36_2.nii.gz -applyxfm -init b0_36_2_coreg.mat -out b0_36_2_coreg.nii.gz -paddingsize 0.0 -interp trilinear -ref b0_35_1.nii.gz
flirt -in b0_36_3.nii.gz -applyxfm -init b0_36_3_coreg.mat -out b0_36_3_coreg.nii.gz -paddingsize 0.0 -interp trilinear -ref b0_35_1.nii.gz
flirt -in b0_36_4.nii.gz -applyxfm -init b0_36_4_coreg.mat -out b0_36_4_coreg.nii.gz -paddingsize 0.0 -interp trilinear -ref b0_35_1.nii.gz

## average b0s (average of 7)
fslmaths b0_35_1.nii.gz -add b0_35_2_coreg.nii.gz -add b0_35_3_coreg.nii.gz -add b0_36_1_coreg.nii.gz -add b0_36_2_coreg.nii.gz -add b0_36_3_coreg.nii.gz -add b0_36_4_coreg.nii.gz -div 7 b0.nii.gz
rm b0_3*

## bet b0 
bet b0.nii.gz b0_brain -m -f 0.3 -R




## acqparams file
printf '0 -1 0 0.05\n' > acqparams.txt

## index file
printf '1\n%.0s' {1..71} > index.txt

## concatenate bvals and bvecs 
paste -d '\t' DTI_2x32_35.bval DTI_2x32_36.bval > bvals.bvals
paste -d '\t' DTI_2x32_35.bvec DTI_2x32_36.bvec > bvecs.bvecs

## eddy-correction
eddy --imain=dwmri.nii.gz --mask=b0_brain_mask.nii.gz --acqp=acqparams.txt --index=index.txt --bvecs=bvecs.bvecs --bvals=bvals.bvals --out=eddy_results --verbose --cnr_maps





### qc plots

## bet qc plot
fsleyes render --scene lightbox -zx Z -nr 10 -nc 10 --outfile bet_qc b0.nii.gz -dr 0 7 b0_brain_mask.nii.gz -ot mask --outline -mc 255 0 0
