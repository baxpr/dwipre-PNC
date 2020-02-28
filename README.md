# dwipre-PNC-EDIT

Preprocessing pipeline with FSL 5.0.11 eddy, specific to PNC DTI dataset.

This version uses a supplied brain mask instead of finding one with BET.


## Assumptions

- Only a single entry is allowed in acq_params file. It is applied to all DWI volumes.

- b=0 volumes are indicated with a value of exactly 0 in the bval files.


## Pipeline

1. For each run ("dti35" and "dti36"):

    a. A mean b=0 image is computed from all available b=0 volumes.
    
    b. BET is used to find a brain mask for the run.
    
    c. The mean intensity of in-brain voxels is computed.
    
    d. All DWI volumes of the run are scaled by a factor of 1000*(mean intensity).

2. The scaled images are combined into a single series.

3. A mean b=0 image for the combined series is computed, and BET is used to compute a brain mask from it.

4. EDDY is run on the combined series, using the mask from the previous step.


## Inputs

    --dti35_niigz <dti35.nii.gz>      First DWI image set
    --dti35_bvals <dti35.bvals>
    --dti35_bvecs <dti35.bvecs>

    --dti36_niigz <dti36.nii.gz>      Second DWI image set
    --dti36_bvals <dti36.bvals>
    --dti36_bvecs <dti36.bvecs>

    --bet_opts "-f 0.3 -R"            BET options (default shown)
    --acq_params "0 -1 0 0.05"        EDDY acq_params (default shown)

    --project <project_label>         Label information from XNAT
    --subject <subject_label>
    --session <session_label>

    --outdir <output_directory>       Results are stored here


## Outputs

    PDF                 QC report
    
    PRE_EDDY_NIFTI      DW images after global rescaling but before eddy correction
    PRE_EDDY_BVALS
    PRE_EDDY_BVECS
    
    EDDY_NIFTI          Eddy-corrected DW images
    EDDY_BVALS
    EDDY_BVECS
    
    EDDY_OUT            Rest of EDDY output files
    
    B0_MEAN             Mean of b=0 images from PRE_EDDY_NIFTI
    
    B0_MASK             Brain mask found by BET applied to B0_MEAN
    
    DTIFIT              Basic dtifit results from eddy corrected data

## Code info

Code authored by Suzanne Avery and edited by Baxter P. Rogers.

    xwrapper.sh                    Entry point for singularity container - sets up xvfb
     \- pipeline.sh                Entry to processing pipeline - parses inputs and calls processing code
         \- dwipre.sh              Workhorse
            functions.sh           Support functions for dwipre.sh
            qcplots.sh             QC images for PDF    
            organize_outputs.sh    Arranges outputs for DAX
    
    localtest.sh                   To run the pipeline outside the container (for testing)
    test_sing.sh                   Test the singularity container
    

