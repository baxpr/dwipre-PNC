#!/bin/bash

function find_zero_bvals {

  bval_file="${1}"

  # Load bvals from file to array
  read -a bvals <<< "$(cat ${bval_file})"

  # Find 0-based index of volumes with b=0
  zinds=()
  for i in "${!bvals[@]}"; do
    if [[ ${bvals[i]} = 0 ]] ; then
      zinds+=($i)
    fi
  done
  echo ${zinds[@]}

}


function pre_normalize_dwi {

  dwi_file="${1}"
  bval_file="${2}"

  echo "Pre-normalize"

  # Find the volumes with b=0	
  read -a zinds <<< "$(find_zero_bvals ${bval_file})"
  echo "Found b=0 volumes in ${dwi_file},${bval_file} at ${zinds[@]}"

  # Extract the b=0 volumes to temporary files
  b0_files=()
  for ind in "${zinds[@]}" ; do
    thisb0_file=$(printf 'tmp_b0_%04d.nii.gz' ${ind})
    b0_files+=("${thisb0_file}")
    fslroi "${dwi_file}" "${thisb0_file}" $ind 1 
  done
  
  # Register all b=0 volumes to the first one
  for b0_file in "${b0_files[@]}" ; do

    # No need to register the first one to itself
    if [[ "${b0_file}" == "${b0_files[0]}" ]] ; then continue; fi

    # FLIRT to register the others
    echo "Registering ${b0_file} to ${b0_files[0]}"
    flirt_opts="-bins 256 -cost corratio -searchrx -15 15 -searchry -15 15 -searchrz -15 15 -dof 6 -interp trilinear"
    flirt -in ${b0_file} -out ${b0_file} -ref ${b0_files[0]} ${flirt_opts1}

  done

  # Average the registered b=0 volumes
  fslmerge -t tmp_b0.nii.gz $(echo "${b0_files[@]}")
  fslmaths tmp_b0.nii.gz -Tmean tmp_b0mean.nii.gz
  
  # Compute brain mask and get mean in-mask intensity
  bet tmp_b0mean.nii.gz tmp_b0brain ${bet_opts}
  brainmean=$(fslstats tmp_b0mean.nii.gz -k tmp_b0brain_mask.nii.gz -M)
  echo "Mean brain intensity: ${brainmean}"
  
  # Apply global scaling to the original DWI, overwriting original
  echo "Applying global scale factor to ${dwi_file}"
  fslmaths "${dwi_file}" -div ${brainmean} -mul 1000 "${dwi_file}" -odt float
  
  # Clean up temp files
  rm -f tmp_b0*.nii.gz
  
}

