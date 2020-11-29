### --- Create 3D SVR volume DICOM
# Converts 3D Nifti file into single-frame Dicom files

# INPUT:
# - 3D SVR .nii file
# - M2D Dicom for header information

# OUTPUT:
# - 3D SVR Dicom
#
######################################################



### --- Dependencies
import os
import numpy as np
import numpy.matlib
import nibabel as nib
import matplotlib
import matplotlib.pyplot as plt

import pydicom
from pydicom.dataset import Dataset, FileDataset, FileMetaDataset
from pydicom.datadict import DicomDictionary, keyword_dict
from pydicom.sequence import Sequence


### --- File admin
reconDir  = r'/home/data/SVR'
inputDir  = r'/home/data/DICOM'

# Output dicom folder
dcmOutputDir = os.path.join(reconDir, 'dcm-svr')
if not os.path.exists(dcmOutputDir):
    os.makedirs(dcmOutputDir)

# Template dicom
# old --- dcmFile = r'stack1.dcm'
dcmFile = os.path.join(inputDir, 'IM_0001')

# 3D SVR Nifti
svrFile = os.path.join(reconDir, 'SVR-output-brain.nii.gz')


### --- Load Template Dicom
os.chdir(reconDir)
ds_tmp = pydicom.dcmread(dcmFile)


### --- Import Nifti Files, Preprocess for Dicom Conversion

svr_nii = nib.load(svrFile)
svr_img = svr_nii.get_fdata()

nX = svr_img.shape[0]
nY = svr_img.shape[1]
nZ = svr_img.shape[2]
nF = 1 # SVR is single dynamic

dimX = svr_nii.header['pixdim'][1]
dimY = svr_nii.header['pixdim'][2]
dimZ = svr_nii.header['pixdim'][3]

print("Shape of SVR nifti:", svr_img.shape)
print("pixdim [mm, mm, mm, seconds]:", [dimX, dimY, dimZ])

# set background pixels = 0 (-1 in SVRTK)
iBkrd = svr_img==-1; svr_img[iBkrd] = 0

# convert to same datatype as DICOM
svr_img = svr_img.astype("uint16")

# Number of files to create
numInstances = nZ*nF


### --- Create Parameter Arrays

# slice array
sliceIndices = range(1, nZ+1)
sliceIndicesArray = np.repeat(sliceIndices, nF)

# slice locations array
voxelSpacing = 1.25
zLocLast = (voxelSpacing * nZ) - voxelSpacing
sliceLoca = np.linspace(0, zLocLast, num=nZ)
sliceLocaArray = np.repeat(sliceLoca, nF)


### --- dcm Initialise

def dcm_initialise():
    
    ### This function based on pydicom codify output
    
    # File meta info data elements
    file_meta = Dataset()
    # file_meta.FileMetaInformationGroupLength = 194 ### REQUIRES DEFINITION
    file_meta.FileMetaInformationVersion = b'\x00\x01'
    file_meta.MediaStorageSOPClassUID = '1.2.840.10008.5.1.4.1.1.4'
    # file_meta.MediaStorageSOPInstanceUID = '1.2.40.0.13.1.75591523476291404472265359935487530723' ### REQUIRES DEFINITION
    file_meta.TransferSyntaxUID = '1.2.840.10008.1.2'
    file_meta.ImplementationClassUID = '1.2.276.0.7230010.3.0.3.6.1'
    file_meta.ImplementationVersionName = 'PERINATAL_CUSTOM_PYDICOM'

    # Main data elements
    ds = Dataset()
    ds.SpecificCharacterSet = 'ISO_IR 100'
    # ds.ImageType = ['ORIGINAL', 'PRIMARY', 'M_FFE', 'M', 'FFE'] ### REQUIRES DEFINITION
    ds.InstanceCreationDate = ''
    ds.InstanceCreationTime = ''
    ds.InstanceCreatorUID = '1.2.40.0.13.1.203399489339977079628124438700844270739' ### TODO: determine if required
    ds.SOPClassUID = '1.2.840.10008.5.1.4.1.1.4'
    # ds.SOPInstanceUID = '1.2.40.0.13.1.75591523476291404472265359935487530723' ### REQUIRES DEFINITION
    ds.StudyDate = ''
    ds.SeriesDate = ''
    ds.AcquisitionDate = ''
    ds.ContentDate = ''
    ds.StudyTime = ''
    ds.SeriesTime = '' # '182511.32000'
    ds.AcquisitionTime = '' # '182511.32'
    ds.ContentTime = '' # '182511.32'
    ds.AccessionNumber = ''
    ds.Modality = 'MR'
    ds.Manufacturer = 'Philips Healthcare'
    ds.CodeValue = ''
    ds.CodingSchemeDesignator = 'DCM'
    ds.CodeMeaning = ''

    # Procedure Code Sequence
    procedure_code_sequence = Sequence()
    ds.ProcedureCodeSequence = procedure_code_sequence

    # Procedure Code Sequence: Procedure Code 1
    procedure_code1 = Dataset()
    procedure_code1.CodeValue = '' # 'RA.MRAAOT'
    procedure_code1.CodingSchemeDesignator = '' # '99ORBIS'
    procedure_code1.CodeMeaning = '' # 'CE-MRA Aorta thorakal'
    procedure_code1.ContextGroupExtensionFlag = 'N'
    procedure_code_sequence.append(procedure_code1)

    ds.OperatorsName = ''
    ds.AdmittingDiagnosesDescription = ''
    ds.ManufacturerModelName = 'Ingenia'

    # Referenced Performed Procedure Step Sequence
    refd_performed_procedure_step_sequence = Sequence()
    ds.ReferencedPerformedProcedureStepSequence = refd_performed_procedure_step_sequence

    # Referenced Performed Procedure Step Sequence: Referenced Performed Procedure Step 1
    refd_performed_procedure_step1 = Dataset()
    refd_performed_procedure_step1.InstanceCreationDate = ''
    refd_performed_procedure_step1.InstanceCreationTime = ''
    refd_performed_procedure_step1.InstanceCreatorUID = '1.2.40.0.13.1.203399489339977079628124438700844270739' ### TODO: determine if required
    refd_performed_procedure_step1.ReferencedSOPClassUID = '1.2.840.10008.3.1.2.3.3'
    refd_performed_procedure_step1.ReferencedSOPInstanceUID = '1.3.46.670589.11.17204.5.0.6524.2012082117320696006'
    refd_performed_procedure_step1.InstanceNumber = "0"
    refd_performed_procedure_step_sequence.append(refd_performed_procedure_step1)


    # Referenced Image Sequence
    refd_image_sequence = Sequence()
    ds.ReferencedImageSequence = refd_image_sequence

    # Referenced Image Sequence: Referenced Image 1
    refd_image1 = Dataset()
    refd_image1.ReferencedSOPClassUID = '1.2.840.10008.5.1.4.1.1.4'
    refd_image1.ReferencedSOPInstanceUID = '1.2.40.0.13.1.89078282904346598403696206113943676723'
    refd_image_sequence.append(refd_image1)

    # Referenced Image Sequence: Referenced Image 2
    refd_image2 = Dataset()
    refd_image2.ReferencedSOPClassUID = '1.2.840.10008.5.1.4.1.1.4'
    refd_image2.ReferencedSOPInstanceUID = '1.2.40.0.13.1.295129673873169057216869911833080985343'
    refd_image_sequence.append(refd_image2)

    # Referenced Image Sequence: Referenced Image 3
    refd_image3 = Dataset()
    refd_image3.ReferencedSOPClassUID = '1.2.840.10008.5.1.4.1.1.4'
    refd_image3.ReferencedSOPInstanceUID = '1.2.40.0.13.1.37560432539838529536104187971339317428'
    refd_image_sequence.append(refd_image3)

    ds.PatientName = 'Not Specified'
    ds.PatientID = 'Not Specified'
    ds.PrivateCreator = 'Philips Imaging'
    ds.IssuerOfPatientID = ''
    ds.PatientBirthDate = ''
    ds.OtherPatientIDs = ''
    ds.OtherPatientNames = ''
    ds.PatientMotherBirthName = ''
    # ds.PregnancyStatus = 4
    ds.ScanningSequence = 'kt bFFE' # 'GR'
    ds.SequenceVariant = '' # 'SP'
    ds.ScanOptions = '' # 'FC'
    ds.MRAcquisitionType = '3D'
    ds.SequenceName = ''
    ds.SliceThickness = ''
    ds.RepetitionTime = "3.8"
    ds.EchoTime = "1.9"
    ds.NumberOfAverages = "1"
    ds.ImagingFrequency = "127.768401"
    ds.ImagedNucleus = '1H'
    ds.EchoNumbers = "1"
    ds.MagneticFieldStrength = "1.5"
    ds.SpacingBetweenSlices = ""
    ds.NumberOfPhaseEncodingSteps = "" # "143"
    ds.EchoTrainLength = "" # "3"
    ds.PercentSampling = "" # "98.4375"
    ds.PercentPhaseFieldOfView = "" # "86.4864871376439"
    ds.PixelBandwidth = "" # "3284"
    ds.SoftwareVersions = ['5.1.7', '5.1.7.2']
    ds.ProtocolName = 'Not Specified' 
    # ds.TriggerTime = "622" ### REQUIRES DEFINITION
    # ds.LowRRValue = "632" # Not sure if needed
    # ds.HighRRValue = "733" # Not sure if needed
    ds.IntervalsAcquired = "" # "1132"
    ds.IntervalsRejected = "" # "20"
    ds.HeartRate = ""
    ds.ReconstructionDiameter = "" # "379.999992370605"
    ds.ReceiveCoilName = 'MULTI COIL'
    ds.TransmitCoilName = 'B'
    # ds.AcquisitionMatrix = [0, 148, 143, 0] # TODO: Determine if required
    ds.InPlanePhaseEncodingDirection = '' # 'ROW'
    ds.FlipAngle = "60"
    ds.SAR = ""
    ds.dBdt = ""
    ds.PatientPosition = '' # 'HFS' TODO: Determine if important/required
    # ds.AcquisitionDuration = 459.6679992675781 # TODO: Determine if important/required
    ds.DiffusionBValue = 0.0
    ds.DiffusionGradientOrientation = [0.0, 0.0, 0.0]
    ds.StudyInstanceUID = '1.2.40.0.13.1.333311361771566580913219583914625766216' # TODO: determine if needs generating
    ds.SeriesInstanceUID = '1.2.40.0.13.1.286595144572817015845933344548631223145' # TODO: determine if needs generating
    ds.StudyID = '513842.201207030' # TODO: determine if needs generating
    ds.SeriesNumber = ""
    ds.AcquisitionNumber = "" # "10"
    # ds.InstanceNumber = "319" ### REQUIRES DEFINITION
    # ds.ImagePositionPatient = ['-56.040032677094', '-189.81796011867', '225.026188065538'] ### REQUIRES DEFINITION
    # ds.ImageOrientationPatient = ['0.51319164037704', '0.85772150754928', '-0.0307911429554', '-0.0599991045892', '6.4554493292E-05', '-0.9981984496116'] ### TODO: decide if need to match Nifti affine
    ds.FrameOfReferenceUID = '1.2.40.0.13.1.168070265634523572089252568290704983898' # TODO: determine if required
    ds.TemporalPositionIdentifier = "" # "1"
    ds.NumberOfTemporalPositions = "" # "1"
    ds.PositionReferenceIndicator = ''
    # ds.SliceLocation = "38.9999961150011" ### REQUIRES DEFINITION
    ds.SamplesPerPixel = 1
    ds.PhotometricInterpretation = 'MONOCHROME2'
    # ds.Rows = 192 ### REQUIRES DEFINITION
    # ds.Columns = 192 ### REQUIRES DEFINITION
    # ds.PixelSpacing = ['1.97916662693023', '1.97916662693023'] ### REQUIRES DEFINITION
    ds.BitsAllocated = 16
    ds.BitsStored = 12
    ds.HighBit = 11
    ds.PixelRepresentation = 0
    # ds.WindowCenter = "213.04" ### REQUIRES DEFINITION
    # ds.WindowWidth = "370.49" ### REQUIRES DEFINITION
    ds.LossyImageCompression = '00'
    ds.RequestingPhysician = ''
    ds.RequestingService = ''
    ds.RequestedProcedureDescription = 'FCMR 4D FLOW MRI'
    ds.PerformedStationAETitle = ''
    ds.PerformedProcedureStepStartDate = '' # '20120821'
    ds.PerformedProcedureStepStartTime = '' # '173207'
    ds.PerformedProcedureStepEndDate = '' # '20120821'
    ds.PerformedProcedureStepEndTime = '' # '173207'
    ds.PerformedProcedureStepID = '' # '398712726'
    ds.PerformedProcedureStepDescription = '' # 'CE-MRA Aorta thorakal'

    # Performed Protocol Code Sequence
    performed_protocol_code_sequence = Sequence()
    ds.PerformedProtocolCodeSequence = performed_protocol_code_sequence

    # Performed Protocol Code Sequence: Performed Protocol Code 1
    performed_protocol_code1 = Dataset()
    performed_protocol_code1.CodeValue = '' # 'RA.MRAAOT'
    performed_protocol_code1.CodingSchemeDesignator = '' # '99ORBIS'
    performed_protocol_code1.CodeMeaning = '' # 'CE-MRA Aorta thorakal'
    performed_protocol_code1.ContextGroupExtensionFlag = 'N'
    performed_protocol_code_sequence.append(performed_protocol_code1)

    # Film Consumption Sequence
    film_consumption_sequence = Sequence()
    ds.FilmConsumptionSequence = film_consumption_sequence

    ds.RequestedProcedureID = '513842.201207030'

    # Real World Value Mapping Sequence
    real_world_value_mapping_sequence = Sequence()
    ds.RealWorldValueMappingSequence = real_world_value_mapping_sequence

    # Real World Value Mapping Sequence: Real World Value Mapping 1
    real_world_value_mapping1 = Dataset()
    real_world_value_mapping1.RealWorldValueIntercept = 0.0
    real_world_value_mapping1.RealWorldValueSlope = 0.0 # 4.280830280830281
    real_world_value_mapping_sequence.append(real_world_value_mapping1)

    ds.PresentationLUTShape = 'IDENTITY'

    return file_meta, ds
	
	
### Create 3D SVR Dicoms
file_meta, ds = dcm_initialise()

# Update Fixed Attributes
ds.PatientName = ds_tmp.PatientName
ds.ProtocolName = ds_tmp.ProtocolName
ds.SeriesNumber = "2001"
ds.ImageType = ds_tmp.ImageType
ds.Rows = nX
ds.Columns = nY
ds.SliceThickness = str(voxelSpacing)
ds.ImageOrientationPatient = ['1','0','0','0','1','0'] # axial. TODO: update to match Nifti
ds.PixelSpacing = [str(voxelSpacing), str(voxelSpacing)]
ds.SpacingBetweenSlices = str(voxelSpacing)  
# ds.WindowCenter = "0" # TODO: determine these from pixel_data
# ds.WindowWidth = "0.5"
# real_world_value_mapping1.RealWorldValueIntercept = 0.0
# real_world_value_mapping1.RealWorldValueSlope = 1
ds.PresentationLUTShape = 'IDENTITY'


iFileCtr = 0

# Update Instance-wise Attributes
for iImage in range(0,nZ):
    
    iFileCtr = iFileCtr + 1    
    iInst  = iImage + 1
    iSlice = sliceIndicesArray[iInst-1]
    sliceLocation = sliceLocaArray[iInst-1]
    
    # Define Instance UIDs
    randomSOPInstanceUID = pydicom.uid.generate_uid(None)
    file_meta.MediaStorageSOPInstanceUID = randomSOPInstanceUID
    ds.SOPInstanceUID = randomSOPInstanceUID
    
    # Update Spatial/Temporal Attributes
    ds.InstanceNumber = str(int(iInst)) # Altered to reflect one frame
    ds.ImagePositionPatient = [str(-1),str(-1),str(sliceLocation)] # TODO: update with centre coord of slice, i.e: -100, -100, -50
    ds.SliceLocation = str(sliceLocation)
    ds.SliceNumberMR = int(iSlice)

    # Create Pixel Data
    ds.PixelData = svr_img[:,:,iImage].tobytes()
    ds.file_meta = file_meta
    ds.is_implicit_VR = True
    ds.is_little_endian = True
    ds.save_as(os.path.join(dcmOutputDir, 'IM_%04d'%(iFileCtr)), write_like_original=False)


### --- Output Messages
print('DICOM files written to:', dcmOutputDir)
print('SVR 3D DICOM creation complete.')


