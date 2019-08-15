#!/bin/csh

set targetExe = "ems combineLabels labelStats rreg areg nreg pareg pnreg prreg sareg snreg srreg motiontrack transformation stransformation ptransformation jacobian atlas dmap dof2flirt dof2image dof2mat dofinvert evaluation flirt2dof info image2dof convert threshold binarize mcubes padding blur dilation dmap erosion closing makesequence opening reflect region resample rescale rview"

set targetDir = "irtk"

mkdir -p $targetDir

foreach f ( $targetExe )
   
   echo "Copying $f to directory $targetDir"
   cp /home/tr17/irtk_cardiac4d_build/bin/$f $targetDir

end

cp /home/tr17/fetal_cmr_4d/irtk_cardiac4d/README $targetDir
cp /home/tr17/fetal_cmr_4d/irtk_cardiac4d/COPYRIGHT $targetDir

if ( `uname` == "Linux" ) then

   tar czvf irtk-linux-64.tar.gz $targetDir

else

   hdiutil create -srcfolder $targetDir irtk-mac-64.dmg

endif
