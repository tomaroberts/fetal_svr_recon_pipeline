#!/bin/bash

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
# --- NB: currently hard-coded to reconstruct at 0.75mm resolution
#
# - UPDATES:
#
# - 05/09/2018
# - Script now automatically detects if .vtk files are present. If so, runs prreg and supplies .dof files to reconstruction
# - .vtk files must be named stack1.vtk, stack2.vtk, etc.
#
# - 31/08/2018
# - Main addition: added option for user to supply .vtk files for Landmark-based reconstruction
# - Added option to specify number of iterations
# - Adjusted numStacks search to only find *.nii* files. Prevents detection of .vtk/.dof files with same name
#
# - 11/07/2018 
# - Added option to specify template stack
# - String supplied to reconstruction function always begins with template stack
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
#####################################################################################


### Generate stack names to pass into reconstruction function
#---------------------------------------------------------------------------------
numStacks=`ls stack*.nii* | wc -l`

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


### Mask selection option
#---------------------------------------------------------------------------------
echo
echo "Which stack was the mask drawn on?" 
echo "You can choose from: "
echo "${arrStackNames[*]/%/$'\n'}" | column
echo
echo "Please enter the number of the stack: "
read maskNum



### Landmark (.vtk files) option
#---------------------------------------------------------------------------------

# Detect if any .vtk files	
numVtkFiles=$(find -name "*.vtk" | wc -l)

if [ $numVtkFiles -gt 0 ]; then

	arrVtkFiles=(`ls stack*.vtk`)	
	targetVtkStack=(stack$maskNum.vtk)
	
	echo
	echo "DETECTED the following .vtk files:"
	echo "${arrVtkFiles[*]/%/$'\n'}" | column
	echo
	
	

	while true; do
		echo 
		read -p "Would you like to like to run a landmark-based reconstruction? [y/n]: " yn
		case $yn in
			[Yy]* ) 
			
				for i in $(seq 1 $numVtkFiles); do
					currStr=${arrVtkFiles[i-1]}		
					currNum=$(echo $currStr | sed -e 's|.*stack\(.*\).vtk.*|\1|') #extract stack number from string
					arrVtkNumbers[i-1]=$currNum
				done
				
				### Run prreg: outputs .dof files
				#arrDofNumbers=(${arrVtkNumbers[@]/$maskNum}) #want all numbers except target stack
				#numDofFiles=$((numVtkFiles-1))
				
				echo
				echo "Running prreg to generate .dof files..."
				echo	
				
				for i in $(seq 1 $numVtkFiles); do
					#arrDofFiles[i-1]=../"stack-"$maskNum"-"${arrVtkNumbers[i-1]}.dof	
					prreg $targetVtkStack stack${arrVtkNumbers[i-1]}.vtk -dofout "stack-"$maskNum"-"${arrVtkNumbers[i-1]}.dof
				done

				declare -a arrDofFiles=(`ls *.dof`) #declare necessary to put on single line for reconstruction command
			
				echo
				echo "Which stacks would you like to use in the reconstruction?"
				echo "You can ONLY choose stacks which have associated .dof files - these are: "${arrVtkNumbers[@]}
				echo "[Enter numbers separated by spaces]:"
				read -a newStackArray	#read -a = read as array!
				
				### Update arrStackNames, Packages and Slice Thicknesses
				unset arrStackNames
				unset numStacks
				unset arrSliceThickness
				unset arrPackages
				unset arrDofFiles
				
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
					arrDofFiles[i-1]=../stack-$maskNum-${newStackArray[i-1]}.dof
				done
			
			break;;
			
			[Nn]* ) 
			
				unset numVtkFiles #make blank
				numVtkFiles=0
			
			break;;
			* ) echo "Please answer yes or no.";;
		esac
	done



	echo 
fi



### Stack selection option
#---------------------------------------------------------------------------------
if [ $numVtkFiles -eq 0 ]; then #if condition skips this section if Landmark-based recon specified
	while true; do
		read -p "Would you like to reconstruct using all ["$numStacks"] of the stacks? [y/n]: " yn
		case $yn in
			[Yy]* ) 
			break;;
			
			[Nn]* ) 
				echo
				echo "Which stacks would you like to use in the reconstruction? You can choose from stacks 1 to "$numStacks
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
fi




### Reorder SVR string if target stack is not stack1
#---------------------------------------------------------------------------------
#- required for reconstruction function
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

if [ $numVtkFiles -gt 0 ]; then	
	echo "Landmark files: "
	echo "${arrDofFiles[*]/%/$'\n'}" | column
	echo
fi


while true; do
    read -p "Proceed with reconstruction using these values? [y/n]: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Exiting script."; echo; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "-------------------------------"


# TO DO: Add in option for user to set reconstruction resolution.


### Run reconstruction function
#---------------------------------------------------------------------------------

mkdir recon
cd recon

echo
echo "-------------------------------"
echo "RUNNING RECONSTRUCTION"
echo "-------------------------------"

if [ $numVtkFiles -gt 0 ]; then	#untidy, loop could be removed - purely for -dofin input...
	
	# with Landmarks
	reconstruction ../outputSVRvolume.nii.gz \
					$numStacks \
					${arrStackNames[*]} \
					-dofin ${arrDofFiles[*]} \
					-mask ../$maskName \
					-packages ${arrPackages[*]} \
					-thickness ${arrSliceThickness[*]} \
					-iterations $numIterations \
					
else

	# without Landmarks (default)
	reconstruction ../outputSVRvolume.nii.gz \
					$numStacks \
					${arrStackNames[*]} \
					-mask ../$maskName \
					-packages ${arrPackages[*]} \
					-thickness ${arrSliceThickness[*]} \
					-iterations $numIterations \

fi

echo "-------------------------------"
echo "RECONSTRUCTION FINISHED"
echo "-------------------------------"
