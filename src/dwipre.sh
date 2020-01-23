#!/bin/bash

### PREPROCESSING SCRIPT FOR PNC_V3 DTI DATA

## These assumptions are hardcoded:
#    - Only a single entry allowed in acq_params file, applied to all DWI volumes
#    - b=0 volumes are indicated with a value of exactly 0 in the bval files

## Input files from xnat (see pipeline.sh for the env variables that hold the filenames)
#    - DTI_2x32_35.nii.gz/bval/bvec (run #1)
#    - DTI_2x32_36.nii.gz/bval/bvec (run #2)

## Major output files are:
#    - dwmri.nii.gz        Original DWI images, globally rescaled per run
#    - dwmri.bvals         bvals for above
#    - dwmri.bvecs         bvecs for above
#    - b0_mean.nii.gz      average of all coregistered b=0 images
#    - b0_mask.nii.gz      binary brain mask from BET
#    - acq_params.txt
#    - index.txt
#    - EDDY results in eddy.<contents>
#        - nii.gz                    eddy corrected dwi series
#        - rotated_bvecs             adjusted b vectors
#        - bvals                     b values copied from input
#        - eddy_cnr_maps.nii.gz      snr for b0s, cnr for dwis
#        - eddy_parameters           inter-volume movement 6 dof
#        - eddy_movement_rms
#        - eddy_restricted_movement_rms
#        - eddy_values_of_all_input_parameters
#        - eddy_command_txt


## QC plots are:
#	- bet_qc.png = lightbox plot of b0.nii.gz with red skull-stripped mask outline
#	- 


# BET options (note, -n -m are already hard-coded later, for pipeline 
# to work correctly)
export bet_opts="-f 0.3 -R"

# Acquisition params. Only one line / one entry is accommodated
acq_params="0 -1 0 0.05"

# Functions we will need
#    pre_normalize_dwi
#      get_mask_from_b0
#      find_zero_bvals
source functions.sh


# FIXME 
# Wouldn't hurt to run FDT before and after and make an image to verify bvecs
# Verify that geometry matches for both DTIs


# Copy input files to working directory, with specified filenames
cp "${dti35_niigz}" "${outdir}"/dti35.nii.gz
dti35_niigz=dti35.nii.gz

cp "${dti35_bval}" "${outdir}"/dti35.bvals
dti35_bvals=dti35.bvals

cp "${dti35_bvec}" "${outdir}"/dti35.bvecs
dti35_bvecs=dti35.bvecs

cp "${dti36_niigz}" "${outdir}"/dti36.nii.gz
dti36_niigz=dti36.nii.gz

cp "${dti36_bval}" "${outdir}"/dti36.bvals
dti36_bvals=dti36.bvals

cp "${dti36_bvec}" "${outdir}"/dti36.bvecs
dti36_bvecs=dti36.bvecs


# Work in outputs directory
cd "${outdir}"

## acqparams file
printf "${acq_params}\n" > acqparams.txt

## b0 normalization for 35- and 36-volume runs
# Overwrites existing files with globally scaled values
pre_normalize_dwi "${dti35_niigz}" "${dti35_bvals}"
pre_normalize_dwi "${dti36_niigz}" "${dti36_bvals}"

## concatenate dwi, bvals, bvecs for eddy
fslmerge -t dwmri.nii.gz "${dti35_niigz}" "${dti36_niigz}"
paste -d '\t' "${dti35_bvals}" "${dti36_bvals}" > dwmri.bvals
paste -d '\t' "${dti35_bvecs}" "${dti36_bvecs}" > dwmri.bvecs

## Brain mask on average b=0 of combined image set
get_mask_from_b0 dwmri.nii.gz dwmri.bvals b0

## Index file (one value for each volume of the final combined dwi image set)
# Assume all volumes had the same acq params, the first entry in acq_params.txt
dim4=$(fslhd dwmri.nii.gz |grep ^dim4)
dim4=$(awk '{ print $2 }' <<< ${dim4})
if [ -e index.txt ] ; then rm -f index.txt ; fi
for i in $(seq 1 ${dim4}) ; do echo '1' >> index.txt ; done

## eddy-correction
echo "EDDY"
eddy \
  --imain=dwmri.nii.gz \
  --mask=b0_mask.nii.gz \
  --acqp=acqparams.txt \
  --index=index.txt \
  --bvecs=dwmri.bvecs \
  --bvals=dwmri.bvals \
  --out=eddy \
  --verbose \
  --cnr_maps

cp dwmri.bvals eddy.bvals



### qc plots
echo "QC plot"

## bet qc plot
# 4mm slice spacing with 36 slices gives 144mm coverage which is probably good
fsleyes render \
  --scene lightbox \
  -zx Z -nr 6 -nc 6 -hc -ss 4 \
  --outfile bet_qc.png \
  b0_mean.nii.gz -dr 0 99% \
  b0_mask.nii.gz -ot mask --outline -w 4 -mc 255 0 0

# PDF
convert \
  -size 2600x3365 xc:white \
  -gravity center \( bet_qc.png -resize 2400x \) -geometry +0+0 -composite \
  -gravity North -pointsize 48 -annotate +0+50 "EDDY preprocess for PNC" \
  -gravity SouthEast -pointsize 48 -annotate +50+50 "$(date)" \
  -gravity NorthWest -pointsize 48 -annotate +50+150 "${project} ${subject} ${session}" \
  dwipre-PNC.pdf

