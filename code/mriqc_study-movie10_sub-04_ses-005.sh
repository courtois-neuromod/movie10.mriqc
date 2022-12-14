#!/bin/bash
#SBATCH --account=rrg-pbellec
#SBATCH --job-name=mriqc_study-movie10_sub-04_ses-005.job
#SBATCH --output=./code/mriqc_study-movie10_sub-04_ses-005.out
#SBATCH --error=./code/mriqc_study-movie10_sub-04_ses-005.err
#SBATCH --time=8:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=4G
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=basile.pinsard@gmail.com



export LOCAL_DATASET=$SLURM_TMPDIR/${SLURM_JOB_NAME//-/}/
flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.movie10.mriqc/.datalad_lock datalad clone ria+file:///lustre03/project/rrg-pbellec/ria-beluga#~cneuromod.movie10.mriqc@main $LOCAL_DATASET
cd $LOCAL_DATASET
datalad get -s ria-beluga-storage -J 4 -n -r -R1 . # get sourcedata/* containers
if [ -d sourcedata/smriprep ] ; then
    datalad get -n sourcedata/smriprep sourcedata/smriprep/sourcedata/freesurfer
fi
git submodule foreach --recursive git annex dead here
git submodule foreach git annex enableremote ria-beluga-storage
git checkout -b $SLURM_JOB_NAME

datalad containers-run -m 'mriqc_sub-04/ses-005' -n containers/bids-mriqc --input sourcedata/movie10/sub-04/ses-005/fmap/ --input sourcedata/movie10/sub-04/ses-005/func/ --output . -- -w workdir/ --participant-label 04 --session-id 005 --omp-nthreads 8 --nprocs 8 -m bold --mem_gb 32 --no-sub sourcedata/movie10 ./ participant 
mriqc_exitcode=$?

flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.movie10.mriqc/.datalad_lock datalad push -d ./ --to origin
if [ -d sourcedata/freesurfer ] ; then
    flock --verbose /lustre03/project/rrg-pbellec/ria-beluga/alias/cneuromod.movie10.mriqc/.datalad_lock datalad push -J 4 -d sourcedata/freesurfer $LOCAL_DATASET --to origin
fi 
exit $mriqc_exitcode 
