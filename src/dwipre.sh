#!/bin/bash

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

cp "${dti35_bvals}" "${outdir}"/dti35.bvals
dti35_bvals=dti35.bvals

cp "${dti35_bvecs}" "${outdir}"/dti35.bvecs
dti35_bvecs=dti35.bvecs

cp "${dti36_niigz}" "${outdir}"/dti36.nii.gz
dti36_niigz=dti36.nii.gz

cp "${dti36_bvals}" "${outdir}"/dti36.bvals
dti36_bvals=dti36.bvals

cp "${dti36_bvecs}" "${outdir}"/dti36.bvecs
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

