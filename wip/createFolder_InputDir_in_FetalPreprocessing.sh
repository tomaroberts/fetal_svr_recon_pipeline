#!/bin/bash

### createFolder.sh
#
# Creates a folder in FetalPreprocessing named according to PatientID and scan date.
#
# - USAGE: 
# - Download data from ISDPACS / raw format and copy into the Input_Data folder
# - Run createFolder.sh
#
# - Asks the user to enter PatientID and scan date
# - Creates a folder based on this input in the format YYYY_MM_DD_PatientID
# - Determines datatype, ie: T1/T2/downloaded from ISDPACS/raw format
# - Copies the data to this folder ready for unpacking/SVR reconstruction
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
##################################################################################


### Path definition
#- path_input = put zip file from ISDPACS in this folder
#---------------------------------------------------------------------------------
#path_input=/pnraw01/FetalPreprocessing/FetalPreprocessing_TestEnviron/nnu/Reconstruction_Scripts
path_input=/pnraw01/FetalPreprocessing/Input_Data


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



### Create folder
#---------------------------------------------------------------------------------
cd .. #cd to FetalPreprocessing folder

patfold=$date_year"_"$date_month"_"$date_day"_"$patid1

if [[ ! -d "${patfold}" ]];then
	mkdir "$patfold"
	
	echo
	echo "Folder created with the name: "$patfold
	echo
elif [[ -d "${patfold}" ]];then

	echo
	echo "######################################################################"
	echo "Folder already exists with this Patient ID and date!"
	echo "To prevent overwriting any data, this script will exit."
	echo "Exiting script..."
	echo "######################################################################"
	echo
	exit
fi

#log.txt
cd $path_input
patpath=`pwd`
echo "Full Folder Path = '"$patpath"'" >> log.txt
echo "Folder Name = '"$patfold"'" >> log.txt







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
echo "Detecting..."
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

#- Raw recon
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
	mv *V4*.nii ../$patfold	
elif [ $testPHILIPS -ne 0 ]; then 
	mv *PHILIPS*.zip ../$patfold
	rm -r *PHILIPS* # removes any folders which were unzipped earlier
	
	# ### Extract the NIFTI files from the zip file
	# unzip *PHILIPS*.zip
	# rm *PHILIPS*.zip #An alternative here is to keep a copy
fi

cd ..
cd $patfold #Patient folder





### Copy scripts for completing the rest of the SVR Reconstruction pipeline
#---------------------------------------------------------------------------------
#-NB: Might be better to combine all of these into a single script at some point?

cd $path_input

mv log.txt ../$patfold
# cp createFolder.sh ../$patfold
# cp convert2stacks.sh ../$patfold
# cp drawMask.sh ../$patfold
# cp autoReconstruct.sh ../$patfold
# cp align2atlas.sh ../$patfold
# cp runReconPipeline.sh ../$patfold


### Script complete message
#---------------------------------------------------------------------------------
echo
echo "######################################################################"
echo "Script complete. Stacks saved to: "$patfold
echo "######################################################################"
echo






