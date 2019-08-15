#!/bin/bash

### drawMask.sh
#
# - USAGE: 
# - Run drawMask.sh in patient folder
#
# - Opens ITKSnap to enable user to draw mask.
# - Make sure mask filename contains string "mask" for compatibility with rest of pipeline
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
#####################################################################################


### Open ITK-SNAP for creating a mask
#---------------------------------------------------------------------------------

echo
echo "-------------------------------"
echo Create mask and save it as mask.nii.gz
echo "-------------------------------"
echo

### Ask which stack to draw mask
#---------------------------------------------------------------------------------
numStacks=`ls stack* | wc -l`

echo "There are "$numStacks "stacks."
echo "Which stack would you like to draw the mask on?"
echo "Type in the number [1-"$numStacks"] followed by [ENTER]:"
read chosenStackNumber


### Check to see if specified stack actually exists.
if [ $chosenStackNumber -lt 1 ];then
	echo
	echo "###################################################"
	echo "Stack does not exist. Please run this script again."
	echo "###################################################"	
	echo
	exit
elif [ $chosenStackNumber -gt $numStacks ];then
	echo
	echo "###################################################"
	echo "Stack does not exist. Please run this script again."
	echo "###################################################"	
	echo
	exit
fi


### Open ITK-SNAP for drawing mask
#---------------------------------------------------------------------------------
itksnap=/pnraw01/FetalPreprocessing/itksnap-3.4.0-20151130-Linux-x86_64-qt4/bin/itksnap
$itksnap stack$chosenStackNumber.nii.gz


### Provide user with list of mask filenames in folder
#---------------------------------------------------------------------------------
echo
echo "-------------------------------"
echo "Detected the following masks in the folder:"
ls -1 *mask*.nii*
echo "-------------------------------"
echo
