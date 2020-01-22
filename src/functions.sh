#!/bin/bash

function find_zero_bvals {

  # Load bvals from file to array
  bval_file="${1}"
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

read -a zinds <<< "$(find_zero_bvals DTI_2x32_36.bval)"

