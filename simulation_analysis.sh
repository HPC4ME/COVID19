#!/bin/bash 

# Load GROMACS module

module load gromacs/2022.4

# RUN RMSD ANALYSIS

#make the required directory
mkdir analysis

# RUN SYSTEM CHECKS

mkdir ./analysis/energy
mkdir ./analysis/temperature
mkdir ./analysis/pressure

for i in {1..8}; do

echo -e "14 0 \n q" | gmx energy -f ./run$i/MD$i/*.edr -o ./analysis/energy/energy$i.xvg
echo -e "16 0 \n q" | gmx energy -f ./run$i/MD$i/*.edr -o ./analysis/temperature/temperature$i.xvg
echo -e "18 0 \n q" | gmx energy -f ./run$i/MD$i/*.edr -o ./analysis/pressure/pressure$i.xvg

done

# MAKE DATA FOR FMO ANALYSIS

#Make index files

mkdir ./analysis/fmo

for i in {1..8}; do

echo -e "1 | 13 \n q" | gmx make_ndx -f ./run$i/MD$i/*.gro -o ./run$i/MD$i/protein_ligand$i.ndx

done

#Generate the pose pdb files

for i in {1..8}; do

mkdir ./analysis/fmo/run$i

for n in $(seq 0 8000 40000); do

echo -e "20 \n q" | gmx trjconv -f ./run$i/MD$i/*.xtc -s ./run$i/MD$i/*.gro -n ./run$i/MD$i/protein_ligand$i.ndx -dump $n -o ./analysis/fmo/run$i/final_pose_time$n.pdb

done

done

# RMSD ANALYSIS

#Generate the RMSD files

for i in {1..8}; do

echo -e "13 13" | gmx rms -s ./run$i/MD$i/*.tpr -f ./run$i/MD$i/*.xtc -o ./analysis/rmsd_run$i.xvg

done

#Run RMSD average calculation

cd ./analysis

output_file="average_ligand_movement.txt"
> $output_file  # Clear the file if it exists

sum=0
count=0

for i in {1..8}; do
    file="rmsd_run${i}.xvg"

    if [[ -f "$file" ]]; then
        avg=$(awk '$1 !~ /^[@#]/ {sum += $2; count++} END {if (count > 0) print sum/count; else print "0"}' "$file")
        sum=$(echo "$sum + $avg" | bc -l)
        count=$((count + 1))
    else
        echo "Warning: File $file not found, skipping."
    fi
done

#Compute the final average
if [[ $count -gt 0 ]]; then
    total_avg=$(echo "$sum / $count" | bc -l)
        echo "The total average movement of your ligands across all ensembles is $total_avg nm" > "$output_file"
    echo "Average ligand movement saved to $output_file"
    cat $output_file
else
    echo "No valid files found!"
fi

cd ../
