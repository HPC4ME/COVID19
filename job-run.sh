#!/bin/bash
#SBATCH --job-name=protein-ligand
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

#SBATCH --account=e793-training

#SBATCH --partition=standard
#SBATCH --qos=standard

# Load the GROMACS module (meaning we can run GROMACS commands)

module load gromacs/2022.4

# Define the number of threads to use for the simulation (required for parallel simulations)

export OMP_NUM_THREADS=1

# Define the mpro/drug combination structure file that you are using for this simulation:

structure=

# Run our simulations

for i in {1..8}; do
(
  mkdir run$i
  cd ./run$i

  mkdir EM$i
  cd ./EM$i

  gmx grompp -f ../../mdp-files/em.mdp -c ../../$structure -r ../../$structure -p ../../topol.top -o em.tpr  -maxwarn 5
  srun --nodes=1 --ntasks=16 --cpus-per-task=1 --exact --mem=24000M gmx_mpi mdrun -s em.tpr -c mpro-em.gro

  cd ../../
)&
done

wait

for i in {1..8}; do
(
  cd ./run$i
  mkdir NVT$i
  cd ./NVT$i

  gmx grompp -f ../../mdp-files/nvt.mdp -c ../EM$i/mpro-em.gro -r ../EM$i/mpro-em.gro -p ../../topol.top -o nvt.tpr -maxwarn 5
  srun --nodes=1 --ntasks=16 --cpus-per-task=1 --exact --mem=24000M gmx_mpi mdrun -s nvt.tpr -c mpro-nvt.gro

  cd ../../
)&
done

wait

for i in {1..8}; do
(
  cd ./run$i
  mkdir NPT$i
  cd ./NPT$i

  gmx grompp -f ../../mdp-files/npt.mdp -c ../NVT$i/mpro-nvt.gro -r ../NVT$i/mpro-nvt.gro -p ../../topol.top -o npt.tpr -maxwarn 5
  srun --nodes=1 --ntasks=16 --cpus-per-task=1 --exact --mem=24000M gmx_mpi mdrun -s npt.tpr -c mpro-npt.gro

  cd ../../
)&
done

wait

for i in {1..8}; do
(
  cd ./run$i
  mkdir MD$i
  cd ./MD$i

  gmx grompp -f ../../mdp-files/md.mdp -c ../NPT$i/mpro-npt.gro -r ../NPT$i/mpro-npt.gro -p ../../topol.top -o md$i.tpr -maxwarn 5
  srun --nodes=1 --ntasks=16 --cpus-per-task=1 --exact --mem=24000M gmx_mpi mdrun -s md$i.tpr -c done-$structure &

  cd ../../
)&
done

wait
