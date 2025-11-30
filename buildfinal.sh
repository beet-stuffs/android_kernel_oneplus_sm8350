#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="martini-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="/home/aryan/lineage-23/prebuilts/clang/host/linux-x86/clang-r547379"
AK3_DIR="AnyKernel3"
DEFCONFIG="vendor/lahaina-qgki_defconfig"

#clang-17
#if [[ $2 = "-9rt" || $1 = "--martini" ]]; then
MAKE_PARAMS="O=out ARCH=arm64 CC=clang LLVM=1 LLVM_IAS=1"
#fi

export PATH="$TC_DIR/bin:$PATH"

if [[ $2 = "-r" || $1 = "--regen" ]]; then
	make $MAKE_PARAMS $DEFCONFIG savedefconfig
	cp out/.config arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

if [[ $2 = "-fr" || $1 = "--fregen" ]]; then #full regen
        make $MAKE_PARAMS $DEFCONFIG
        cp out/.config arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit
fi

if [[ $2 = "-dfr" || $1 = "--defregen" ]]; then #defconfig regen
        make $MAKE_PARAMS $DEFCONFIG savedefconfig
        cp out/defconfig arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit

fi

if [[ $2 = "-mc" || $1 = "--mconf" ]]; then #menuconf
        make $MAKE_PARAMS $DEFCONFIG menuconfig
        cp out/.config arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit
fi


if [[ $2 = "-c" || $1 = "--clean" ]]; then
	echo -e "\nCleaning output folder..."
	rm -rf out
fi

mkdir -p out
make $MAKE_PARAMS $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $MAKE_PARAMS || exit $?

kernel="out/arch/arm64/boot/Image"

if [ -f "$kernel" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR AnyKernel3
	elif ! git clone -q https://github.com/bheatleyyy/AnyKernel3 -b oscar; then
		echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
		exit 1
	fi
        COMPILED_IMAGE=out/arch/arm64/boot/Image
        COMPILED_DTBO=out/arch/arm64/boot/dtbo.img
        mv -f ${COMPILED_IMAGE} ${COMPILED_DTBO} AnyKernel3
        find out/arch/arm64/boot/dts/vendor -name '*.dtb' -exec cat {} + > AnyKernel3/dtb
	cd AnyKernel3
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) :"
	echo "$(realpath $ZIPNAME)"
else
	echo -e "\nCompilation failed!"
	exit 1
fi

#if [ -f "$ZIPNAME" ]; then
	telegram -f "$ZIPNAME"
	telegram "kernel for me don't touch"
#fi
