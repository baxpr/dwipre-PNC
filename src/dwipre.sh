#!/bin/bash

### PREPROCESSING SCRIPT FOR PNC_V3 DTI DATA

## These assumptions are hardcoded for this data:
#    - Only a single entry allowed in acq_params file, applied to all DWI volumes
#    - b=0 volumes are indicated with a value of exactly 0 in the bval files

## Input files from xnat (see pipeline.sh for the env variables that hold the filenames)
#    - DTI_2x32_35.nii.gz/bval/bvec (run #1)
#    - DTI_2x32_36.nii.gz/bval/bvec (run #2)

## Major output files are:
#    - dwmri.nii.gz        Original DWI images, globally rescaled per run
#    - dwmri.bvals         bvals for above
#    - dwmri.bvecs         bvecs for above
#    - brain_mean.nii.gz   average of all coregistered b=0 images
#    - brain_mask.nii.gz   binary brain mask from BET
#    - EDDY results in eddy_results.<contents>
#        - nii.gz                    eddy corrected dwi series
#        - rotated_bvecs             adjusted b vectors
#        - bvals                     b values copied from input
#        - eddy_cnr_maps.nii.gz      snr for b0s, cnr for dwis
#        - eddy_parameters           inter-volume movement (three transl, three rot)
#        - eddy_movement_rms
#        - eddy_restricted_movement_rms
#        - eddy_values_of_all_input_parameters
#        - eddy_command_txt


## QC plots are:
#	- bet_qc.png = lightbox plot of b0.nii.gz with red skull-stripped mask outline
#	- 


# FIXME 
# Wouldn't hurt to run FDT before and after and make an image to verify bvecs
# Verify that geometry matches for both DTIs

# Output directory
out_dir=../OUTPUTS

# Inputs (Filenames in out_dir)
dti35_niigz=DTI_2x32_35.nii.gz
dti35_bval=DTI_2x32_35.bval
dti35_bvec=DTI_2x32_35.bvec
dti36_niigz=DTI_2x32_36.nii.gz
dti36_bval=DTI_2x32_36.bval
dti36_bvec=DTI_2x32_36.bvec

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

# Work in outputs directory
cd "${out_dir}"

## acqparams file
printf "${acq_params}\n" > acqparams.txt

## b0 normalization for 35- and 36-volume runs
# Overwrites existing files with globally scaled values
pre_normalize_dwi "${dti35_niigz}" "${dti35_bval}"
pre_normalize_dwi "${dti36_niigz}" "${dti36_bval}"

## concatenate dwi, bvals, bvecs for eddy
fslmerge -t dwmri.nii.gz "${dti35_niigz}" "${dti36_niigz}"
paste -d '\t' "${dti35_bval}" "${dti36_bval}" > dwmri.bvals
paste -d '\t' "${dti35_bvec}" "${dti36_bvec}" > dwmri.bvecs

## Brain mask on average b=0 of combined image set
get_mask_from_b0 dwmri.nii.gz dwmri.bvals brain

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
  --mask=brain_mask.nii.gz \
  --acqp=acqparams.txt \
  --index=index.txt \
  --bvecs=dwmri.bvecs \
  --bvals=dwmri.bvals \
  --out=eddy_results \
  --verbose \
  --cnr_maps

cp dwmri.bvals eddy_results.bvals



### qc plots

## bet qc plot
echo "QC plot"
fsleyes render \
  --scene lightbox \
  -zx Z -nr 10 -nc 10 \
  --outfile bet_qc.png \
  b0.nii.gz -dr 0 7 \
  b0_brain_mask.nii.gz -ot mask --outline -mc 255 0 0

# PDF
convert \
  -size 2600x3365 xc:white \
  -gravity center \( bet_qc.png -resize 2400x1200 \) -geometry +0+0 -composite \
  -gravity center -pointsize 48 -annotate +0-1300 "eddy preprocess for PNC" \
  -gravity SouthEast -pointsize 48 -annotate +50+50 "$(date)" \
  -gravity NorthWest -pointsize 48 -annotate +50+50 "${project} ${subject} ${session}" \
  dwipre-PNC.pdf
