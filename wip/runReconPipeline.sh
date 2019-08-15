#!/bin/bash

### Wrapper to run ALL reconstruction scripts, one after another.

# Download .zip from ISDPACS
# Run this script in the folder containing the NIFTI folders

chmod u+x createFolder.sh convert2stacks.sh drawMask.sh autoReconstruct.sh align2atlas.sh

./createFolder.sh

#- Move to Patient Folder ,
#- Erase log.txt from Input_Data so there are no leftovers
currDir=`pwd`
patpath=$(grep -F "Full Folder Path =" log.txt | awk -F "'" '{print $2}')
rm log.txt
cd $patpath

./convert2stacks.sh
./drawMask.sh
./autoReconstruct.sh
./align2atlas.sh