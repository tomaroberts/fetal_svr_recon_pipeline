#!/bin/bash

### align2atlas.sh
#
# Aligns SVR volume to Fetal Atlas
#
# - USAGE: 
# - Run align2atlas.sh in patient folder
#
# - Uses rview to align SVR reconstructed volume to Atlas
#
# --- NB: currently only works with T2 data, as we only have T2 atlases
#
# - Tom Roberts, KCL, January 2018
# - t.roberts@kcl.ac.uk
#
#####################################################################################


echo
echo "-------------------------------"
echo "ALIGN TO ATLAS"
echo "-------------------------------"
echo

fetalAtlasPath=/pnraw01/FetalPreprocessing/TomFetalRep/fetalAtlas

### Ask user for GA
#---------------------------------------------------------------------------------
echo "Please type the Gestational Age (GA) of the fetus (rounded to nearest number), followed by [ENTER]:"
read ga

#mkdir aligned
#cd aligned

### Run headertool
#---------------------------------------------------------------------------------
headertool outputSVRvolume.nii.gz outputSVRvolume.nii.gz -origin 0 0 0 


### Align SVR volume to fetal atlas
#---------------------------------------------------------------------------------
echo "-------------------------------------------"
echo "Manually reorient and Save As man-orient.dof"
echo "-------------------------------------------"

rview $fetalAtlasPath/GA$ga.nii.gz outputSVRvolume.nii.gz
rreg $fetalAtlasPath/GA$ga.nii.gz outputSVRvolume.nii.gz -dofin man-orient.dof -dofout orient.dof

echo "-------------------------------------------"
echo "Check that the registration worked."
echo "-------------------------------------------"
echo

rview $fetalAtlasPath/GA$ga.nii.gz outputSVRvolume.nii.gz orient.dof
transformation outputSVRvolume.nii.gz outputSVRvolume_FINAL.nii.gz -target $fetalAtlasPath/GA$ga.nii.gz -dofin orient.dof -linear -Sp -1

echo "------------------------------------------"
echo "View the final volume."
echo "-------------------------------------------"
echo

rview outputSVRvolume_FINAL.nii.gz
