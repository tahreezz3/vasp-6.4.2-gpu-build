#!/bin/bash

# ---------------------------
# VASP 6.4.2 GPU Build Installation Script for Google Colab or Ubuntu
# Author: Tahreezz Murdifin tahriz716@gmail.com
# Tested with: NVIDIA HPC SDK 25.3, CUDA 12.8, OpenMPI 4.1.5, Intel MKL 2025.1
# Target GPU: NVIDIA T4 (Compute Capability 7.5)
# Google Colab Compatible
# ---------------------------

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

# Go back to root directory
cd /content || cd ~

echo "==> Step 4: Setting Up HPC Environment Variables"
HPC_BASE="/opt/nvidia/hpc_sdk/Linux_x86_64/25.3"
CUDA_VER="12.8"

export PATH="$HPC_BASE/comm_libs/mpi/bin:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/bin:$HPC_BASE/compilers/bin:$HPC_BASE/compilers/compilers/extras:$PATH"
export LD_LIBRARY_PATH="$HPC_BASE/compilers/extras/qd/lib:$HPC_BASE/cuda/$CUDA_VER/targets/x86_64-linux/lib:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/lib:$LD_LIBRARY_PATH"
export MANPATH="$HPC_BASE/compilers/man:$HPC_BASE/comm_libs/mpi/man:$MANPATH"
export CPPFLAGS="-I$HPC_BASE/cuda/$CUDA_VER/include"

echo "==> Step 5: Downloading Intel oneMKL"
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

echo "==> Step 8: Writing makefile.include"

MAKEFILE="vasp.6.4.2/makefile.include"
if [ ! -f "$MAKEFILE" ]; then
cat <<EOF > $MAKEFILE
# ----------------------------------------
# Precompiler options
CPP_OPTIONS = -DHOST=\"LinuxNV\" \
              -DMPI -DMPI_INPLACE -DMPI_BLOCK=8000 -Duse_collective \
              -DscaLAPACK \
              -DCACHE_SIZE=4000 \
              -Davoidalloc \
              -Dvasp6 \
              -Dtbdyn \
              -Dqd_emulate \
              -Dfock_dblbuf \
              -D_OPENMP \
              -D_OPENACC \
              -DUSENCCL \
              -DUSENCCLP2P

CPP         = nvfortran -Mpreprocess -Mfree -Mextend -E $(CPP_OPTIONS) $*$(FUFFIX) > $*$(SUFFIX)

# ----------------------------------------
# Compiler setup
CC          = mpicc  -acc -gpu=cc75,cuda12.8 -mp
FC          = mpif90 -acc -gpu=cc75,cuda12.8 -mp
FCL         = mpif90 -acc -gpu=cc75,cuda12.8 -mp -c++libs

FREE        = -Mfree
FFLAGS      = -Mbackslash -Mlarge_arrays -tp=host
OFLAG       = -fast
DEBUG       = -Mfree -O0 -traceback
OBJECTS     = fftmpiw.o fftmpi_map.o fftw3d.o fft3dlib.o

# ----------------------------------------
# NVHPC SDK paths
NVROOT      = $(shell which nvfortran | awk -F /compilers/bin/nvfortran '{ print $$1 }')

# ----------------------------------------
# Quad precision library
QD          ?= $(NVROOT)/compilers/extras/qd
LLIBS       = -cudalib=cublas,cusolver,cufft,nccl -cuda
LLIBS      += -L$(QD)/lib -lqdmod -lqd
INCS       += -I$(QD)/include/qd

# ----------------------------------------
# MKL setup
MKLROOT     = /opt/intel/mkl/2025.1
LLIBS      += -Mmkl -L$(MKLROOT)/lib/intel64 -lmkl_scalapack_lp64 -lmkl_blacs_openmpi_lp64
INCS       += -I$(MKLROOT)/include/fftw

# ----------------------------------------
# NCCL setup
NCCLROOT    = /opt/nvidia/hpc_sdk/Linux_x86_64/25.3/comm_libs/nccl
LLIBS      += -L$(NCCLROOT)/lib -lnccl
INCS       += -I$(NCCLROOT)/include

# ----------------------------------------
# Source object overrides
SOURCE_O1   := pade_fit.o minimax_dependence.o wave_window.o
SOURCE_O2   := pead.o

# For vasp.5.lib
CPP_LIB     = $(CPP)
FC_LIB      = $(FC)
CC_LIB      = $(CC)
CFLAGS_LIB  = -O -w
FFLAGS_LIB  = -O1 -Mfixed
FREE_LIB    = $(FREE)
OBJECTS_LIB = linpack_double.o

# Parser library
CXX_PARS    = nvc++ --no_warnings

# Improves performance for newer NVHPC
OFLAG_IN   = -fast -Mwarperf
SOURCE_IN  := nonlr.o

# -----------------------------------------
# Error solution of- [NVFORTRAN-F-0004-Unable to open MODULE file]  

#vpath %.F90 build/ncl build/gam build/std
#vpath %.f90 build/ncl build/gam build/std
#vpath %.F   build/ncl build/gam build/std

#manually make dir or using code for once /vasp.6.4.2/global_modules
#WORKDIR="$(pwd)"
#MODDIR = "${WORKDIR}/vasp.6.4.2/modules"
#FFLAGS += -module $(MODDIR) -I$(MODDIR)
# ------------------------------------------
EOF

echo "==> Step 9: Building VASP"
cd vasp.6.4.2
make all

echo "==> ✅ VASP 6.4.2 Build Complete!"
