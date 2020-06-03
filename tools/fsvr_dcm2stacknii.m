%% DICOM to SVR volume
% 
% feeder script to convert DCM files to .nii files for SVR reconstruction
% - typically use for datasets sent from other institutions
%
% USAGE:
% - currently a script, therefore update the following appropriately:
% --- dicomDir / niiStr / niiExt / seriesNos
%
% OUTPUT:
% - stacks saved as individual dynamics in the format stack1.nii.gz,
% stack2.nii.gz, stack3.nii.gz, etc.
%
%
% Tom Roberts (t.roberts@kcl.ac.uk)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% STEP 1)
% - Convert DICOMs to .nii files
% - Use dcm2niix within mricrogl package: https://www.nitrc.org/projects/mricrogl

%% STEP 2)
% - Rename / save DICOMs to stack*.nii.gz
% - This form is compatible with Perinatal SVR bash scripts
% - Note, will probably need to view the .nii stacks to establish which are
% relevant, ie: T2 rather than pilot scans, etc.

% TODO: scrape the .json files to automatically find the relevant seriesNos

dicomDir = 'C:\Users\tr17\Documents\Projects\Misc\2019_10_01_SVR_recon_for_Mary\DICOM\0000A444\AA7FD04E\AA30AD7C';
cd(dicomDir);

niiStr = '20190929132513_anonymous_';
niiExt = '01.nii.gz';

seriesNos = [9, 11, 12];
stackCtr  = 1;

for seriesNo = seriesNos
    
    niiFullStr = [niiStr num2str(seriesNo) niiExt];
    
    nii  = niftiread(niiFullStr);
    info = niftiinfo(niiFullStr);
    
    % adjust header to reflect single dynamic
    info.raw.dim(1) = 3;
    info.raw.dim(5) = 1;
    info.raw.pixdim(5) = 0;
    info.raw.xyzt_units = 2; % mm only, ie: no temporal unit

    info.ImageSize(4) = [];
    info.PixelDimensions(4) = [];
    info.TimeUnits = 'None';
    
    % save each dynamic separately
    for ii = 1:size(nii,4)
        
        % write
        niftiwrite( nii(:,:,:,ii), ['SVR_recon/stack' num2str(stackCtr)], info, 'Compressed', true );

        stackCtr = stackCtr + 1;
        
    end
    
end


