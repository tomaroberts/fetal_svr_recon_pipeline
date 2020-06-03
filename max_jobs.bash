# Function from Max: 
# - prevents simultaneous reconstruction of too many datasets, to lessen chance of crashes
# - allows reconstruction command to be run via SSH on a remote machine

#!/bin/bash -e

while true; do
	for lockfile in /tmp/recon_loc1 /tmp/recon_loc2; do
		#trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT KILL
		if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; 
		then
			trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT KILL
			
			
			# New SVRTK version (06_2020)
			/projects/perinatal/peridata/fetalsvr/software/MIRTK_recon/build/lib/tools/reconstruct $@

			# Old version (uses IRTK: reconstruction function)
			# echo $PATH
			# reconstruction $@ # $@ --- the argument of the function
			# eval reconstruction $@
			
			# reconstruction ../outputSVRvolume.nii.gz \
							# $numStacks \
							# ${arrStackNames[*]} \
							# -mask ../$maskName \
							# -packages ${arrPackages[*]} \
							# -thickness ${arrSliceThickness[*]} \
							# -iterations $numIterations

			echo "Reconstruction complete within max_jobs.bash ... "
	 
		   rm -f "$lockfile"
		   trap - INT TERM EXIT
		   exit
		else
		   echo "Failed to acquire lockfile: $lockfile, held by job $(cat $lockfile)"
		   continue
		fi
	done
	echo 'Waiting for reconstructions to finish...'
	sleep 10
done
