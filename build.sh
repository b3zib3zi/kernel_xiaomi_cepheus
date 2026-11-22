#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# REVENIR 2.0 kernel build script - Xiaomi Mi 9 (cepheus)
#
# Base: LineageOS sm8150 kernel (xiaomi-sm8150-devs/android_kernel_xiaomi_sm8150)
#
# Usage: ./build.sh [clean]
#
# Needs clang/lld 19 plus aarch64 and arm32 GNU binutils, e.g. on Ubuntu 24.04:
#   apt install clang-19 lld-19 llvm-19 flex bison bc libssl-dev zip python3 \
#       device-tree-compiler binutils-aarch64-linux-gnu gcc-arm-linux-gnueabi
# The in-tree dtc is too old for the LineageOS overlays, like the Android
# build this uses an external dtc (DTC_EXT, default: dtc from PATH).
#
# Output in $OUT_DIR/arch/arm64/boot/:
#   Image-dtb     kernel (uncompressed) with the base dtbs appended
#   dtbo.img      cepheus overlay, must be flashed together with the kernel
# With an AnyKernel3 template in $ANYKERNEL_DIR the script also builds
# $ZIP_DIR/REVENIR-<ver>-cepheus-A16-KSUN-<ksun>-<date>.zip

set -e

# Version of this kernel and of the parts it carries
REVENIR_VER="${REVENIR_VER:-2.0}"
ANDROID_VER="A16"
# Names the KernelSU-Next manager release users have to install.
# The kernel itself reports the tag of its checkout, v3.4.0-legacy.
KSUN_VER="3.4.2"

# KernelSU-Next: official legacy branch, unpatched. Version (33314) and tag
# (v3.4.0-legacy) come from the git history of the checkout.
KSU_COMMIT="465490a26667ba4cf00b3be975a7e28e53978829"

# LineageOS config fragments plus the REVENIR additions
DEFCONFIGS=(
	vendor/sm8150-perf_defconfig
	vendor/xiaomi/sm8150-common.config
	vendor/xiaomi/cepheus.config
	vendor/xiaomi/revenir.config
)

KERNEL_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${OUT_DIR:-$KERNEL_DIR/out}"
# AnyKernel3 template (anykernel.sh, tools/, META-INF/), not part of this repo
ANYKERNEL_DIR="${ANYKERNEL_DIR:-$HOME/anykernel}"
ZIP_DIR="${ZIP_DIR:-$KERNEL_DIR/..}"
LLVM_BIN="${LLVM_BIN:-/usr/lib/llvm-19/bin}"
DTC_EXT="${DTC_EXT:-$(command -v dtc || true)}"
[ -n "$DTC_EXT" ] || { echo "dtc not found, install device-tree-compiler or set DTC_EXT"; exit 1; }

BUILD_DATE="${BUILD_DATE:-$(date +%Y%m%d)}"
ZIP_NAME="REVENIR-${REVENIR_VER}-cepheus-${ANDROID_VER}-KSUN-${KSUN_VER}-${BUILD_DATE}.zip"

export PATH="$LLVM_BIN:$PATH"

MAKE_ARGS=(
	-j"$(nproc)"
	O="$OUT_DIR"
	ARCH=arm64
	SUBARCH=arm64
	LLVM=1
	LLVM_IAS=1
	CROSS_COMPILE=aarch64-linux-gnu-
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
	DTC_EXT="$DTC_EXT"
	LOCALVERSION=
	KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-b3zi}"
	KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-revenir}"
)

cd "$KERNEL_DIR"

# KernelSU-Next: official legacy commit
if [ ! -f KernelSU-Next/kernel/Kbuild ]; then
	echo "-- fetching KernelSU-Next $KSU_COMMIT"
	rm -rf KernelSU-Next
	git clone https://github.com/KernelSU-Next/KernelSU-Next.git KernelSU-Next
	git -C KernelSU-Next checkout -q "$KSU_COMMIT"
fi
if [ "$1" = "clean" ]; then
	rm -rf "$OUT_DIR"
fi

START=$(date +%s)

make "${MAKE_ARGS[@]}" "${DEFCONFIGS[@]}"
make "${MAKE_ARGS[@]}"

BOOT="$OUT_DIR/arch/arm64/boot"
IMAGE="$BOOT/Image-dtb"
[ -f "$IMAGE" ] || { echo "build failed: $IMAGE missing"; exit 1; }

# dtbo.img with the cepheus overlay only (one entry, like the ROM's dtbo)
DTBO_SRC="$BOOT/dts/qcom/cepheus-sm8150-overlay.dtbo"
[ -f "$DTBO_SRC" ] || { echo "build failed: $DTBO_SRC missing"; exit 1; }
python3 -I scripts/revenir/mkdtbo.py create "$BOOT/dtbo.img" "$DTBO_SRC"

if [ -f "$ANYKERNEL_DIR/anykernel.sh" ]; then
	cp "$IMAGE" "$BOOT/dtbo.img" "$ANYKERNEL_DIR/"
	rm -f "$ZIP_DIR/$ZIP_NAME"
	(cd "$ANYKERNEL_DIR" && zip -r9 "$ZIP_DIR/$ZIP_NAME" . -x '.git/*' '*.zip')
	echo "-- $ZIP_DIR/$ZIP_NAME"
else
	echo "-- no AnyKernel3 template in $ANYKERNEL_DIR"
	echo "-- kernel: $IMAGE"
	echo "-- dtbo:   $BOOT/dtbo.img"
fi

END=$(date +%s)
echo "### build completed in $(((END - START) / 60)) min $(((END - START) % 60)) s"
