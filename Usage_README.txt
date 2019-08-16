### Readme for automated SVR reconstruction scripts.
#
# Scripts by Tom Roberts, Maximilian Pietsch, KCL
#
# --- 16/08/2019 - version 2.0.
# - Updates:
# - Input_Data is in user area
# - Reconstructions can be performed on either gpubeastie01-pc / beastie01 / beastie02
#
# --- 13/03/2018 - version 1.0.
#
######################################################################################################

USAGE NOTE:
	This readme is written with Windows users in mind.
	If you are a Linux user, you can skip PuTTY/Xming/WinSCP.
	
	The scripts are interactive so should guide you through the reconstruction process as you go.


REQUIREMENTS:
	1) PuTTY for Windows --- https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
	2) Xming Mesa (warning: automatic download) --- https://sourceforge.net/projects/xming/files/Xming-mesa/6.9.0.31/Xming-mesa-6-9-0-31-setup.exe/download
	3) WinSCP (optional, but good) --- https://winscp.net/eng/download.php
	4) User account on gpubeastie01-pc. Ask IT for access if you don't have an account
	5) Scripts added to your user PATH. Easiest way to do this:
	
		cd ~/
		echo "export PATH=$PATH:/pnraw01/FetalPreprocessing/bin" >> ~/.profile
		
		This creates a .profile file in your home directory. You may need to re-login to gpubeastie01-pc for it to work.
		
SCRIPT NOTES:
	1) drawMask.sh:
		- This script uses ITKSNAP, located in: FetalPreprocessing/itksnap-3.4.0-20151130-Linux-x86_64-qt4
		- Note: this is the qt4 version which has better compatibility with Xming
	2) align2atlas.sh:
		- This script uses Fetal Atlases, located in: /pnraw01/FetalPreprocessing/fetalAtlas
	3) rview can be called to inspect data, ie: after running convert2stacks.sh, you can view individual stacks by typing:
		rview stack1.nii.gz     
	   etc, depending on stack number.
		
		
SCRIPT USAGE:
	1) Download data from ISDPACS/raw drive
	2) Copy data to Input_Data folder in your user area using WinSCP
	3) Open PuTTY and and log in to gpubeastie01-pc.
	4) Navigate to the Input_Data folder in your user area and run:
		createFolder.sh
	   This creates a folder in: /pnraw01/FetalPreprocessing/YYYY_MM_DD/PatientID
	5) Navigate to the new folder:
		cd /pnraw01/FetalPreprocessing/YYYY_MM_DD/PatientID
	6) Run:
		convert2stacks.sh
	7) Run:
		drawMask.sh
	   When you save the mask, make sure the filename contains the word "mask", for later scripts.
	8) Run:
		autoReconstruct.sh		
	9) If reconstructing T2 data, run:
		align2atlas.sh
		
	The final SVR volume should be called outputSVR_FINAL.nii.gz.
	
		
		
		
