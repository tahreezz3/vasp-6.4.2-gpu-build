# ⚙️ VASP 6.4.2 GPU Build Script for Google Colab / Ubuntu

This repository provides a complete bash script (`vasp-setup.sh`) for building **VASP 6.4.2** on **Google Colab** or **Ubuntu** using:

- **NVIDIA HPC SDK 25.3**
- **CUDA 12.8**
- **Intel oneMKL 2025.1**
- **OpenMPI 4.1.5**
- **Target GPU:** NVIDIA T4 (Compute Capability 7.5)

> 🛠️ This setup is **Google Colab-compatible** and intended for research and educational purposes.

---

## 📜 Script Overview

The script performs the following tasks:

1. Install required libraries.
2. Download and install NVIDIA HPC SDK.
3. Configure environment variables.
4. Download and install Intel oneMKL.
5. Extract and configure the VASP source.
6. Generate `makefile.include` with all needed flags and paths.
7. Compile VASP 6.4.2 for GPU with OpenACC and MPI support.

---

## 📥 Requirements

- Ubuntu 20.04+ or Google Colab environment
- Root (sudo) privileges
- `vasp.6.4.2.tgz` source file (must be manually placed in working directory)
- ~15GB free disk space

---

## ✅ How to Use

### Step-by-Step Instructions

1. **Upload the following files to your environment:**

   - `vasp-setup.sh` (this script)
   - `vasp.6.4.2.tgz` (VASP source package – make sure it's present)

2. **Give execution permission:**

   ```bash
   chmod +x vasp-setup.sh
   ```

3. **Run the script:**

   ```bash
   ./vasp-setup.sh
   ```

---

## 🔧 Step-by-Step Breakdown

### 1. Install Dependencies
Updates APT and installs necessary development libraries:
```bash
sudo apt-get update
sudo apt-get install -y libblas-dev liblapack-dev libfftw3-dev liblapack-doc libfftw3-doc
```

### 2. Install NVIDIA HPC SDK (v25.3)
Downloads and extracts the SDK, then installs it silently:
```bash
wget https://developer.download.nvidia.com/hpc-sdk/25.3/nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz
tar xpzf nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz
cd nvhpc_2025_253_Linux_x86_64_cuda_12.8
printf "\n3\n\n" | ./install
```

### 3. Set Environment Variables
Sets `PATH`, `LD_LIBRARY_PATH`, `CPPFLAGS`, etc., for the compiler, CUDA, and MPI:
```bash
export HPC_BASE="/opt/nvidia/hpc_sdk/Linux_x86_64/25.3"
export CUDA_VER="12.8"

export PATH="$HPC_BASE/comm_libs/mpi/bin:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/bin:$HPC_BASE/compilers/bin:$HPC_BASE/compilers/compilers/extras:$PATH"
export LD_LIBRARY_PATH="$HPC_BASE/compilers/extras/qd/lib:$HPC_BASE/cuda/$CUDA_VER/targets/x86_64-linux/lib:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/lib:$LD_LIBRARY_PATH"
export MANPATH="$HPC_BASE/compilers/man:$HPC_BASE/comm_libs/mpi/man:$MANPATH"
export CPPFLAGS="-I$HPC_BASE/cuda/$CUDA_VER/include"
```

### 4. Install Intel oneMKL
Downloads and installs Intel oneMKL silently:
```bash
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/dc93af13-2b3f-40c3-a41b-2bc05a707a80/intel-onemkl-2025.1.0.803.sh
chmod +x intel-onemkl-2025.1.0.803.sh
./intel-onemkl-2025.1.0.803.sh -a -s --eula accept --install-dir /opt/intel
```

### 5. Set MKL Environment Variables
```bash
export MKLROOT="/opt/intel/mkl/2025.1"
export PATH="$MKLROOT/bin:$PATH"
export LD_LIBRARY_PATH="$MKLROOT/lib/intel64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$MKLROOT/lib/intel64:$LIBRARY_PATH"
export CPATH="$MKLROOT/include:$CPATH"
```

### 6. Clean Up
Remove downloaded archives to save space:
```bash
rm -rf nvhpc_2025_253_Linux_x86_64_cuda_12.8*
rm -rf intel-onemkl-2025.1.0.803.sh
```

### 7. Extract VASP Source
```bash
tar xpzf vasp.6.4.2.tgz
```

### 8. Generate makefile.include
A detailed `makefile.include` is created to define compilation settings for NVHPC, CUDA, MKL, NCCL, etc. This is crucial for building VASP correctly on GPU.

### 9. Build VASP
```bash
cd vasp.6.4.2
make all
```

---

## 🛠️ Troubleshooting and Fixes

### ❌ Error: `nvfortran: error #0004: Unable to open MODULE file`
✅ **Fix:**
```bash
mkdir -p vasp.6.4.2/modules
```
And modify `makefile.include` to use:
```make
MODDIR = $(PWD)/vasp.6.4.2/modules
FFLAGS += -module $(MODDIR) -I$(MODDIR)
```

### ❌ Error: `mpif90: command not found`
✅ **Fix:**
```bash
export PATH="/opt/nvidia/hpc_sdk/Linux_x86_64/25.3/comm_libs/12.8/openmpi4/openmpi-4.1.5/bin:$PATH"
```

---

## 📂 File Structure

```text
.
├── vasp-setup.sh             # Main installation and build script
├── vasp.6.4.2.tgz            # VASP source archive (not included)
└── README.md                 # This file
```

---

## 📧 Author

**Tahreezz Murdifin**  
📫 [tahriz716@gmail.com](mailto:tahriz716@gmail.com)

---

## 📄 License

For academic use only. Respect VASP’s license terms: https://www.vasp.at

---

## 🙏 Acknowledgments

- NVIDIA for the HPC SDK
- Intel for MKL
- The VASP team for their scientific contributions

---


## 🤝 Contributing

Feel free to open issues or submit pull requests if you improve this setup.
