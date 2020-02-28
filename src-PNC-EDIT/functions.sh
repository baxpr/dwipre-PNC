#!/bin/bash

function get_nifti_geom {
  
  nii_file="${1}"
  
  vals=
  for field in dim1 dim2 dim3 sform_xorient sform_yorient sform_zorient ; do
    val=$(fslval "${nii_file}" $field)
    vals="${vals} ${val}"
  done
  vals="${vals} $(fslorient -getsform ${nii_file})"
  
  echo "${vals}"

}


function find_zero_bvals {

  bval_file="${1}"  # Input bval file

  # Load bvals from file to array
  read -a bvals <<< "$(cat ${bval_file})"

  # Find 0-based index of volumes with b=0
  zinds=()
  for i in "${!bvals[@]}"; do
    if (( $(echo "${bvals[i]} == 0" |bc -l) )) ; then
      zinds+=($i)
    fi
  done

  echo ${zinds[@]}

}


function get_mask_from_b0 {

  dwi_file="${1}"       # Input DWI file
  bval_file="${2}"      # Matching bvals
  out_pfx="${3}"        # Prefix for outputs
                        #    ${out_pfx}.nii.gz        Masked mean b=0
                        #    ${out_pfx}_mean.nii.gz   Mean b=0
                        #    ${out_pfx}_mask.nii.gz   Brain mask
  
  # Find the volumes with b=0. FSL and bash both use 0-based indexing
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

    # FLIRT to register the others, overwriting the input image each time
    echo "Registering ${b0_file} to ${b0_files[0]}"
    flirt_opts="-bins 256 -cost corratio -searchrx -45 45 -searchry -45 45 -searchrz -45 45 -dof 6 -interp trilinear"
    flirt -in ${b0_file} -out ${b0_file} -ref ${b0_files[0]} ${flirt_opts}

  done

  # Average the registered b=0 volumes
  echo "Averaging b=0 images"
  fslmerge -t tmp_b0.nii.gz $(echo "${b0_files[@]}")
  fslmaths tmp_b0.nii.gz -Tmean "${out_pfx}_mean.nii.gz"
  
  # Compute brain mask
  echo "BET options -n -m ${bet_opts}"
  bet "${out_pfx}_mean.nii.gz" "${out_pfx}" -n -m ${bet_opts}

  # Clean up temp files
  rm -f ${b0_files[@]} tmp_b0.nii.gz
  
}


function pre_normalize_dwi {

  dwi_file="${1}"    # Input DWI image (will be overwritten with result)
  bval_file="${2}"   # Matching bvals

  echo "Pre-normalize ${dwi_file}"

  # Get the brain mask from average b=0 image
  get_mask_from_b0 "${dwi_file}" "${bval_file}" tmp_b0

  # Get mean in-mask intensity
  brainmean=$(fslstats tmp_b0_mean.nii.gz -k tmp_b0_mask.nii.gz -M)
  echo "Mean brain intensity: ${brainmean}"
  
  # Apply global scaling to the original DWI, overwriting original
  echo "Applying global scale factor to ${dwi_file}"
  fslmaths "${dwi_file}" -div ${brainmean} -mul 1000 "${dwi_file}" -odt float
  
  # Clean up temp files
  rm -f tmp_b0*.nii.gz
  
}


