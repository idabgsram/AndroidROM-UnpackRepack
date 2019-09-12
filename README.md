# Guzram Android ROM Unpack/Repack Tool

Welcome to Guzram Android ROM Unpack/Repack Tool!
Version : 0.3.4b

This simple tool is made to unpack/repack Android ROM (8.1+) on linux :)

===================================================================

# Requirements :

- A Linux Machine
- Make sure those package is installed in your machine :

p7zip-full python3

===================================================================

# Usage :

$ ./ur.sh <unpack/repack> <target-zip/dir> <outname-dir/zip>

unpack/repack : -u for Unpack , -r for Repack
target-zip/dir : Target ZIP file/path for unpack,  DIR Project name for Repack
outname-dir/zip : Custom Project DIR name for unpack, Output Custom ZIP name for repack

Supported ROM : Aonly ROM Type (META-INF+*.new.dat/.br)

# Example of Usage :

1. for Unpack :

$ ./ur.sh -u miui_LAVENDER_9.7.25_a70f3c63fa_9.0.zip miui

* unpacked ZIP will be generated in out/miui

2. for Repack :

$ ./ur.sh -r miui miui_LAVENDER_9.7.25_a70f3c63fa_9.0_repack.zip

* repacked out/miui will generated in out/<customzipname>.zip

===================================================================

This tool might still have some issues, as it's still in beta stage.

Thanks to brotli, simg2img / img2simg, and sdat2img/img2sdat developer.
