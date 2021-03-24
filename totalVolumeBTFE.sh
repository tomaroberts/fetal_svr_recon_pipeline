#!/bin/bash

### totalVolumeBTFE.sh
#
# One-stop script to perform automatic [WHOLE BODY] segmentation using Deep Learning from [BTFE STACKS]
# - USAGE: 
# - Download data from ISDPACS / raw format and copy into Input_Data folder in YOUR user area.
# - Run automaticSVR.sh
#
# - Asks the user to enter PatientID and scan date
# - Creates a folder using date (if required) and subfolder based on PatientID
# - Copies files across for automatic segmentation
# - Copies files back to patient folder once segmentation is completed
#
#
# - UPDATES:
# - 23/03/2021:
# - First implementation using Alena+Irina+Maria's /auto-recon-files directory implementation
#
# 
# - Alena Uus, KCL, March 2021
# - Tom Roberts, KCL, February 2021
# - t.roberts@kcl.ac.uk
#
##################################################################################


### Path definitions
#- path_input    = put zip file from ISDPACS in this folder
#- path_fetalrep = pnraw fetal reporting folder
#---------------------------------------------------------------------------------
#path_input=/pnraw01/FetalPreprocessing/Input_Data
path_input=~/Input_Data
path_fetalrep=/pnraw01/FetalPreprocessing

cd ${path_input}

# Remove log.txt if one exists (should prevent errors)
txtCount=`ls log.txt 2>/dev/null | wc -l`
if [[ ${txtCount} -gt 0 ]]; then
	rm log.txt
fi

### Enter Patient ID twice
#---------------------------------------------------------------------------------
echo "Please type the Patient ID, followed by [ENTER]:"
read patid1

patid1=${patid1}_totalvolume


clear

echo -e "Please type the Patient ID once more, followed by [ENTER]:"
read patid2

patid2=${patid2}_totalvolume


### Check Patient ID entered correctly
#---------------------------------------------------------------------------------
echo "Checking Patient ID matches..."

if [[ ${patid1} = ${patid2} ]];then
	echo
	echo "###################"
	echo "Patient ID matches."
	echo "###################"	
	echo
	
### Exit script if Patient ID entered incorrectly
else
	echo
	echo "#############################################################"
	echo "Patient ID entered incorrectly. Please run this script again."
	echo "#############################################################"
	echo
	exit
fi


### Enter study date and check date entered correctly
#---------------------------------------------------------------------------------
echo "Please input the date of the scan. Press [ENTER] after each step:"

while true; do
    
echo "Year (YYYY):"
read date_year
echo "Month (MM):"
read date_month
echo "Day (DD):"
read date_day
echo
echo "Date entered as: "${date_year}"_"${date_month}"_"${date_day}
echo	
	
	read -p "Is this the correct date? [y/n]: " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo; echo "Please re-input the date of the scan. Press [ENTER] after each step:";;
        * ) echo "Please answer yes or no.";;
    esac
done



### Check/create directories for that day and patient
#---------------------------------------------------------------------------------
cd ${path_fetalrep} #cd to fetal reporting folder

# check for folder on that day and create if doesn't exist
dayFolder=${date_year}"_"${date_month}"_"${date_day}

if [[ ! -d ${dayFolder} ]];then
	mkdir ${dayFolder}
	
	# give folder sticky bits permissions, so all users can share directory
	chmod 775 ${dayFolder}; chmod +t ${dayFolder};
	
	echo
	echo "Folder created with the date: "${dayFolder}
	echo
elif [[ -d ${patientFolder} ]];then

	cd ${dayFolder}
fi

cd ${dayFolder} #enter day folder



# create patient folder if doesn't exist
patientFolder=${patid1}

if [[ ! -d ${patientFolder} ]];then
	mkdir ${patientFolder}
	
	echo "Folder created with the name: "${patientFolder}
	echo
elif [[ -d ${patientFolder} ]];then

	echo
	echo "######################################################################"
	echo "Folder already exists with this date and Patient ID!"
	echo "To prevent overwriting any data, this script will exit."
	echo "Exiting script..."
	echo "######################################################################"
	echo
	exit
fi

# Update log.txt
cd ${path_input}
patientFolderLength=${#patientFolder}

echo "Input_Data Path = '"${path_input}"'" >> log.txt
echo "Recon Path = '"${path_fetalrep}"'" >> log.txt
echo "Folder Date = '"${dayFolder}"'" >> log.txt
echo "Folder Name = '*****"${patientFolder:5:$patientFolderLength}"'" >> log.txt




### Detect Data Type in Input_Folder
#---------------------------------------------------------------------------------
cd ${path_input}

### Check if the folder is empty
nostudies=`ls ${path_input} 2>/dev/null | wc -l`
if [[ ${nostudies} -eq 0 ]] ; then
	echo "There is no data in the Input_Data folder."
	exit
fi


### Identify Data Type
echo
echo "######################################################################"
echo "Identifying Data..."
echo "######################################################################"
echo




### Check for ZIP file(s) and unzip (or warn and abort script).
testZIP=`ls *.zip 2>/dev/null | wc -l`
if [[ ${testZIP} -eq 1 ]]; then
	echo
	echo "Found a .ZIP file. Unzipping and examining contents..."
	echo
	
	zipFile=`ls *.zip`
	unzip ${zipFile}
	#rm *PHILIPS*.zip #An alternative here is to keep a copy
	
elif [[ ${testZIP} -gt 1 ]]; then
	
	echo
	echo "Found multiple .ZIP files! Please check that you haven't downloaded multiple/duplicate scans."
	echo "Aborting script."
	echo
	exit
	
fi 


### Move .nii Files to Patient Folder
#---------------------------------------------------------------------------------

find . -name "*.nii*" -exec cp {} ${path_fetalrep}/${dayFolder}/${patientFolder} \; 
	
ls ${path_fetalrep}/${dayFolder}/${patientFolder} 


echo
echo "######################################################################"
echo "Stacks saved to:"
echo ${path_fetalrep}/${dayFolder}/${patientFolder}
echo "######################################################################"
echo


cd ${path_fetalrep}/${dayFolder}/${patientFolder}



### Perform automatic segmentation with Deep Learning
#---------------------------------------------------------------------------------
#path_autoSegmentation_input=/projects/perinatal/peridata/fetalsvr/auto-segmentation-files/whole_body
#path_autoSegmentation_output=/projects/perinatal/peridata/fetalsvr/auto-segmentation-files/results-whole_body

path_autoSegmentation_input=/pnraw01/FetalPreprocessing/auto-recon-files/whole_body
path_autoSegmentation_output=/pnraw01/FetalPreprocessing/auto-recon-files/results-whole_body




#THE TRANSFER FOLDER HAS RANDOM ID GENERAGED
#id_transfer=${RANDOM}${RANDOM}


id_transfer=${patientFolder}
path_autoSegmentation_patientFolder=${path_autoSegmentation_input}/${dayFolder}"_"${id_transfer}


mkdir ${path_autoSegmentation_patientFolder}

cp ${path_fetalrep}/${dayFolder}/${patientFolder}/*.nii* ${path_autoSegmentation_patientFolder}


echo
echo "######################################################################"
echo "Running automatic segmentation of the whole fetal body ..."
echo "######################################################################"
echo


### while loop - Wait for segmentation to complete

checkOutputFolder=${path_autoSegmentation_output}/${dayFolder}_${id_transfer}-segmentations


isProcessed=false
while ! ${isProcessed}; do

	echo "Segmentation is still running..."	

    # Detect output segmentation folder with files / if found, exit while loop
	if [[ -d ${checkOutputFolder} ]];then
		echo
		echo "Mask Files Found! Copying to patient directory..."
		echo
		isProcessed=true
	fi
			
	sleep 60

done


in_stack_names=$(ls ${path_fetalrep}/${dayFolder}/${patientFolder}/*.nii*)
IFS=$'\n' read -rd '' -a all_stacks <<<"$in_stack_names"


### Copy / clean up
cp ${path_autoSegmentation_output}/${dayFolder}_${id_transfer}-segmentations/*fetus* ${path_fetalrep}/${dayFolder}/${patientFolder}/
#rm -r ${path_autoSegmentation_patientFolder}
#rm -r ${checkOutputFolder}


out_mask_names=$(ls ${path_fetalrep}/${dayFolder}/${patientFolder}/*fetus*)
IFS=$'\n' read -rd '' -a all_masks <<<"$out_mask_names"


ls ${path_fetalrep}/${dayFolder}/${patientFolder}/*fetus*


echo
echo "######################################################################"
echo "Displaying masks for refinement & printing mask volume ..."
echo "######################################################################"
echo


itksnap=/pnraw01/FetalPreprocessing/itksnap-3.4.0-20151130-Linux-x86_64-qt4/bin/itksnap


for ((j=0;j<${#all_stacks[@]};j++));
do

	echo " - stack : " ${all_stacks[$j]} " & mask : " ${all_masks[$j]}

	${itksnap} -g ${all_stacks[$j]} -s ${all_masks[$j]}

	/projects/perinatal/peridata/fetalsvr/software/svrtk-112020/MIRTK/build/lib/tools/mask_count ${all_masks[$j]}

	echo 

done 



#rm -r $path_autoSVRrecon_patientFolder

echo 
echo "-------------------------------"
echo "SEGMENTATION FINISHED "
echo "Data saved to: "
echo ${path_fetalrep}/${dayFolder}/${patientFolder}
echo "-------------------------------"


