#!/bin/bash

# Parse options
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    --project)
        export project="$2"
        shift; shift
        ;;
    --subject)
        export subject="$2"
        shift; shift
        ;;
    --session)
        export session="$2"
        shift; shift
        ;;
    --outdir)
        export outdir="$2"
        shift; shift
        ;;
    *)
        shift
        ;;
  esac
done

# Inputs report
echo "${project} ${subject} ${session} ${scan}"
echo "outdir: $outdir"

# Set up working directory and copy/rename inputs

# Run eddy pipeline

