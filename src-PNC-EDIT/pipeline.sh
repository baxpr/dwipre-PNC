#!/bin/bash

# Default acquisition params. Only one line / one entry is accommodated
export acq_params="0 -1 0 0.05"

# Parse command line options
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    --dti35_niigz)
        export dti35_niigz="$2" ; shift; shift;;
    --dti35_bvals)
        export dti35_bvals="$2" ; shift; shift;;
    --dti35_bvecs)
        export dti35_bvecs="$2" ; shift; shift;;
    --dti36_niigz)
        export dti36_niigz="$2" ; shift; shift;;
    --dti36_bvals)
        export dti36_bvals="$2" ; shift; shift;;
    --dti36_bvecs)
        export dti36_bvecs="$2" ; shift; shift;;
    --mask_niigz)
        export mask_niigz="$2"  ; shift; shift;;
    --acq_params)
        export acq_params="$2"  ; shift; shift;;
    --project)
        export project="$2"     ; shift; shift;;
    --subject)
        export subject="$2"     ; shift; shift;;
    --session)
        export session="$2"     ; shift; shift;;
    --outdir)
        export outdir="$2"      ; shift; shift;;
    *)
        echo "Ignoring unknown option ${1}"
        shift ;;
  esac
done

# Report inputs
echo "${project} ${subject} ${session}"
echo "    ${dti35_niigz}"
echo "       ${dti35_bvals}"
echo "       ${dti35_bvecs}"
echo "    ${dti36_niigz}"
echo "       ${dti36_bvals}"
echo "       ${dti36_bvecs}"
echo "outdir: $outdir"
echo "mask: $mask_niigz"
echo "acq_params: $acq_params"

# Run eddy pipeline
dwipre.sh

# QC and PDF
qcplots.sh

# Organize outputs
organize_outputs.sh

