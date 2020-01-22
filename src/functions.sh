#!/bin/bash

# Load bvals from file to array
bval_file=DTI_2x32_35.bval
read -a bvals <<< "$(cat ${bval_file})"

# Find 0-based index of volumes with b=0
zinds=()
for i in "${!bvals[@]}"; do
  if [[ ${bvals[i]} = 0 ]] ; then
    zinds+=($i)
  fi
done
echo "Found b=0 in ${bval_file} at ${zinds[@]}"

