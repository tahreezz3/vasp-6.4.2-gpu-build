#!/bin/bash

# ---------------------------
# VASP 6.4.2 GPU Build Installation Script for Google Colab or Ubuntu
# Author: Tahreezz Murdifin tahriz716@gmail.com
# Tested with: NVIDIA HPC SDK 25.3, CUDA 12.8, OpenMPI 4.1.5, Intel MKL 2025.1
# Target GPU: NVIDIA T4 (Compute Capability 7.5)
# Google Colab Compatible
# ---------------------------

# Check if no arguments were provided
if [ $# -eq 0 ]; then
    echo "Cuda compatibility code not provided. Usage: ./vasp-setup.sh --75 #here 75 is cc 7.5"
    exit 1
fi
# Extract the number from the first argument, assuming it's in the format --XX
cuda_cc_number="${1/--/}"
if [[ "$cuda_cc_number" =~ ^[0-9]{2,3}$ ]]; then
    echo "Using CUDA Compute Capability: cc$cuda_cc_number"
else
    echo "Invalid CUDA Compute Capability format. Please provide a 2 or 3-digit number (e.g., --75 or --120)."
    exit 1
fi

set -e  # Exit on any error

echo "==> Step 1: Installing Required Libraries"
sudo apt-get update
sudo apt-get install -y libblas-dev liblapack-dev libfftw3-dev liblapack-doc libfftw3-doc

echo "==> Step 2: Downloading NVIDIA HPC SDK"
wget https://developer.download.nvidia.com/hpc-sdk/25.3/nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz
tar xpzf nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz
cd nvhpc_2025_253_Linux_x86_64_cuda_12.8

echo "==> Step 3: Installing NVIDIA HPC SDK Silently"

printf "\n3\n\n" | ./install

echo "==> Step 4: Setting Up HPC Environment Variables"

HPC_BASE="/opt/nvidia/hpc_sdk/Linux_x86_64/25.3"
CUDA_VER="12.8"
export PATH="$HPC_BASE/comm_libs/mpi/bin:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/bin:$HPC_BASE/compilers/bin:$HPC_BASE/compilers/compilers/extras:$PATH"
export LD_LIBRARY_PATH="$HPC_BASE/compilers/extras/qd/lib:$HPC_BASE/cuda/$CUDA_VER/targets/x86_64-linux/lib:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/lib:$LD_LIBRARY_PATH"
export MANPATH="$HPC_BASE/compilers/man:$HPC_BASE/comm_libs/mpi/man:$MANPATH"
export CPPFLAGS="-I$HPC_BASE/cuda/$CUDA_VER/include"

echo "==> Step 5: Downloading Intel oneMKL"

cd /content || cd ~
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/dc93af13-2b3f-40c3-a41b-2bc05a707a80/intel-onemkl-2025.1.0.803.sh
chmod +x intel-onemkl-2025.1.0.803.sh
./intel-onemkl-2025.1.0.803.sh -a -s --eula accept --install-dir /opt/intel

echo "==> Step 6: Setting Up MKL Environment Variables"

MKLROOT="/opt/intel/mkl/2025.1"
export PATH="$MKLROOT/bin:$PATH"
export LD_LIBRARY_PATH="$MKLROOT/lib/intel64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$MKLROOT/lib/intel64:$LIBRARY_PATH"
export CPATH="$MKLROOT/include:$CPATH"
export MKLROOT="/opt/intel/mkl/2025.1"

echo "==> Cleaning up temporary installation files"

rm -rf nvhpc_2025_253_Linux_x86_64_cuda_12.8*
rm -rf intel-onemkl-2025.1.0.803.sh

echo "==> Step 7: Extracting VASP Source (ensure vasp.6.4.2.tgz exists)"

tar xpzf vasp.6.4.2.tgz

echo "==> Step 8: downloading and editing makefile.include"

cd vasp.6.4.2
wget https://raw.githubusercontent.com/tahreezz3/vasp-6.4.2-gpu-build/main/makefile.include -O makefile.include
MAKEFILE= "makefile.include"
# Use sed to update the CC, FC, and FCL lines in the makefile
sed -i "s/cc\$(cuda_cc-number)/cc$cuda_cc_number/g" $MAKEFILE

echo "==> Step 9: Building VASP"

make all

echo "==> ✅ VASP 6.4.2 Build Complete!"
