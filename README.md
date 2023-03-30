# GPAW-benchmark-2023

GPAW code building instructions and benchmark data
--------------------------------------------------

The purpose of this page is to document the building of the [GPAW](https://wiki.fysik.dtu.dk/gpaw/) code release version 22.08.0.
Subsequently a GPAW test and a GPAW benchmark run on a single compute node is documented.

The benchmarks are designed to reflect our HPC software environment,
and to run some representative physics problems using the GPAW code.

The prerequisite operating system is AlmaLinux 8.7 or RockyLinux 8.7
(denoted as [EL8](https://en.wikipedia.org/wiki/Red_Hat_Enterprise_Linux),
or compatible, for example Red Hat RHEL 8 Update 7) or newer.

We require using the [EasyBuild](https://github.com/hpcugent/easybuild)
software build and installation framework that allows you to manage
(scientific) software on High Performance Computing (HPC) systems in an efficient way.
The present instructions are based upon EasyBuild version 4.7.1.

In order to have a well-defined and reproducible software modules framework 
for the purpose of comparing benchmark results obtained on different systems,
we require the use of specific software module [toolchains](https://docs.easybuild.io/common-toolchains/)
provided by EasyBuild version 4.7.1.

EasyBuild contains newer toolchains (such as 2022b) in addition to the ones used in the present instruction,
but the versions specified in this document must nevertheless be used in order to make a working benchmark.
The reason is that dependencies such as *SciPy* are not yet available in the ``intel-2022b`` toolchain,
and that the GPAW self-test fails with the ``foss-2022b`` toolchain.

The benchmark requires to build the GPAW code using both of the following 
EasyBuild software module toolchains:

1. intel-2022a: icc, ifort, imkl, impi

2. foss-2022a: BLACS, FFTW, GCC, OpenBLAS, OpenMPI, ScaLAPACK

The foss toolchain uses only Open Source software,
whereas the intel toolchain requires licensed Intel C and Fortran compilers 
as well as the Intel MKL and MPI libraries.
For systems with processors that include AVX-512 vector support,
it is anticipated that the MKL library may offer a better performance.

Step 1: Installing Lmod
-----------------------

A software modules tool is a prerequisite, and the recommended tool is
[Lmod](https://www.tacc.utexas.edu/research-development/tacc-projects/lmod).

Brief Lmod installation instructions for EL8 may be found in
https://wiki.fysik.dtu.dk/niflheim/EasyBuild_modules#install-lmod.
The root superuser may install the Lmod RPM by:

```
$ dnf install epel-release
$ dnf install Lmod
```

whereas a non-root user can install Lmod as documented in [Installing Lmod without root permissions](https://docs.easybuild.io/installing-lmod-without-root-permissions/)

Step 2: Installing EasyBuild
----------------------------

EasyBuild must be installed as a normal user, however,
EasyBuild and certain software modules need some prerequisite OS packages to be installed by the superuser:

```
$ dnf install tar gzip bzip2 unzip xz patch python3-setuptools gcc-c++ python3
$ dnf install libibverbs-devel rdma-core-devel
```

NOTICE: EasyBuild by default builds binary application codes which are optimized 
for the host/node CPU architecture.  Therefore all software must be built on the 
same type of CPU architecture that the software will eventually run on.
If you build software on an older CPU architecture, the code will only use CPU instructions
available on the old CPU architecture, and hence potentially be much slower 
than it should be!

The CPU architecture may be printed using the command:
```
gcc -march=native -Q --help=target | grep '^  -march'
```
This information is only available with the GCC compiler version 4.9 and newer.
Also the ```lscpu``` command will reveal information about the type of CPU.

Brief EasyBuild installation instructions for EL8 may be found in
https://wiki.fysik.dtu.dk/niflheim/EasyBuild_modules.
There is an official [EasyBuild Installation](https://docs.easybuild.io/installation/)
guide with detailed instructions.
The following is a summary:

1. Define the top-level directory and modules tool for your modules,
   for example, you could create a ``/scratch/easybuild`` folder on the node's local hard disk:
```
export EASYBUILD_PREFIX=/scratch/easybuild
mkdir $EASYBUILD_PREFIX
export EASYBUILD_MODULES_TOOL=Lmod
```

2. Install EasyBuild, update paths, and verify the ``eb`` command as explained in the instructions:
```
pip3 install --prefix $EASYBUILD_PREFIX easybuild
export PATH=$EASYBUILD_PREFIX/bin:$PATH
export PYTHONPATH=$EASYBUILD_PREFIX/lib/python3.6/site-packages:$PYTHONPATH
module use $EASYBUILD_PREFIX/modules/all
eb --version
```
   The EasyBuild version must be 4.7.1 or newer.

Step 3: Build the foss-2022a toolchain
--------------------------------------

EasyBuild version 4.7.1 (and newer) contains the foss-2022a toolchain which is used to build GPAW.
The foss toolchain contains the following modules:

```
BLACS, FFTW, GCC, OpenBLAS, OpenMPI, ScaLAPACK
```

To build the foss-2022a toolchain run this command:

```
eb foss-2022a.eb -r
```

The building of GCC, OpenMPI and FFTW will be particularly time consuming,
and this task may take a number of hours (especially for the ``FFTW`` module)!

Now the foss toolchain modules can be loaded:

```
$ module load foss/2022a
$ module list

Currently Loaded Modules:
  1) GCCcore/11.3.0                    13) libfabric/1.15.1-GCCcore-11.3.0
  2) zlib/1.2.12-GCCcore-11.3.0        14) PMIx/4.1.2-GCCcore-11.3.0
  3) binutils/2.38-GCCcore-11.3.0      15) UCC/1.0.0-GCCcore-11.3.0
  4) GCC/11.3.0                        16) OpenMPI/4.1.4-GCC-11.3.0
  5) numactl/2.0.14-GCCcore-11.3.0     17) OpenBLAS/0.3.20-GCC-11.3.0
  6) XZ/5.2.5-GCCcore-11.3.0           18) FlexiBLAS/3.2.0-GCC-11.3.0
  7) libxml2/2.9.13-GCCcore-11.3.0     19) FFTW/3.3.10-GCC-11.3.0
  8) libpciaccess/0.16-GCCcore-11.3.0  20) gompi/2022a
  9) hwloc/2.7.1-GCCcore-11.3.0        21) FFTW.MPI/3.3.10-gompi-2022a
 10) OpenSSL/1.1                       22) ScaLAPACK/2.2.0-gompi-2022a-fb
 11) libevent/2.1.12-GCCcore-11.3.0    23) foss/2022a
 12) UCX/1.12.1-GCCcore-11.3.0
```

Step 4: Build the intel-2022a toolchain
---------------------------------------

EasyBuild version 4.7.1 (and later) contains the intel-2022a toolchain which is used to build GPAW.
The intel toolchain contains the following modules with software offered by Intel:

```
icc, ifort, imkl, impi
```
You may specify your Intel *license-server* host port 28518 (for example) or just the license file path:
```
export INTEL_LICENSE_FILE=28518@<license-server>
export INTEL_LICENSE_FILE=<file-path>
```

Then run this command to build the intel toolchain, accepting the *Intel-oneAPI* EULA:
```
eb intel-2022a.eb -r --accept-eula-for=Intel-oneAPI
```

Now the intel toolchain modules can be loaded:
```
$ module load intel/2022a
$ module list

Currently Loaded Modules:
  1) GCCcore/11.3.0                  7) impi/2021.6.0-intel-compilers-2022.1.0
  2) zlib/1.2.12-GCCcore-11.3.0      8) imkl/2022.1.0
  3) binutils/2.38-GCCcore-11.3.0    9) iimpi/2022a
  4) intel-compilers/2022.1.0       10) imkl-FFTW/2022.1.0-iimpi-2022a
  5) numactl/2.0.14-GCCcore-11.3.0  11) intel/2022a
  6) UCX/1.12.1-GCCcore-11.3.0
```

Build GPAW using the foss-2022a and intel-2022a toolchains
------------------------------------------------------------

The GPAW release version 22.08.0 is part of the EasyBuild official releases.

Build the GPAW, GPAW-setups and ASE software modules plus all prerequisites with foss-2022a by:
```
eb GPAW-22.8.0-foss-2022a.eb -r
```

Note: If download fails of the source file ```libxc-5.2.3.tar.gz``` from the unstable site *tddft.org*, 
it can alternatively be downloaded from
https://gitlab.com/libxc/libxc/-/archive/5.2.3/libxc-5.2.3.tar.gz
and copied to ```$EASYBUILD_PREFIX/sources/l/libxc/```.

Then build the GPAW, GPAW-setups and ASE software modules plus all prerequisites with intel-2022a by:
```
eb GPAW-22.8.0-intel-2022a.eb -r
```

A patch is required for the GPAW verification tests,
so it is actually necessary to rebuild GPAW from this *Pull Request*
before proceeding to the GPAW tests:
```
eb --rebuild --from-pr=17618
```

Run GPAW verification tests
---------------------------

The GPAW verification tests are described in https://wiki.fysik.dtu.dk/gpaw/install.html#run-the-tests

Execute both of the GPAW modules as built in the above, one after the other:
```
1: module load GPAW/22.8.0-foss-2022a
2: module load GPAW/22.8.0-intel-2022a
module list
```

Now you can clone the present repository:
```
git clone https://github.com/OleHolmNielsen/GPAW-benchmark-2023
cd GPAW-benchmark-2023
```
and run the verification tests 
as shown in https://wiki.fysik.dtu.dk/gpaw/devel/testing.html with 8 single-threaded MPI tasks by:

```
export OMP_NUM_THREADS=1 
mpiexec -n 8 pytest --exitfirst -c pytest.ini -v --pyargs gpaw --color=no
```
The number of tasks must be one of 1, 2, 4 or 8.

The script [gpaw_test.sh](gpaw_test.sh/) may be used to run the GPAW verification tests.

Warning messages and “SKIPPED” tests in the test suite output are accepted, but FAILED tests are not acceptable and must be corrected.
An example output file is [gpaw-test-intel-2022a.txt](gpaw-test-intel-2022a.txt/).

Run the GPAW benchmarks
-----------------------

The GPAW benchmarks must be executed on a single compute node, 
using all CPU cores available in the system.

The subdirectory [benchmarks](benchmarks/) contains the Python scripts,
batch job shell scripts, and any further input files.
The shell scripts are configured for the [Slurm](https://slurm.schedmd.com/overview.html)
resource manager and may be adopted for other systems easily, or even run interactively.

The batch jobs script files in [benchmarks](benchmarks/) are:
```
Benchmark 1: MoS2-benchmark.sh
Benchmark 2: Ru2Cl6-benchmark.sh
```

Execute the benchmarks with both of the GPAW modules (foss-2022a and intel-2022a)
as built in the above, one after the other.
The GPAW module with either intel or foss toolchain must be uncommented in the scripts:

```
# Select ONE of these modules:
module load GPAW/22.8.0-foss-2022a
# module load GPAW/22.8.0-intel-2022a
```

The script must then be executed interactively or submitted to a batch queue.
Scripts must be run in the [benchmarks](benchmarks/) directory because the
Python and json input files are required.

The RAM memory requirement is especially high for the MoS2-benchmark.sh script,
and a minimum of 256 GB system RAM memory may be needed, depending on the number of CPU cores used.

After completing the benchmarks, results have been written to the output files :
```
Benchmark 1: MoS2-benchmark.txt
Benchmark 2: Ru2Cl6-benchmark.txt
```

Verification of correctness
---------------------------

In order to verify that the benchmark calculations have produced correct results,
numerical values in the sample output files should be compared to the reference output files.
Here the [meld](https://meldmerge.org/) visual diff and merge tool can be very useful.
The [meld](https://meldmerge.org/) RPM package is available from the
[EPEL](https://fedoraproject.org/wiki/EPEL) repository and can be installed by:
```
$ dnf install meld
```

To quickly verify the results, a few numbers from the output files may be extracted as follows:

Benchmark 1:
```
$ grep Free MoS2-benchmark.txt
Free energy:   -1287.277410
```

Benchmark 2:
```
$ grep Free Ru2Cl6-benchmark.txt
Free energy:    -28.476802
```

It is expected that the mentioned numbers should vary only in the last digit by a small amount.

Recording of timings
--------------------

The GPAW code records the elapsed wall-clock time and prints it at the end of
the output files, for example:
```
$ grep Total: MoS2-benchmark.txt
Total:                                      4050.393 100.0%
$ grep Total: Ru2Cl6-benchmark.txt 
Total:                                       877.165 100.0%
```

These ```Total:``` timings for Benchmarks 1 and 2, executed with both the foss-2022a and intel-2022a toolchains,
must be collected and rounded down to the nearest integer.
The complete output files must also be collected and submitted.
