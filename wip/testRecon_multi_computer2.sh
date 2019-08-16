#!/bin/bash -e

### autoReconstruct.sh
#
# Wrapper script for reconstruction function in the SVR toolbox
#
# - USAGE: 
# - Run autoReconstruct.sh in patient folder
#
# - Collates all the information from previously run scripts
# - Feeds this information into reconstruction function within SVR toolbox
# - Option to omit certain stacks from the SVR reconstruction process
#
# --- NB: currently hard-coded to do 3 iterations, 0.75mm resolution
#
# - UPDATES:
# - 11/07/2018 
# - Added option to specify template stack
# - String supplied to reconstruction function always begins with template stack
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
#####################################################################################

### Check load on various machines
hosts=(gpubeastie01-pc beastie01 beastie02)
wdirs=($HOME /scratch /scratch)

# check SSH installed, if not install one
haskey=`ls -al ~/.ssh/id_rsa`
while [ -z "$haskey" ]; do
  echo 'generating ssh key'
  cat /dev/zero | ssh-keygen -q -N ""
  haskey=`ls -al ~/.ssh/id_rsa`
done

# copies SSH keys to other remote machines
for host in ${hosts[@]}; do
  username=`whoami`
  [ `hostname` == $host ] && continue # ssh keys not set up for local machine, TODO requires special handling later on
  echo "checking connection to ${host}"
  exec 3>&1  # Save the place that stdout (1) points to
  set +e
  keyinstalled=$(ssh -oBatchMode=yes -l ${username} ${host} exit 2>&1 1>&3)  # check if ssh connection is possible, should be empty if success, captures stderr
  set -e
  exec 3>&- # Close FD #3
  if [ ! -z "$keyinstalled" ]; then
    echo "set up ssh key for ${host} via the command: ssh-copy-id ${host}"
    exit 1
  fi
done


# for host in ${hosts[@]}; do
  # set +e
  # keynotinstalled=$(ssh -oBatchMode=yes -l `whoami` ${host} 'exit')
  # set -e
  # if [ ! -z "$keynotinstalled" ]; then
    # echo "install key for ${host}: ssh-copy-id ${host}"
    # exit 1
  # fi
# done




### Generate stack names to pass into reconstruction function
#---------------------------------------------------------------------------------
numStacks=`ls stack* | wc -l`

for i in $(seq 1 $numStacks); do
	arrStackNames[i-1]=../stack$i.nii.gz
done


### Generate arrays for packages/slice thickness
#---------------------------------------------------------------------------------
arrSliceThickness=$(grep -F "Slice Thickness Array = " log.txt | sed -e 's/[^0-9. ]//g')
arrPackages=$(grep -F "Packages Array = " log.txt | sed -e 's/[^0-9. ]//g')


### Get number of Iterations
#---------------------------------------------------------------------------------
numIterations=3		# TO DO: Automate this depending on slice order - Ask Ant.


### Check masks and get mask name for reconstruction
#---------------------------------------------------------------------------------
maskName=`ls *mask*.nii.gz`		# search for mask file

# Check that a mask exists
if [ $? -eq 0 ]; then	# If no file in format *mask*.nii.gz, then exit script
	echo	
else
	echo
	echo "#######################################################"
	echo "Mask not found. It must contain 'mask' in the filename."
	echo "#######################################################"
	echo
	exit
fi

# If more than one mask, ask user to specify which mask
numMasks=`ls *mask*.nii.gz | wc -l`
if [ $numMasks -gt 1 ]; then		
	
	arrMaskNames=(`echo ${maskName}`);
	echo "-------------------------------"
	echo "Multiple masks found:"
	echo " ${arrMaskNames[*]/%/$'\n'}" | column
	echo "Type which mask you would would like to use (including .nii.gz):"
	read maskName
fi



### Stack selection option
#---------------------------------------------------------------------------------
while true; do
	read -p "Would you like to reconstruct using all ["$numStacks"] of the stacks? [y/n]: " yn
	case $yn in
		[Yy]* ) break;;
		[Nn]* ) 
		echo
		echo "Which stacks would you like to use? You can choose from stacks 1 to "$numStacks
		echo "[Enter numbers separated by spaces, e.g: 1 2 4 6]:"
		read -a newStackArray	#read -a = read as array!
		 
		echo
		echo "You chose to reconstruct using stacks: "${newStackArray[@]}
		echo
		
		### Update arrStackNames, Packages and Slice Thicknesses
		unset arrStackNames
		unset numStacks
		unset arrSliceThickness
		unset arrPackages
		
		strSliceThk=$(grep -F "Slice Thickness Array = " log.txt)
		valueSliceThk=(${strSliceThk#*=})
		sliceThk=${valueSliceThk[1]}
		
		strPkgs=$(grep -F "Packages Array = " log.txt)
		valuePkgs=(${strPkgs#*=})
		pkgs=${valuePkgs[1]}
		
		numStacks=${#newStackArray[@]}			
		for i in $(seq 1 $numStacks); do
			arrStackNames[i-1]=../stack${newStackArray[i-1]}.nii.gz
			arrSliceThickness[i-1]=$sliceThk
			arrPackages[i-1]=$pkgs
		done
		
		break;;
		* ) echo "Please answer yes or no.";;
	esac
done


### Mask selection option
#---------------------------------------------------------------------------------
echo
echo "Which stack was the mask drawn on?" 
echo "You can choose from: "
echo "${arrStackNames[*]/%/$'\n'}" | column
echo "Please enter the number of the stack: "
read maskNum

# Reorder stack string so template is first (required for reconstruction function)
targetStack=(../stack$maskNum.nii.gz)
tempStackNames=(${arrStackNames[@]/$targetStack})
arrStackNames=("$targetStack" ${tempStackNames[@]})



### Sanity check for User
#---------------------------------------------------------------------------------
echo
echo "-------------------------------"
echo "SVR RECONSTRUCTION"
echo "-------------------------------"
echo
echo "Sanity check for the user:"
echo
echo "Template stack/Mask drawn on stack: "$maskNum
echo
echo "Order of stacks to be used: "
echo "${arrStackNames[*]/%/$'\n'}" | column
echo
echo "Using Mask called: "$maskName
echo
echo "Number of Packages: "${arrPackages[*]}
echo "Slice Thickness: "${arrSliceThickness[*]}
echo "Iterations = "$numIterations
echo

while true; do
	read -p "Proceed with reconstruction using these values? [y/n]: " yn
	case $yn in
		[Yy]* ) break;;
		[Nn]* ) echo "Exiting script."; echo; exit;;
		* ) echo "Please answer yes or no.";;
	esac
done

echo "-------------------------------"


# TO DO: Add in warning and option to change iterations from default of 3.
# TO DO: Add in option for user to set reconstruction resolution.



### Run reconstruction function
#---------------------------------------------------------------------------------
patientDir=$(basename `pwd`)
[-z "$patientDir" ] && exit 1

mkdir -p recon
cd recon



### Lock file
#---------------------------------------------------------------------------------
# while true; do
	# for lockfile in /tmp/recon_loc1 /tmp/recon_loc2; do
		# #trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT KILL
		# if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
		# then
			# trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT KILL
			
			


			echo
			echo "-------------------------------"
			echo "RUNNING RECONSTRUCTION"
			echo "-------------------------------"

			for host in ${hosts[@]}; do 
				ssh ${host} /pnraw01/FetalPreprocessing/bin/checkload.sh; 
			done | column -t -s','

			# TODO: edit user input here to select computer for recon
			i=2


			host=${hosts[i]}
			wdir=${wdirs[i]}
			set +x
			
			echo $host $wdir
			
			## TODO: -make it clear that running locally --- if local, don't do any SSH, just run scripts locally.
			if [ `hostname` == $host ]; then
				cd ${wdir}/${patientDir}/recon; /pnraw01/FetalPreprocessing/bin/max_jobs.bash \
													../outputSVRvolume.nii.gz \
													$numStacks \
													${arrStackNames[*]} \
													-mask ../$maskName \
													-packages ${arrPackages[*]} \
													-thickness ${arrSliceThickness[*]} \
													-iterations $numIterations
			else

			
			
			rsync -aP ../ ${host}:${wdir}/${patientDir}
			echo $host $wdir
			

			
			
			ssh ${host} "export PATH=/pnraw01/dhcp-reconstructions/FetalPreprocessing/bin/reconstruction:/pnraw01/dhcp-reconstructions/FetalPreprocessing/bin/lib:$PATH; \
						 cd ${wdir}/${patientDir}/recon; /pnraw01/dhcp-reconstructions/FetalPreprocessing/bin/max_jobs.bash \
															../outputSVRvolume.nii.gz \
															$numStacks \
															${arrStackNames[*]} \
															-mask ../$maskName \
															-packages ${arrPackages[*]} \
															-thickness ${arrSliceThickness[*]} \
															-iterations $numIterations"
			set -x
																	
																	
																	
															
																
			rsync -aP --remove-source-files ${host}:${wdir}/${patientDir}/ ../ 
			# ssh ${host} "rm -r ${wdir}"

			fi
			

			echo "-------------------------------"
			echo "RECONSTRUCTION FINISHED"
			echo "-------------------------------"





	 
		   # rm -f "$lockfile"
		   # trap - INT TERM EXIT
		# else
		   # echo "Failed to acquire lockfile: $lockfile, held by job $(cat $lockfile)"
		   # continue
		# fi
	# done
	# echo 'Waiting for reconstructions to finish...'
	# sleep 10
# done
