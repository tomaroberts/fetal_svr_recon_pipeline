### Readme for automated SVR reconstruction scripts.
#
# Scripts by Tom Roberts, KCL (March 2018)
#
# --- 13/03/2018
# - version 1.0.
#
######################################################################################################

REQUIREMENTS:
	1) PuTTY for Windows --- https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
	2) Xming Mesa (warning: automatic download) --- https://sourceforge.net/projects/xming/files/Xming-mesa/6.9.0.31/Xming-mesa-6-9-0-31-setup.exe/download
	3) WinSCP (optional, but good) --- https://winscp.net/eng/download.php
	4) User account on gpubeastie01-pc. Ask IT for access if you don't have an account
	5) Scripts added to your user PATH. Easiest way to do this:
	
		cd ~/
		echo "export PATH=$PATH:/pnraw01/FetalPreprocessing/bin" >> ~/.profile
		
		This creates a .profile file in your home directory. You may need to re-login to gpubeastie01-pc for it to work.
		
NOTES:
	1) drawMask.sh ITKSNAP, located in: FetalPreprocessing/itksnap-3.4.0-20151130-Linux-x86_64-qt4
		- Note: this is the qt4 version which has better compatibility with Xming
	2) align2atlas.sh script uses Fetal Atlases, located in: /pnraw01/FetalPreprocessing/fetalAtlas
	3) rview can be called to inspect data, ie: after running convert2stacks.sh, you can view individual stacks by typing:
		rview stack1.nii.gz      
	   etc, depending on stack number.
		
		
SCRIPT USAGE:
	1) Download data from ISDPACS/raw drive
	2) Copy data to /pnraw01/FetalPreprocessing/Input_Da/ta using WinSCP
	3) Navigate to /pnraw01/FetalPreprocessing/Input_Data and run:
		createFolder.sh
	   This creates a folder in FetalPreprocessing in the form PatientID_YYYY_MM_DD
	4) Navigate to the new folder, ie:
		cd ../PatientID_YYYY_MM_DD
	5) Run:
		convert2stacks.sh
	6) Run:
		drawMask.sh
	   When you save the mask, make sure the filename contains the word "mask", for later scripts.
	7) Run:
		autoReconstruct.sh
	8) If reconstructing T2 data, run:
		align2atlas.sh
		
	The final SVR volume should be called outputSVR_FINAL.nii.gz.
	
		
		
		
