#!/bin/bash
# MSM8916 KK kernel build script v0.5

BUILD_COMMAND=$1
if [ "$BUILD_COMMAND" == "rossa_eur" ]; then
        PRODUCT_NAME=rossalte;
	SIGN_MODEL=SM-G360F_EUR_XX_ROOT0
elif [ "$BUILD_COMMAND" == "rossa_vzw" ]; then
        PRODUCT_NAME=coreprimeltevzw;
        SIGN_MODEL=SM-G360V_NA_VZW_ROOT0
elif [ "$BUILD_COMMAND" == "a3_chnopen" ]; then
        PRODUCT_NAME=a3ltechn;
        SIGN_MODEL=SM-A3000_CHN_CHC_ROOT0
elif [ "$BUILD_COMMAND" == "a3_chntw" ]; then
        PRODUCT_NAME=a3ltezt;
	 SIGN_MODEL=
elif [ "$BUILD_COMMAND" == "a3_chnhk" ]; then
        PRODUCT_NAME=a3ltezh;
	 SIGN_MODEL=
elif [ "$BUILD_COMMAND" == "a3_chnctc" ]; then
        PRODUCT_NAME=a3ltectc;
	 SIGN_MODEL=
elif [ "$BUILD_COMMAND" == "a3_eur" ]; then
	PRODUCT_NAME=a3ltexx;
	SIGN_MODEL=SM-A300F_CIS_SER_ROOT0
elif [ "$BUILD_COMMAND" == "j1_vzw" ]; then
        PRODUCT_NAME=j1qltevzw;
	SIGN_MODEL=SM-J100V_NA_VZW_ROOT0
elif [ "$BUILD_COMMAND" == "novel_kx" ]; then
        PRODUCT_NAME=novelltekx;
elif [ "$BUILD_COMMAND" == "j5lte_chncmcc" ]; then
        PRODUCT_NAME=j5lte_chncmcc;
elif [ "$BUILD_COMMAND" == "j5lte_chnctc" ]; then
        PRODUCT_NAME=j5lte_chnctc;
	SIGN_MODEL=
elif [ "$BUILD_COMMAND" == "j5lte_kor" ]; then
        PRODUCT_NAME=j5ltekx;
	SIGN_MODEL=
elif [ "$BUILD_COMMAND" == "j5nlte_eur" ]; then
        PRODUCT_NAME=j5nlte;
	SIGN_MODEL=
elif [ "$BUILD_COMMAND" == "j75lte_ktt" ]; then
        PRODUCT_NAME=j75ltektt;
	SIGN_MODEL=
else
#default product
        PRODUCT_NAME=$BUILD_COMMAND;
	SIGN_MODEL=
fi

BUILD_WHERE=$(pwd)
BUILD_KERNEL_DIR=$BUILD_WHERE
BUILD_ROOT_DIR=$BUILD_KERNEL_DIR/../..
BUILD_KERNEL_OUT_DIR=$BUILD_ROOT_DIR/android/out/target/product/$PRODUCT_NAME/obj/KERNEL_OBJ
PRODUCT_OUT=$BUILD_ROOT_DIR/android/out/target/product/$PRODUCT_NAME


SECURE_SCRIPT=$BUILD_ROOT_DIR/buildscript/tools/signclient.jar
BUILD_CROSS_COMPILE=$BUILD_ROOT_DIR/android/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`

# Default Python version is 2.7
mkdir -p bin
ln -sf /usr/bin/python2.7 ./bin/python
export PATH=$(pwd)/bin:$PATH

KERNEL_DEFCONFIG=msm8916_sec_defconfig
DEBUG_DEFCONFIG=msm8916_sec_eng_defconfig
SELINUX_DEFCONFIG=selinux_defconfig
SELINUX_LOG_DEFCONFIG=selinux_log_defconfig
DMVERITY_DEFCONFIG=dmverity_defconfig

while getopts "w:t:" flag; do
	case $flag in
		w)
			BUILD_OPTION_HW_REVISION=$OPTARG
			echo "-w : "$BUILD_OPTION_HW_REVISION""
			;;
		t)
			TARGET_BUILD_VARIANT=$OPTARG
			echo "-t : "$TARGET_BUILD_VARIANT""
			;;
		*)
			echo "wrong 2nd param : "$OPTARG""
			exit -1
			;;
	esac
done

shift $((OPTIND-1))

BUILD_COMMAND=$1
SECURE_OPTION=
SEANDROID_OPTION=
if [ "$2" == "-B" ]; then
SECURE_OPTION=$2
elif [ "$2" == "-E" ]; then
	SEANDROID_OPTION=$2
else
	NO_JOB=
fi

if [ "$3" == "-B" ]; then
	SECURE_OPTION=$3
elif [ "$3" == "-E" ]; then
	SEANDROID_OPTION=$3
else
	NO_JOB=
fi

MODEL=${BUILD_COMMAND%%_*}
TEMP=${BUILD_COMMAND#*_}
REGION=${TEMP%%_*}
CARRIER=${TEMP##*_}

VARIANT_DEFCONFIG=msm8916_sec_${MODEL}_${CARRIER}_defconfig

CERTIFICATION=NONCERT

case $1 in
		clean)
		echo "Not support... remove kernel out directory by yourself"
		exit 1
		;;
		
		*)
		
		BOARD_KERNEL_BASE=0x80000000
		BOARD_KERNEL_PAGESIZE=2048
		BOARD_KERNEL_TAGS_OFFSET=0x01E00000
		BOARD_RAMDISK_OFFSET=0x02000000
		#BOARD_KERNEL_CMDLINE="console=ttyHSL0,115200,n8 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3"
		BOARD_KERNEL_CMDLINE="console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci"
#		BOARD_KERNEL_CMDLINE="console=ttyHSL0,115200,n8 androidboot.hardware=qcom androidboot.bootdevice=soc.0/7824900.sdhci user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 video=vfb:640x400,bpp=32,memsize=3072000 earlyprintk"
		mkdir -p $BUILD_KERNEL_OUT_DIR
		;;

esac

KERNEL_ZIMG=$BUILD_KERNEL_OUT_DIR/arch/arm/boot/zImage
DTC=$BUILD_KERNEL_OUT_DIR/scripts/dtc/dtc

FUNC_CLEAN_DTB()
{
	if ! [ -d $BUILD_KERNEL_OUT_DIR/arch/arm/boot/dts ] ; then
		echo "no directory : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot/dts""
	else
		echo "rm files in : "$BUILD_KERNEL_OUT_DIR/arch/arm/boot/dts/*.dtb""
		rm $BUILD_KERNEL_OUT_DIR/arch/arm/boot/dts/*.dtb
	fi
}

INSTALLED_DTIMAGE_TARGET=${PRODUCT_OUT}/dt.img
DTBTOOL=$BUILD_KERNEL_DIR/tools/dtbTool

FUNC_BUILD_DTIMAGE_TARGET()
{
	echo ""
	echo "================================="
	echo "START : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
	echo "DT image target : $INSTALLED_DTIMAGE_TARGET"
	
	if ! [ -e $DTBTOOL ] ; then
		if ! [ -d $BUILD_ROOT_DIR/android/out/host/linux-x86/bin ] ; then
			mkdir -p $BUILD_ROOT_DIR/android/out/host/linux-x86/bin
		fi
		cp $BUILD_ROOT_DIR/kernel/tools/dtbTool $DTBTOOL
	fi

	echo "$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p $BUILD_KERNEL_OUT_DIR/scripts/dtc/ $BUILD_KERNEL_OUT_DIR/arch/arm/boot/dts/"
		$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p $BUILD_KERNEL_OUT_DIR/scripts/dtc/ $BUILD_KERNEL_OUT_DIR/arch/arm/boot/dts/

	chmod a+r $INSTALLED_DTIMAGE_TARGET

	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
}

FUNC_BUILD_KERNEL()
{
	echo ""
	echo "=============================================="
	echo "START : FUNC_BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "build project="$PROJECT_NAME""
	echo "build common config="$KERNEL_DEFCONFIG ""
	echo "build variant config="$VARIANT_DEFCONFIG ""
	echo "build secure option="$SECURE_OPTION ""
	echo "build SEANDROID option="$SEANDROID_OPTION ""

        if [ "$BUILD_COMMAND" == "" ]; then
                SECFUNC_PRINT_HELP;
                exit -1;
        fi

	FUNC_CLEAN_DTB

	make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG VARIANT_DEFCONFIG=$VARIANT_DEFCONFIG \
			DEBUG_DEFCONFIG=$DEBUG_DEFCONFIG \
			SELINUX_DEFCONFIG=$SELINUX_DEFCONFIG \
			SELINUX_LOG_DEFCONFIG=$SELINUX_LOG_DEFCONFIG || exit -1

	make -C $BUILD_KERNEL_DIR O=$BUILD_KERNEL_OUT_DIR -j$BUILD_JOB_NUMBER ARCH=arm \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1

	FUNC_BUILD_DTIMAGE_TARGET
	
	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}

FUNC_MKBOOTIMG()
{
	echo ""
	echo "==================================="
	echo "START : FUNC_MKBOOTIMG"
	echo "==================================="
	echo ""
	MKBOOTIMGTOOL=$BUILD_ROOT_DIR/android/kernel/tools/mkbootimg

	if ! [ -e $MKBOOTIMGTOOL ] ; then
		if ! [ -d $BUILD_ROOT_DIR/android/out/host/linux-x86/bin ] ; then
			mkdir -p $BUILD_ROOT_DIR/android/out/host/linux-x86/bin
		fi
		cp $BUILD_ROOT_DIR/anroid/kernel/tools/mkbootimg $MKBOOTIMGTOOL
	fi

	echo "Making boot.img ..."
	echo "	$MKBOOTIMGTOOL --kernel $KERNEL_ZIMG \
			--ramdisk $PRODUCT_OUT/ramdisk.img \
			--output $PRODUCT_OUT/boot.img \
			--cmdline "$BOARD_KERNEL_CMDLINE" \
			--base $BOARD_KERNEL_BASE \
			--pagesize $BOARD_KERNEL_PAGESIZE \
			--ramdisk_offset $BOARD_RAMDISK_OFFSET \
			--tags_offset $BOARD_KERNEL_TAGS_OFFSET \
			--dt $INSTALLED_DTIMAGE_TARGET"
			
	$MKBOOTIMGTOOL --kernel $KERNEL_ZIMG \
			--ramdisk $PRODUCT_OUT/ramdisk.img \
			--output $PRODUCT_OUT/boot.img \
			--cmdline "$BOARD_KERNEL_CMDLINE" \
			--base $BOARD_KERNEL_BASE \
			--pagesize $BOARD_KERNEL_PAGESIZE \
			--ramdisk_offset $BOARD_RAMDISK_OFFSET \
			--tags_offset $BOARD_KERNEL_TAGS_OFFSET \
			--dt $INSTALLED_DTIMAGE_TARGET

	if [ "$SEANDROID_OPTION" == "-E" ] ; then
		FUNC_SEANDROID
	fi

	if [ "$SECURE_OPTION" == "-B" ]; then
		FUNC_SECURE_SIGNING
	fi

	cd $PRODUCT_OUT
	tar cvf boot_${MODEL}_${CARRIER}_${CERTIFICATION}.tar boot.img

	cd $BUILD_ROOT_DIR
	if ! [ -d output ] ; then
		mkdir -p output
	fi

        echo ""
	echo "================================================="
        echo "-->Note, copy to $BUILD_TOP_DIR/../output/ directory"
	echo "================================================="
	cp $PRODUCT_OUT/boot_${MODEL}_${CARRIER}_${CERTIFICATION}.tar $BUILD_ROOT_DIR/output/boot_${MODEL}_${CARRIER}_${CERTIFICATION}.tar || exit -1
        cd ~

	echo ""
	echo "==================================="
	echo "END   : FUNC_MKBOOTIMG"
	echo "==================================="
	echo ""
}

FUNC_SEANDROID()
{
	echo -n "SEANDROIDENFORCE" >> $PRODUCT_OUT/boot.img
}

FUNC_SECURE_SIGNING()
{
	echo "java -jar $SECURE_SCRIPT -model $SIGN_MODEL -runtype ss_openssl_sha -input $PRODUCT_OUT/boot.img -output $PRODUCT_OUT/signed_boot.img"
	openssl dgst -sha256 -binary $PRODUCT_OUT/boot.img > sig_32
	java -jar $SECURE_SCRIPT -runtype ss_openssl_sha -model $SIGN_MODEL -input sig_32 -output sig_256
	cat $PRODUCT_OUT/boot.img sig_256 > $PRODUCT_OUT/signed_boot.img

	mv -f $PRODUCT_OUT/boot.img $PRODUCT_OUT/unsigned_boot.img
	mv -f $PRODUCT_OUT/signed_boot.img $PRODUCT_OUT/boot.img

	CERTIFICATION=CERT
}

SECFUNC_PRINT_HELP()
{
	echo -e '\E[33m'
	echo "Help"
	echo "$0 \$1 \$2 \$3"
	echo "  \$1 : "
	echo "	for ROSSALTE_EUR_OPEN use rossa_eur"
	echo "	for ROSSALTE_USA_TMO use rossa_tmo"
	echo "	for ROSSALTE_USA_VZW use rossa_vzw"
	echo "	for A3LTE_EUR_OPEN use a3_eur"
	echo "	for A3LTE_CHN_OPEN use a3_chnopen"
	echo "	for A3LTE_CHN_HK use a3_chnhk"
	echo "	for A3LTE_CHN_TW use a3_chntw"
	echo "	for A3LTE_CHN_CTC use a3_chnctc"
	echo "	for J1_USA_VZW use j1_vzw"
	echo "	for J5LTE_EUR use j5lte_eur"
	echo "	for J53G_EUR use j53g_eur"
	echo "	for J5LTE_CHNCMCC use j5lte_chncmcc"
	echo "	for J5LTE_KOR_OPEN use j5lte_kor"
	echo "	for J5NLTE_EUR use j5nlte_eur"
	echo "	for J75LTE_KOR_KTT use j75lte_ktt"
	echo "	for NOVELLTE_KOR_OPEN use novel_kx"
	echo "  \$2 : "
	echo "	-B or Nothing  (-B : Secure Binary)"
	echo "  \$3 : "
	echo "	-E or Nothing  (-E : SEANDROID Binary)"
	echo -e '\E[0m'
}


# MAIN FUNCTION
rm -rf ./build.log
(
	START_TIME=`date +%s`

	FUNC_BUILD_KERNEL
	#FUNC_RAMDISK_EXTRACT_N_COPY
	FUNC_MKBOOTIMG

	END_TIME=`date +%s`

	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "Total compile time is $ELAPSED_TIME seconds"
) 2>&1	 | tee -a ./build.log
