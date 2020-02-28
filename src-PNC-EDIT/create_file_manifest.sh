#!/bin/bash
# 
# Create list of output files with MD5 hash

cd "${outdir}"

md5sum \
  dwipre-PNC.pdf \
  dwmri.nii.gz \
  dwmri.bvals \
  dwmri.bvecs \
  eddy.nii.gz \
  eddy.bvals \
  eddy.eddy_rotated_bvecs \
  eddy.* \
  index.txt \
  acqparams.txt \
  b0_mean.nii.gz \
  b0_mask.nii.gz \
  dtifit_* \
> manifest.txt
