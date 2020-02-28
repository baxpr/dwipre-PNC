#!/bin/bash

cd "${outdir}"

create_file_manifest.sh


mkdir MANIFEST
mv manifest.txt MANIFEST


mkdir PDF
mv dwipre-PNC.pdf PDF


mkdir PRE_EDDY_NIFTI
mv dwmri.nii.gz PRE_EDDY_NIFTI

mkdir PRE_EDDY_BVALS
mv dwmri.bvals PRE_EDDY_BVALS

mkdir PRE_EDDY_BVECS
mv dwmri.bvecs PRE_EDDY_BVECS


mkdir EDDY_NIFTI
mv eddy.nii.gz EDDY_NIFTI

mkdir EDDY_BVALS
mv eddy.bvals EDDY_BVALS

mkdir EDDY_BVECS
mv eddy.eddy_rotated_bvecs EDDY_BVECS

mkdir EDDY_OUT
mv eddy.* EDDY_OUT
mv index.txt EDDY_OUT
mv acqparams.txt EDDY_OUT


mkdir B0_MEAN
mv b0_mean.nii.gz B0_MEAN

mkdir B0_MASK
mv b0_mask.nii.gz B0_MASK


mkdir DTIFIT
mv dtifit_* DTIFIT

