#!/usr/bin/env bash
#
# This script installs miniconda, and configures a
# python environment with all of the dependencies
# required by FSL. This involves:
#
#  1. Downloading the miniconda install script from https://repo.continuum.io
#
#  2. Installing miniconda to $FSLDIR/fslpython/
#
#  3. Creating a miniconda environment called 'fslpython', with all of the
#     packages listed in fslpython_environment.yml (this file is assumed
#     to be present in the same location as this script).
#
#  4. Creating a symlink from the fslpython environment binary to
#     $FSLDIR/bin/fslpython.
#
# Call with -f <FSLDIR path>, e.g. /usr/local/fsl (with use FSLDIR if given
# no arguments)

# Where is this script?
set -o pipefail
script_dir=$( cd $(dirname $0) ; pwd)

# Set some defaults
OPTIND=1
fsl_dir=""


#####################################
# Download miniconda installer script
#####################################

fsl_dir="/usr/local/fsl-6.0.2"
mkdir ${fsl_dir}
platform=`uname -s`
miniconda_url="https://repo.continuum.io/miniconda"
miniconda_tmp=`mktemp -d -t fslpythonXXXX`
miniconda_installer="${miniconda_tmp}/fslpython_miniconda_installer.sh"
miniconda_root_dir="${fsl_dir}/fslpython"
miniconda_bin_dir="${miniconda_root_dir}/bin"
fslpython_env_dir="${miniconda_root_dir}/envs/fslpython/"
miniconda_script="Miniconda3-latest-Linux-x86_64.sh"

echo "Downloading to ${miniconda_tmp}"
wget -O "${miniconda_installer}" --quiet ${miniconda_url}/${miniconda_script}


###################
# Install miniconda
###################
/usr/bin/env bash ${miniconda_installer} -b -p "${miniconda_root_dir}"
rm "${miniconda_installer}"

"${miniconda_bin_dir}/conda"  config --file "${miniconda_root_dir}"/.condarc --set safety_checks warn
"${miniconda_bin_dir}/conda"  config --file "${miniconda_root_dir}"/.condarc --set remote_read_timeout_secs 240
"${miniconda_bin_dir}/conda"  config --file "${miniconda_root_dir}"/.condarc --set remote_connect_timeout_secs 20
"${miniconda_bin_dir}/conda"  config --file "${miniconda_root_dir}"/.condarc --set remote_max_retries 10


##############################
# Create fslpython environment
##############################
FSLDIR=$fsl_dir "${miniconda_bin_dir}/conda" env create \
    -f "${script_dir}/fslpython_environment.yml" 

