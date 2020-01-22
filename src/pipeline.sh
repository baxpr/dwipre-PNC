#!/bin/bash

# Parse options
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    --dti35_niigz)
        export dti35_niigz="$2"
        shift; shift ;;
    --dti35_bval)
        export dti35_bval="$2"
        shift; shift ;;
    --dti35_bvec)
        export dti35_bvec="$2"
        shift; shift ;;
    --dti36_niigz)
        export dti36_niigz="$2"
        shift; shift ;;
    --dti36_bval)
        export dti36_bval="$2"
        shift; shift ;;
    --dti36_bvec)
        export dti36_bvec="$2"
        shift; shift ;;
    --project)
        export project="$2"
        shift; shift ;;
    --subject)
        export subject="$2"
        shift; shift ;;
    --session)
        export session="$2"
        shift; shift ;;
    --outdir)
        export outdir="$2"
        shift; shift ;;
    *)
        echo "Unknown option ${1} - ignoring"
        shift ;;
  esac
done

# Inputs report
echo "${project} ${subject} ${session}"
echo "    ${dti35_niigz}"
echo "    ${dti35_bval}"
echo "    ${dti35_bvec}"
echo "    ${dti36_niigz}"
echo "    ${dti36_bval}"
echo "    ${dti36_bvec}"
echo "outdir: $outdir"

# Run eddy pipeline
dwipre.sh

# Organize outputs
organize_outputs.sh

