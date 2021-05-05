#!/bin/bash
#SBATCH --job-name=gpaw-test
#SBATCH --mail-type=START,END
#SBATCH --partition=xeon40_clx
#SBATCH --output=%x-%j.out
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --cpus-per-task=1
#SBATCH --mem=50G

# This is a Slurm batch job script for the Ru2Cl6-benchmark.py benchmark.
# It is assumed that a GPAW 1.4 software module can be loaded.

echo Hostname: `hostname`
echo CPU type:
lscpu
echo NUMA nodes:
numactl --hardware

module purge
echo
echo module load GPAW
# Select ONE of these modules:
# module load GPAW/21.1.0-foss-2020b-ASE-3.21.1
module load GPAW/21.1.0-intel-2020b-ASE-3.21.1

# module load GPAW
mpiexec gpaw info
module list
printenv | grep SLURM

# Run 1 thread per task
export OMP_NUM_THREADS=1

# The number of tasks must be 1, 2, 4 or 8.
echo Running GPAW tests with 8 tasks.
mpiexec -n 8 pytest -c pytest.ini -v --pyargs gpaw --color=no
