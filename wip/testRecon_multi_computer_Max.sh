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
# - Reconstruction can be run on either gpubeastie01-pc, beastie01 or beastie02
#
# --- NB: currently hard-coded to do 3 iterations, 0.75mm resolution
#
# - UPDATES:
#
# - 15/08/2019
# - Big update to allow reconstructions on gpubeastie01-pc, beastie01 or beastie02
# - Lots of additional code from Max
# - User can now choose which machine will perform the reconstruction. The data is sent
#   to that machine, reconstructed, and then returned to pnraw01.
#
# - 11/07/2018 
# - Added option to specify template stack
# - String supplied to reconstruction function always begins with template stack
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
#####################################################################################

	echo
	echo "-------------------------------"
	echo "autoReconstruct SCRIPT"
	echo "-------------------------------"
	echo


### Check connections to available machines
#---------------------------------------------------------------------------------
hosts=(gpubeastie01-pc beastie01 beastie02)
wdirs=(/pnraw01/FetalPreprocessing /scratch/tmp_recon /scratch/tmp_recon)

# SSH keys - check installed, if not install one
haskey=`ls -al ~/.ssh/id_rsa`
while [ -z "$haskey" ]; do
  echo 'generating ssh key'
  cat /dev/zero | ssh-keygen -q -N ""
  haskey=`ls -al ~/.ssh/id_rsa`
done

# copies SSH keys to other remote machines
echo "Checking connections to remote computers ..."
for host in ${hosts[@]}; do
  username=`whoami`
  [ `hostname` == $host ] && continue # ssh keys not set up for local machine, TODO requires special handling later on
  echo "Checking connection to ${host} ..."
  exec 3>&1  # Save the place that stdout (1) points to
  set +e
  keyinstalled=$(ssh -oBatchMode=yes -l ${username} ${host} exit 2>&1 1>&3)  # check if ssh connection is possible, should be empty if success, captures stderr
  set -e
  exec 3>&- # Close FD #3
  if [ ! -z "$keyinstalled" ]; then
    echo "Set up ssh key for ${host} via the command: ssh-copy-id ${host}. Ask Max/Tom if stuck."
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

echo
echo "-------------------------------"
echo "SVR RECONSTRUCTION OPTIONS"
echo "-------------------------------"
echo


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


### Get number of Iterations
#---------------------------------------------------------------------------------
echo
echo -e "Please type number of iterations (default = 3) you would like to run, followed by [ENTER]:"
read numIterations


### Sanity check for User
#---------------------------------------------------------------------------------
echo
echo "-------------------------------"
echo "SVR RECONSTRUCTION PARAMETERS"
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


# TO DO: Add in option for user to set reconstruction resolution.



### Run reconstruction function
#---------------------------------------------------------------------------------
patientDir=$(basename `pwd`)
[ -z "$patientDir" ] && exit 1

mkdir -p recon
cd recon


			echo
			echo "-------------------------------"
			echo "COMPUTER LOAD CHECK"
			echo "-------------------------------"

			# user input here to select computer for recon
			while true; do
			for (( ihost=0; ihost<${#hosts[@]}; ihost++ )); do
				host=${hosts[ihost]}
				if [ $host == `hostname` ]; then 
                                     echo ${ihost}: `/pnraw01/FetalPreprocessing/bin/checkload.sh`
				else
                                     echo ${ihost}: `ssh ${host} /pnraw01/dhcp-reconstructions/FetalPreprocessing/bin/checkload.sh`
                                fi 
			done | column -t -s','

				echo
				echo "Please select a computer on which to run the reconstruction."
				echo "Lower CPU load and lower RAM usage is better."
				echo "Rule of thumb: beastie01 or beastie02 are a good choice as they have plenty of RAM."
				echo "[0 = gpubeastie01-pc]"
				echo "[1 = beastie01]"
				echo "[2 = beastie02]"
				echo "Type the number of the computer you would like to use: "
				echo

				read -r i
					
				# input check
				re='^[0-9]+$'
				if ! [[ "$i" =~ $re ]] ; then
				   echo "Error: Not a number: $i"; continue
				fi

				if [ "$i" -ge 0 -a "$i" -lt ${#hosts[@]} ]; then
					break
				else 
					echo "Error: not in valid range 0...${#hosts[@]}: $i"; continue
				fi
			
			done			


			echo
			echo "-------------------------------"
			echo "RUNNING RECONSTRUCTION"
			echo "-------------------------------"
			
			
			host=${hosts[i]}
			wdir=${wdirs[i]}
			set +x
			
			echo
			echo Running reconstruction on: $host in: ${wdir}/${patientDir}
			
			if [ `hostname` == $host ]; then
				cd ${wdir}/${patientDir}/recon; /pnraw01/FetalPreprocessing/bin/max_jobs.bash ../outputSVRvolume.nii.gz \
																								$numStacks \
																								${arrStackNames[*]} \
																								-mask ../$maskName \
																								-packages ${arrPackages[*]} \
																								-thickness ${arrSliceThickness[*]} \
																								-iterations $numIterations
			
			else
				rsync -a --stats ../ ${host}:${wdir}/${patientDir}
			
				ssh -o ServerAliveInterval=60 ${host} "export PATH=/pnraw01/dhcp-reconstructions/FetalPreprocessing/bin:$PATH; cd ${wdir}/${patientDir}/recon; LD_LIBRARY_PATH=/pnraw01/dhcp-reconstructions/FetalPreprocessing/bin/lib /pnraw01/dhcp-reconstructions/FetalPreprocessing/bin/max_jobs.bash ../outputSVRvolume.nii.gz \
																	$numStacks \
																	${arrStackNames[*]} \
																	-mask ../$maskName \
																	-packages ${arrPackages[*]} \
																	-thickness ${arrSliceThickness[*]} \
																	-iterations $numIterations"
			
			
				# ssh -o ServerAliveInterval=60 ${host} "export PATH=${wdir}/${patientDir}:$PATH; cd ${wdir}/${patientDir}/recon; LD_LIBRARY_PATH=${wdir}/${patientDir}/lib /pnraw01/dhcp-reconstructions/FetalPreprocessing/bin/max_jobs.bash ../outputSVRvolume.nii.gz \
																	# $numStacks \
																	# ${arrStackNames[*]} \
																	# -mask ../$maskName \
																	# -packages ${arrPackages[*]} \
																	# -thickness ${arrSliceThickness[*]} \
																	# -iterations $numIterations"
																	
				rsync -a --stats --remove-source-files ${host}:${wdir}/${patientDir}/ ../ 
				# ssh ${host} "find ${host}:${wdir}/${patientDir}/ -depth -type d -empty -delete"
				ssh ${host} "find ${wdir}/${patientDir}/ -depth -type d -empty -delete"
			fi
			

			echo "-------------------------------"
			echo "RECONSTRUCTION FINISHED"
			echo "-------------------------------"


