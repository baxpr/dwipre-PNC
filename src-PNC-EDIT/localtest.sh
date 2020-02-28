#!/bin/bash

pipeline.sh \
    --dti35_niigz ../INPUTS/DTI_2x32_35.nii.gz \
    --dti35_bvals ../INPUTS/DTI_2x32_35.bval \
    --dti35_bvecs ../INPUTS/DTI_2x32_35.bvec \
    --dti36_niigz ../INPUTS/DTI_2x32_36.nii.gz \
    --dti36_bvals ../INPUTS/DTI_2x32_36.bval \
    --dti36_bvecs ../INPUTS/DTI_2x32_36.bvec \
    --bet_opts "-f 0.3 -R" \
    --acq_params "0 -1 0 0.05" \
    --project TESTPROJ \
    --subject TESTSUBJ \
    --session TESTSESS \
    --outdir ../OUTPUTS
