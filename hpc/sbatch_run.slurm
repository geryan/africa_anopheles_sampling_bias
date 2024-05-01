#!/bin/bash
# Created by the University of Melbourne job script generator for SLURM
# Tue Apr 30 2024 16:05:22 GMT+1000 (Australian Eastern Standard Time)

# Partition for the job:
#SBATCH --partition=cascade

# Multithreaded (SMP) job: must run on one node
#SBATCH --nodes=1

# The name of the job:
#SBATCH --job-name="travel_time"

# The project ID which this job should run under:
#SBATCH --account="punim0995"

# Maximum number of tasks/CPU cores used by the job:
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

# The amount of memory in megabytes per node:
#SBATCH --mem=262144
## #SBATCH --mem=16384

# Use this email address:
#SBATCH --mail-user=ryange@unimelb.edu.au

# The maximum running time of the job in days-hours:mins:sec
#SBATCH --time=0-1:0:00

# check that the script is launched with sbatch
if [ "x$SLURM_JOB_ID" == "x" ]; then
   echo "You need to submit your job to the queuing system with sbatch"
   exit 1
fi

# Run the job from your home directory:
cd $HOME

# The modules to load:
module load R/4.3.2
module load rgdal/1.6.6
module load CMake/3.24.3

# The job command(s):
cd /home/ryange/africa_anopheles_sampling_bias

Rscript --vanilla run.R

##DO NOT ADD/EDIT BEYOND THIS LINE##
##Job monitor command to list the resource usage
my-job-stats -a -n -s
