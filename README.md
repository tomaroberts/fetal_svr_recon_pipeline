# Interactive SVR reconstruction scripts

A collection of .sh/.bash wrapper scripts for use with the Image Registration Toolkit (IRTK) for volumetric reconstruction of multi-stack fetal brain data.

These scripts are highly specific to the network infrastructure in the Perinatal Imaging & Health department at KCL.

## Directories

__irtk_bin__ - IRTK binaries (not required if you already have IRTK installed)

__lib__ - libraries required by IRTK (not exhaustive)

__wip__ - work in progress

## Dependencies

__IRTK__ - slice-to-volume registration reconstruction software. Since superseded by MIRTK. Download IRTK here: [https://github.com/BioMedIA/IRTK](https://github.com/BioMedIA/IRTK).

__ITK-Snap__ - Image viewer used for creating brain mask. Download here: [http://www.itksnap.org/pmwiki/pmwiki.php](http://www.itksnap.org/pmwiki/pmwiki.php).

__rview__ - Image viewer which comes as part of IRTK. Required for align2atlas.sh script.

__PuTTY/Xming__ - Required if using Windows as local computer.

__WinSCP__ - Very handy FTP program if you are using Windows and need to move files across a network.

__Possibly more I've forgotten about...__

## Installation

Not straightforward to get running... 

If you are a member of PIH, see the included readme.txt for instructions on how to use.