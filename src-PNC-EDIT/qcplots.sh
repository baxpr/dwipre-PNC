#!/bin/bash

cd "${outdir}"

### qc plots
echo "QC plot"

## dtifit view
# V1
fsleyes render -of dti_v1.png --size 2400 1200 \
    -hc -hl -xz 1200 -yz 1200 -zz 1200 \
    dtifit_FA.nii.gz \
    dtifit_V1.nii.gz -ot linevector

# TENSORS
fsleyes render -of dti_tensors.png --size 2400 1200 \
    -vl 64 65 45 --hidex --hidez -hc -hl -yz 1700 \
    dtifit_FA.nii.gz \
    dtifit_tensor.nii.gz -ot tensor

## bet qc plot
# 4mm slice spacing with 36 slices gives 144mm coverage which is probably good
fsleyes render -of bet_qc.png --size 2400 2400 \
  --scene lightbox \
  -zx Z -nr 6 -nc 6 -hc -ss 4 \
  b0_mean.nii.gz -dr 0 99% \
  b0_mask.nii.gz -ot mask --outline -w 4 -mc 255 0 0


# PDF
convert \
  -size 2600x3365 xc:white \
  -gravity center \( bet_qc.png -resize 2400x \) -geometry +0+0 -composite \
  -gravity North -pointsize 48 -annotate +0+50 "EDDY preprocess for PNC" \
  -gravity SouthEast -pointsize 48 -annotate +50+50 "$(date)" \
  -gravity NorthWest -pointsize 48 -annotate +50+150 "${project} ${subject} ${session}" \
  page1.png

convert \
  -size 2600x3365 xc:white \
  -gravity center \( dti_v1.png -resize 2400x1200 \) -geometry +0-650 -composite \
  -gravity center \( dti_tensors.png -resize 2400x1200 \) -geometry +0+650 -composite \
  -gravity center -pointsize 48 -annotate +0-1300 "Tensor reconstruction (dtifit)" \
  -gravity SouthEast -pointsize 48 -annotate +50+50 "$(date)" \
  -gravity NorthWest -pointsize 48 -annotate +50+150 "${project} ${subject} ${session}" \
  page2.png
  
convert page1.png page2.png dwipre-PNC.pdf

