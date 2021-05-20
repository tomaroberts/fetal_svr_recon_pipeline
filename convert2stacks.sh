#!/bin/bash

### convert2stacks.sh
#
# Converts data into individual stacks.
#
# - USAGE: 
# - Run convert2stacks.sh in the patient folder
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
##################################################################################


### Detect file types
isNiiFiles=`ls -1 *.nii 2>/dev/null | wc -l`		# NIFTI files (probably from raw recon)
isZipFile=`ls -1 *PHILIPS* 2>/dev/null | wc -l`		# ISDPACS download as a .ZIP file


### Individual nifti files
if [ $isNiiFiles -ne 0 ]; then
	
	echo
	echo "----------------------------------"
	echo "NIFTI files found."
	echo "----------------------------------"

	
	
	### Loop through NIFTI files, get parameters and rename stacks
	#---------------------------------------------------------------------------------
	arrNii=(`ls *.nii`)
	numNii=`ls *.nii | wc -l`


	d=0
	ctrDyns=0
	ctrStack=1
	while [ $d -lt $numNii ] ; do		# loop until hit d'th .nii
		niiCurr=${arrNii[$d]}							
		
		#---Get Image Dimensions
		imdimStr=$(info $niiCurr | grep "Image dimensions" | sed -e 's/[^0-9 ]//g')		# Here, sed pipes only the numbers and spaces to the variable
		echo "Image dimensions = "$imdimStr
		arr=(`echo ${imdimStr}`);
		
		#---Get Number of Dynamics in Volume
		numDyns=${arr[3]}		# Last dimension = dynamics
		echo "Number of dynamics in volume = "$numDyns
		ctrDyns=`expr $ctrDyns + $numDyns`

		#---Get Voxel Dimensions
		voxdimStr=$(info $niiCurr | grep "Voxel dimensions" | sed -e 's/[^0-9. ]//g')		# Here, sed pipes only the numbers, decimals and spaces to the variable
		echo "Voxel dimensions = "$voxdimStr
		arr=(`echo ${voxdimStr}`);
			
		#---Get Slice Thickness
		sliceThk=$(grep -F "Slice Thickness = " log.txt | awk -F "'" '{print $2}')
		echo "Slice thickness = "$sliceThk
			
		#---Get Packages
		pkgs=$(grep -F "Number of Packages = " log.txt | awk -F "'" '{print $2}')
		echo "Number of Packages = "$pkgs
		
		
					
		#---Make new .nii files, one per stack	
		if [ $numDyns -eq 1 ];then
		
			# if volume is single dynamic, simply copy and rename .nii
			cp $niiCurr stack$ctrStack.nii.gz
			echo "Created stack"$ctrStack".nii.gz"
			echo "-------------------------------"
			ctrStack=`expr $ctrStack + 1`
			
			#---Put values in arrays
			SLICETHICKNESS[$ctrStack]=$sliceThk
			PACKAGES[$ctrStack]=$pkgs
	#		PACKAGES[d]=$(echo $niiCurr | sed -e 's|.*mi\(.*\)s.*|\1|')		#sed finds everything between "mi" and "s" in filename.	
			
		
		
		elif [ $numDyns -gt 1 ];then
		
			# if volume has multiple dynamics, need to split using region from IRTK
			for i in $(seq 1 $numDyns); do
				
				# Need to be careful with the 'region' function
				# -Rt1 = index of first temporal position
				# -Rt2 = index of final temporal position
				# eg: region <...> -Rt1 3 -Rt2 6 would produce a new volume with 3 dynamics.
				# I want a single dynamic on each loop, ie: a single temporal position, ie: Rt2-Rt1 = 1.
				# NB: remember we count from 0, hence -Rt1 0 = dynamic 1.
				region $niiCurr stack$ctrStack.nii.gz -Rt1 `expr $i - 1` -Rt2 $i					
				echo "Created stack"$ctrStack".nii.gz, using dynamic number "$i
				echo "-------------------------------"
				ctrStack=`expr $ctrStack + 1`
				
			#---Put values in arrays
			SLICETHICKNESS[$ctrStack]=$sliceThk
			PACKAGES[$ctrStack]=$pkgs
	#		PACKAGES[d]=$(echo $niiCurr | sed -e 's|.*mi\(.*\)s.*|\1|')		#sed finds everything between "mi" and "s" in filename.	
		
			done
		fi
			
		
		d=`expr $d + 1`
	done

	echo "Slice Thickness Array = "${SLICETHICKNESS[*]} >> log.txt
	echo "Packages Array = "${PACKAGES[*]} >> log.txt	
		
	echo
	echo "----------------------------------"
	echo "Converted "$numNii" NIFTI files into stack*.nii files."
	echo "Important parameters for SVR reconstruction saved to log.txt"
	echo "----------------------------------"
	echo	
	
	
	
	

### ZIP file
elif [ $isZipFile -ne 0 ]; then

	echo
	echo "----------------------------------"
	echo "ZIP file found."
	echo "----------------------------------"

	echo
	echo "----------------------------------"
	echo "Unzipping volumes"
	echo "----------------------------------"

	unzip *PHILIPS*.zip
	# rm *PHILIPS*.zip		# Keep .zip incase need to re-run one of the scripts


	### Get folder names
	#---------------------------------------------------------------------------------	
	volFolds=(`ls -d *PHILIPS*/ | awk '{printf "%s ",$1}'`)
	numVols=`ls -d *PHILIPS*/ | wc -l`


	### Detect downloaded filetype: nifti or dicom
	#---------------------------------------------------------------------------------
	cd ${volFolds[0]}
	isNifti=`ls -1 *.nii.gz 2>/dev/null | wc -l`
	isDicom=`ls -1 *.dcm 2>/dev/null | wc -l`
	cd ..
	
	
	### Loop through volumes
	#---------------------------------------------------------------------------------

	echo
	echo "----------------------------------"
	echo "Sorting through "$numVols" folders:"
	echo "----------------------------------"

	### Preprocess nifti
	if [ $isNifti -ne 0 ]; then

		d=0
		ctrDyns=0											# Counter to keep track of current folder
		ctrStack=1											# Counter to keep track of which .nii will be created next --- sorry, bit confusing with ctrDyns...
		while [ $d -lt $numVols ] ; do						# loop until hit d'th folder
			volCurr=${volFolds[$d]}							# %d corresponds to the idx of the current volume folder => volsv is string of current directory
			cd $volCurr
			echo "Current dir: "$volCurr
			
			# Nifti files
			if [ $isNifti -ne 0 ]; then
			
				#--- Gunzip metadata file
				# Must get Slice Thickness from .metadata file, as not in .nii header
				# Remove .metadata later to avoid overwrite message if need to repeat script
				mdataGz=`ls *metadata.gz`
				# echo "mdataGz file = "$mdataGz
				gunzip -k $mdataGz
				mdataFile=`ls *metadata`
				# echo "mdata file = "$mdataFile
				
				#---Get Slice Thickness
				sliceThk=$(grep -F "PerFrameFunctionalGroupsSequence[1].(2005,140f)[1].SliceThickness" $mdataFile | awk -F "'" '{print $2}') # awk - finds everything between '...' in specified DICOM header
				echo "Slice thickness = "$sliceThk
				
				#---Get Image Dimensions
				imdimStr=$(info *.nii.gz | grep "Image dimensions" | sed -e 's/[^0-9 ]//g')		# Here, sed pipes only the numbers and spaces to the variable
				echo "Image dimensions = "$imdimStr
				arr=(`echo ${imdimStr}`);
				
				#---Get Number of Dynamics in Volume
				numDyns=${arr[3]}		# Last dimension = dynamics
				echo "Number of dynamics in volume = "$numDyns
				ctrDyns=`expr $ctrDyns + $numDyns`

				#---Get Voxel Dimensions
				voxdimStr=$(info *.nii.gz | grep "Voxel dimensions" | sed -e 's/[^0-9. ]//g')		# Here, sed pipes only the numbers, decimals and spaces to the variable
				echo "Voxel dimensions = "$voxdimStr
				arr=(`echo ${voxdimStr}`);
			fi
			
			# Dicom files
			if [ $isDicom -ne 0 ]; then			
				# Convert dicom file to .nii.gz
				/pnraw01/FetalPreprocessing/bin/dcm2niix -z y -b n .
				/projects/perinatal/peridata/fetalsvr/software/svrtk-112020/MIRTK/build/bin/mirtk extract-image-region *.nii.gz -split t
			fi
			
				
			#---Make new .nii files, one per stack	
			if [ $numDyns -eq 1 ];then
			
				# if volume is single dynamic, simply copy and rename .nii
				cp *.nii.gz ../stack$ctrStack.nii.gz
				echo "Created stack"$ctrStack".nii.gz"
				echo "-------------------------------"
				ctrStack=`expr $ctrStack + 1`
				
				#---Put values in arrays
				SLICETHICKNESS[$ctrStack]=$sliceThk
				PACKAGES[$ctrStack]=4	#TO DO: Automate depending on whether ZOOM/iFIND/dHCP normal
				
			
			
			elif [ $numDyns -gt 1 ];then
			
				# if volume has multiple dynamics, need to split using region from IRTK
				for i in $(seq 1 $numDyns); do
					
					# Need to be careful with the 'region' function
					# -Rt1 = index of first temporal position
					# -Rt2 = index of final temporal position
					# eg: region <...> -Rt1 3 -Rt2 6 would produce a new volume with 3 dynamics.
					# I want a single dynamic on each loop, ie: a single temporal position, ie: Rt2-Rt1 = 1.
					# NB: remember we count from 0, hence -Rt1 0 = dynamic 1.
					region *.nii.gz ../stack$ctrStack.nii.gz -Rt1 `expr $i - 1` -Rt2 $i					
					echo "Created stack"$ctrStack".nii.gz, using dynamic number "$i
					echo "-------------------------------"
					ctrStack=`expr $ctrStack + 1`
					
				#---Put values in arrays
				SLICETHICKNESS[$ctrStack]=$sliceThk
				PACKAGES[$ctrStack]=4	#TO DO: Automate depending on whether ZOOM/iFIND/dHCP normal
			
				done
			fi
			
			
			# Clean-up: remove .metadata file
			rm *.metadata
				
			# move up, step counter
			cd ..
			d=`expr $d + 1`
		done
		
	
	### Preprocess dicoms (convert to nifti)
	elif [ $isDicom -ne 0 ]; then
		 
		d=0
		stackFileNumberCtr=1
		while [ $d -lt $numVols ]; do	
		 
			cd ${volFolds[$d]}
		 
			echo "Entering... " ${volFolds[$d]}
		 
			/pnraw01/FetalPreprocessing/bin/dcm2niix -z y .
			/projects/perinatal/peridata/fetalsvr/software/svrtk-112020/MIRTK/build/bin/mirtk extract-image-region *.nii.gz stack.nii.gz -split t
			 
			niiFilenames=(`ls stack*.nii.gz`)
			numNiiFiles=`ls stack*.nii.gz | wc -l`

			# rename stacks stack1.nii.gz...stackN.nii.gz
			iF=0
			while [ $iF -lt $numNiiFiles ] ; do
				mv ${niiFilenames[$iF]} stack$stackFileNumberCtr.nii.gz
				iF=`expr $iF + 1`
				stackFileNumberCtr=`expr $stackFileNumberCtr + 1`
			done
			
			mv stack*.nii.gz ..		# put files up one directory
			rm *.nii.gz 			# remove dcm2niix nifti
			
			# get parameters from .json
			sliceThk=$(grep -F "SliceThickness" *.json | awk -F ": " '{print $2}' | awk -F "," '{print $1}' )
			rm *.json
			
			# logfile arrays
			SLICETHICKNESS[$d]=$sliceThk
			PACKAGES[$d]=4
			
			
			d=`expr $d + 1`
			
			cd ..

		done
	
	fi


	#---Rescale stacks to prevent irtk dynamicRange error

	echo
	echo "Rescaling stacks ..."
	echo

	stackFiles=`ls stack*.nii* | wc -l`

	for i in $(seq 1 $stackFiles)
	do
		rescale stack$i.nii.gz stack$i.nii.gz 0 300
	done

	echo
	echo "Rescaling complete."

		
	#---Save file containing parameters for reconstruction
	echo "Slice Thickness Array = "${SLICETHICKNESS[*]} >> log.txt
	echo "Packages Array = "${PACKAGES[*]} >> log.txt


	echo
	echo "----------------------------------"
	echo "Converted "$numVols" folders to individual NIFTI files."
	echo "Important parameters for SVR reconstruction saved to log.txt"
	echo "----------------------------------"
	echo




## Exit if unknown data
else

	echo
	echo "----------------------------------"
	echo "DATA DETECTED AS: UNKNOWN!"
	echo "Exiting Script."
	echo "----------------------------------"
	exit

fi 














