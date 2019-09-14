#/bin/bash
#
# 2019 Guzram Android Project. 
# Created : 2019-09-12
#

locdir=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
date=`date +%Y%m%d`
datesec=`date +%H%M%S`
script_ver=0.3.4b
script_codename=ilopyou
BUILD_START=$(date +"%s")
FungTion=unknown
toolsdir="$locdir/tools"
brotli_legacy="$toolsdir/brotli"
simg2img="$toolsdir/simg2img"
img2simg="$toolsdir/img2simg"
sdat2img="$toolsdir/sdat2img.py"
img2sdat="$toolsdir/img2sdat.py"

echo "Welcome to Guzram Android ROM Unpack/Repack Tools"
echo "ver: $script_ver - codename: $script_codename"
shopt -s extglob

usage()
{
	echo ""
	echo "Usage: $0 <unpack/repack> <target-zip/dir> <outname-dir/zip>"
    echo -e "\tunpack/repack : -u for Unpack , -r for Repack"
    echo -e "\ttarget-zip/dir : Target ZIP file/path for unpack,  DIR Project name for Repack"
    echo -e "\toutname-dir/zip : Custom Project DIR name for unpack, Output Custom ZIP name for repack"
    echo -e ""
    echo "Supported ROM : Aonly ROM Type (META-INF+*.new.dat/.br)"
}

help()
{
	echo ""
	echo "Use --help for this tool usage."
}


extract_rom() {
	romzip=$1
	outdir=$2

	if [[ ! $(7z l -ba $romzip | grep "system.new.dat\|META-INF") ]]; then
	    echo "This type of ROM isn't supported"
	    rm -rf "$outdir"
	    exit 1
	fi

	echo "Extracting ROM on: $outdir"
	mkdir $outdir/logs
	logs=$outdir/logs
	cd $outdir
	mkdir $outdir/romdata
	romdata=$outdir/romdata
	echo $(7z l -ba $romzip | rev | gawk '{ print $1 }' | rev) > $romdata/zip_list.txt
    7z x -y $romzip 2>/dev/null >> $logs/zip.log
    outputs=$(ls)
    for output in $outputs; do
        if [[ -f $output.new.dat.1 ]]; then
            cat $output.new.dat.{0..999} 2>/dev/null >> $output.new.dat
            rm -rf $output.new.dat.{0..999}
        fi
    done
        ls | grep "\.new\.dat" | while read i; do
            line=$(echo "$i" | cut -d"." -f1)
            if [[ $(echo "$i" | grep "\.dat\.xz") ]]; then
                7z x -y "$i" 2>/dev/null >> $logs/unpack.log
                rm -rf "$i"
            fi
            if [[ $(echo "$i" | grep "\.dat\.br") ]]; then
                echo "Decompressing brotli $i file"
                brotli -d "$i"
                echo "$i" >> $romdata/br_list.txt
                rm -f "$i"
            fi
            echo "Unpacking $i ..."
            python3 $sdat2img $line.transfer.list $line.new.dat "$outdir"/$line.img > $logs/extract.log
            rm -rf $line.transfer.list $line.new.dat $line.patch.dat
            echo "$line" >> $romdata/pack_list.txt
        done
}

repack_rom() {
	romdir=$1
	outzip=$2
	romdata=$romdir/romdata
	packlist=$(cat $romdata/zip_list.txt)
	echo "Repacking ROM on: $romdir"
	if [ ! -d $romdir/logs ]; then
		mkdir $romdir/logs
	fi
	logs=$romdir/logs
	cd $romdir
	outputs=$(ls)
    for output in $outputs; do
    	outimg="${output/.img/}"
    	PackListX=$(cat $romdata/pack_list.txt|grep $outimg)
	    	if [ "$PackListX" != "" ]; then
	    		echo "Compressing $output..."
		    	if [[ -f $outimg.img ]]; then
		            $img2simg $outimg.img "$outimg"_sparse.img 2>/dev/null >> $logs/repack.log
		            rm -rf $outimg.img
		            python3 $img2sdat -v 4 -p $outimg "$outimg"_sparse.img 2>/dev/null >> $logs/repack.log
		            rm -rf "$outimg"_sparse.img
		            if [ -f $romdata/br_list.txt ]; then
		            	isMatch=$(cat $romdata/br_list.txt|grep $outimg)
		            	if [ "$isMatch" != "" ]; then
		            		echo "Compressing $output to brotli..."
		            		brotli --quality=6 $outimg.new.dat
		            		rm -rf $outimg.new.dat
		            	fi
		            fi
		        fi
		    fi
    done
    echo "Zipping..."
    7z a $outzip $packlist 2>/dev/null >> $logs/repackzip.log
}

if [ "$1" == "--help" ]; then
	usage
	exit 1
fi

if [ "$1" == "" ]; then
	help
	exit 1
fi

if [ "$2" == "" ]; then
	echo "Parameter not meet, please check the --help for usage"
	exit 1
fi

if [ "$1" == "-u" ]; then
	FungTion=unpack
elif [ "$1" == "-r" ]; then
	FungTion=repack
else
	echo "Parameter : $1 isnt supported -_-"
	exit 1
fi

if [ "$FungTion" == "unpack" ]; then

	if [ ! -f $2 ]; then
		echo "Target isnt a valid file. Cannot continue."
		exit 1
	fi

	if [ "$3" == "" ]; then
		if [ ! -d $locdir/out ]; then
			mkdir $locdir/out
		fi
		rm -rf $locdir/out/$date-$datesec
		mkdir $locdir/out/$date-$datesec
		out_zip=$locdir/out/$date-$datesec
	else
		rm -rf $locdir/out/$3
		if [ ! -d $locdir/out ]; then
			mkdir $locdir/out
		fi
		mkdir $locdir/out/$3
		out_zip=$locdir/out/$3
	fi

 	romzip="$(realpath $2)"
	extract_rom $romzip $out_zip


elif [ "$FungTion" == "repack" ]; then

	if [ ! -d $locdir/out/$2 ]; then
		echo "Output isnt exist. Cannot continue."
		exit 1
	fi

	if [ "$3" == "" ]; then
		out_dir=$locdir/out/"$2"_$date-"$datesec"_repack.zip
	else
		if [ ! -f $3 ] || [ ! -d $3 ]; then
			out_dir=$locdir/out/"$3"_repack.zip
		else
			echo "Only name allowed, not path!"
			exit 1
		fi
	fi
	if [ ! -f $locdir/out/$2/romdata/zip_list.txt ]; then
		echo "Target isnt a valid project to repack. Cannot continue."
		exit 1
	fi
 	romdir=$locdir/out/$2
	repack_rom $romdir $out_dir


else
	echo "Function $FungTion isn't defined, dont do stupid thing with the code -_-"
	exit 1
fi

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo "Done !"
echo "Took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) to complete ;)"
