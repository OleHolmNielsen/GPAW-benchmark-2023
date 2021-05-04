#!/bin/bash
#SBATCH --job-name=MoS2-benchmark
#SBATCH --mail-type=START,END
#SBATCH --partition=xeon40_clx
#SBATCH --output=%x-%j.out
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --cpus-per-task=1
#SBATCH --mem=350G

# This is a Slurm batch job script for the MoS2-benchmark.py benchmark.
# It is assumed that a GPAW software module can be loaded.

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

mpiexec gpaw info
module list
printenv|grep SLURM

# Run 1 thread per task
export OMP_NUM_THREADS=1

echo Running GPAW with $SLURM_NTASKS tasks.
mpiexec gpaw -P $SLURM_NTASKS python MoS2-benchmark.py

echo Extract numbers for correctness and timing
grep Free MoS2-benchmark.txt
grep Total: MoS2-benchmark.txt
