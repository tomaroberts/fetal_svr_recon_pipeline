#!/bin/bash

### createFolder.sh
#
# Creates a folder in FetalPreprocessing named according to PatientID and scan date.
#
# - USAGE: 
# - Download data from ISDPACS / raw format and copy into Input_Data folder in YOUR user area.
# - Run createFolder.sh
#
# - Asks the user to enter PatientID and scan date
# - Creates a folder using date (if required) and subfolder based on PatientID
# - Determines datatype, ie: T1/T2/downloaded from ISDPACS/raw format
# - Copies the data to the ne folder ready for unpacking/SVR reconstruction
#
#
# - UPDATES:
# - 31/08/2018 
# - Amended so that script works from Input_Data folder in user's home directory
# - Solves issue with multiple users requiring communal Input_Data directory
# - Amended log.txt output to partially-asterisks patientID
# - Changed script to reflect new Date > PatientID folder structure
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
##################################################################################

### Path definitions
#- path_input    = put zip file from ISDPACS in this folder
#- path_fetalrep = pnraw fetal reporting folder
#---------------------------------------------------------------------------------

# Detect host computer: required because paths to FetalPreprocessing are varied
host_name=`hostname`
if [ $host_name = "beastie01" ];then
	path_fetalrep=/pnraw01/dhcp-reconstructions/FetalPreprocessing/TomFetalRep
fi

if [ $host_name = "beastie02" ];then
	path_fetalrep=/pnraw01/dhcp-reconstructions/FetalPreprocessing/TomFetalRep
fi

if [ $host_name = "gpubeastie01-pc" ];then
	path_fetalrep=/pnraw01/FetalPreprocessing/TomFetalRep
fi

#path_input=/pnraw01/FetalPreprocessing/Input_Data
path_input=~/Input_Data

cd $path_input

# Remove log.txt if one exists (should prevent errors)
txtCount=`ls log.txt 2>/dev/null | wc -l`
if [ $txtCount -gt 0 ]; then
	rm log.txt
fi

### Enter Patient ID twice
#---------------------------------------------------------------------------------
echo "Please type the Patient ID, followed by [ENTER]:"
read patid1

clear

echo -e "Please type the Patient ID once more, followed by [ENTER]:"
read patid2


### Check Patient ID entered correctly
#---------------------------------------------------------------------------------
echo "Checking Patient ID matches..."

if [ $patid1 = $patid2 ];then
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
echo "Date entered as: "$date_year"_"$date_month"_"$date_day
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
cd $path_fetalrep #cd to fetal reporting folder

# check for folder on that day and create if doesn't exist
dayFolder=$date_year"_"$date_month"_"$date_day

if [[ ! -d "${dayFolder}" ]];then
	mkdir "$dayFolder"
	
	echo
	echo "Folder created with the date: "$dayFolder
	echo
elif [[ -d "${patientFolder}" ]];then

	cd $dayFolder
fi

cd $dayFolder #enter day folder



# create patient folder if doesn't exist
patientFolder=$patid1

if [[ ! -d "${patientFolder}" ]];then
	mkdir "$patientFolder"
	
	echo "Folder created with the name: "$patientFolder
	echo
elif [[ -d "${patientFolder}" ]];then

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
cd $path_input
patientFolderLength=${#patientFolder}

echo "Input_Data Path = '"$path_input"'" >> log.txt
echo "Recon Path = '"$path_fetalrep"'" >> log.txt
echo "Folder Date = '"$dayFolder"'" >> log.txt
echo "Folder Name = '*****"${patientFolder:5:$patientFolderLength}"'" >> log.txt







### Detect Data Type in Input_Folder
#---------------------------------------------------------------------------------
cd $path_input

### Check if the folder is empty
nostudies=`ls $path_input 2>/dev/null | wc -l`
if [ $nostudies -eq 0 ] ; then
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
if [ $testZIP -eq 1 ]; then
	echo
	echo "Found a .ZIP file. Unzipping and examining contents..."
	echo
	
	zipFile=`ls *.zip`
	unzip $zipFile
	#rm *PHILIPS*.zip #An alternative here is to keep a copy
	
elif [ $testZIP -gt 1 ]; then
	
	echo
	echo "Found multiple .ZIP files! Please check that you haven't downloaded multiple/duplicate scans."
	echo "Aborting script."
	echo
	exit
	
fi 



echo
echo "Detecting scanner parameters..."
echo



##### Scanner
#- Ingenia
testINGENIA=`ls -1 *J2LF9B9* 2>/dev/null | wc -l`
if [ $testINGENIA -ne 0 ]; then
	echo "Detected scans from 1.5T Ingenia scanner." | tee -a log.txt
fi

#- NNU
testNNU=`ls -1 *ECA816E* 2>/dev/null | wc -l`
if [ $testNNU -ne 0 ]; then
	echo "Detected scans from 3T NNU scanner." | tee -a log.txt
fi



##### Download Source
#- ISDPACS
testPHILIPS=`ls -1 *PHILIPS* 2>/dev/null | wc -l`
if [ $testPHILIPS -ne 0 ]; then
	echo "Detected data downloaded from ISDPACS." | tee -a log.txt
	numPACKAGES=4
fi 

#- .RAW recon
testV4=`ls -1 *V4*.nii 2>/dev/null | wc -l`
if [ $testV4 -ne 0 ]; then
	echo "Detected data reconstructed from RAW files." | tee -a log.txt
fi 


##### Scan/Session Type
#- T2 ZOOM
testZOOM=`ls -1 *t2mb* 2>/dev/null | wc -l`
if [ $testZOOM -ne 0 ]; then
	echo "Detected T2 multi-band data." | tee -a log.txt
	echo "Warning: HARD-CODING SLICE THICKNESS = 2.2"
	echo "Detected Slice Thickness = '2.2'" | tee -a log.txt
	
	strFile=`ls *t2mb* | head -1`
	numPACKAGES=$(echo $strFile | sed -e 's|.*mi\(.*\)s.*|\1|')		#sed find  between "mi" and "s"
fi

#- T1
testT1=`ls -1 *t1* 2>/dev/null | wc -l` #t1 is from RAW recon
if [ $testT1 -ne 0 ]; then
	echo "Detected T1 data." | tee -a log.txt
	echo "Warning: HARD-CODING SLICE THICKNESS = 4"
	echo "Detected Slice Thickness = '4'" | tee -a log.txt
	
	strFile=`ls *t1* | head -1`
	numPACKAGES=$(echo $strFile | sed  's/sensep/&\n/;s/.*\n//;s/i/\n&/;s/\n.*//')	 #sed find  between "sensep" and "i"
fi

testT1=`ls -1 *T1* 2>/dev/null | wc -l`		#T1 from PACS
if [ $testT1 -ne 0 ]; then
	echo "Detected T1 data." | tee -a log.txt
	echo "Warning: HARD-CODING SLICE THICKNESS = 4"
	echo "Detected Slice Thickness = '4'" | tee -a log.txt
	
	strFile=`ls *T1* | head -1`
	numPACKAGES=$(echo $strFile | sed  's/p/&\n/;s/.*\n//;s/i/\n&/;s/\n.*//')	 #sed find  between "p" and FIRST MATCHING "i"
fi

#- PIP
testPIP=`ls -1 *pip* 2>/dev/null | wc -l`
if [ $testPIP -ne 0 ]; then
	echo "Detected PIP data." | tee -a log.txt
	
	strFile=`ls *pip* | head -1`
	numPACKAGES=$(echo $strFile | sed -e 's|.*p\(.*\)o.*|\1|')		#sed find  between "p" and "o"
fi

echo "Detected Number of Packages = '"$numPACKAGES"'" | tee -a log.txt









### Move Files to Patient Folder
#---------------------------------------------------------------------------------
if [ $testV4 -ne 0 ]; then
	mv *V4*.nii $path_fetalrep/$dayFolder/$patientFolder	
elif [ $testPHILIPS -ne 0 ]; then 
	mv *PHILIPS*.zip $path_fetalrep/$dayFolder/$patientFolder
	rm -r *PHILIPS* # removes any folders which were unzipped earlier
	
	# ### Extract the NIFTI files from the zip file
	# unzip *PHILIPS*.zip
	# rm *PHILIPS*.zip #An alternative here is to keep a copy
fi

# move log file
mv log.txt $path_fetalrep/$dayFolder/$patientFolder



### Script complete message
#---------------------------------------------------------------------------------
echo
echo "######################################################################"
echo "Script complete. Stacks saved to:"
echo $path_fetalrep/$dayFolder/$patientFolder
echo "######################################################################"
echo






