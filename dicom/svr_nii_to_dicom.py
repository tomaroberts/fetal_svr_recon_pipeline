### Create 3D SVR volume DICOM
# Converts 3D Nifti file into single-frame Dicom files

# INPUT:
# - 3D SVR .nii file
# - M2D Dicom for header information

# OUTPUT:
# - 3D SVR Dicom


### Dependencies
import os
import numpy as np
import numpy.matlib
import nibabel as nib
import matplotlib
import matplotlib.pyplot as plt

from __future__ import unicode_literals  # Only for python2.7 and save_as unicode filename
import pydicom
from pydicom.dataset import Dataset, FileDataset, FileMetaDataset
from pydicom.datadict import DicomDictionary, keyword_dict
from pydicom.sequence import Sequence


### File admin
reconDir = r'C:\Users\tr17\Dropbox\2019_11_08_T2_SVR\dcm'

# Template Dicom
dcmFile = r'295_fetalCMR_201911081253_PHILIPSJ2LF9B9_601_PIH1T2_brain_traSENSE_001.dcm'

# 3D SVR Nifti
svrFile = r'SVR-output-brain.nii.gz'


### Load Template Dicom
os.chdir(reconDir)
ds_tmp = pydicom.dcmread(dcmFile)

### Import Nifti Files, Preprocess for Dicom Conversion

svr_nii = nib.load(svrFile)
svr_img = svr_nii.get_fdata()

nX = svr_img.shape[0]
nY = svr_img.shape[1]
nZ = svr_img.shape[2]
nF = svr_img.shape[3]

dimX = svr_nii.header['pixdim'][1]
dimY = svr_nii.header['pixdim'][2]
dimZ = svr_nii.header['pixdim'][3]
dimF = svr_nii.header['pixdim'][4]

print("Shape of SVR nifti:", svr_img.shape)
print("pixdim [mm, mm, mm, seconds]:", [dimX, dimY, dimZ, dimF])

# set background pixels = 0 (-1 in SVRTK)
iBkrd = svr_img==-1; svr_img[iBkrd] = 0

# convert to same datatype as DICOM
svr_img = svr_img.astype("uint16")

# Number of files to create
numInstances = nZ*nF

print("End of svr_nii_to_dicom.py ... ")
