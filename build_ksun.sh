#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Build Sultan Kernel + KernelSU-Next for Pixel 8 / 8 Pro (shiba/husky) and
# package it as an AnyKernel3 zip that flashes:
#   boot               <- kernel Image
#   vendor_kernel_boot <- zuma dtb (only the dtb; the stock ramdisk is kept)
#
# Requirements (Ubuntu 24.04):
#   apt install gcc-14-aarch64-linux-gnu binutils-aarch64-linux-gnu flex bison \
#               bc libssl-dev libelf-dev lz4 cpio python3 zip git
#
# Usage: ./build_ksun.sh [-jN]

set -euo pipefail

SRC=$(cd "$(dirname "$0")" && pwd)
OUT=$SRC/out
JOBS=${1:--j$(nproc)}
TC=$OUT/.toolchain
AK3_REPO=https://github.com/osm0sis/AnyKernel3

# GCC LTO needs gcc-ar/gcc-nm; expose the versioned GCC 14 binaries under
# the plain aarch64-linux-gnu- prefix.
mkdir -p "$TC"
for t in gcc gcc-ar gcc-nm gcc-ranlib cpp; do
	ln -sf "$(command -v aarch64-linux-gnu-$t-14)" "$TC/aarch64-linux-gnu-$t"
done
export PATH=$TC:$PATH

MAKE=(make -C "$SRC" O="$OUT" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-)
"${MAKE[@]}" zuma_defconfig
"${MAKE[@]}" "$JOBS" Image dtbs

# Package
STAGE=$OUT/ak3
rm -rf "$STAGE"
git clone -q --depth 1 "$AK3_REPO" "$STAGE"
rm -rf "$STAGE"/.git "$STAGE"/.github "$STAGE"/README.md "$STAGE"/modules \
       "$STAGE"/patch "$STAGE"/ramdisk
cp "$SRC/scripts/ksun/anykernel.sh" "$STAGE/anykernel.sh"

# AnyKernel3 ships 32-bit ARM tools, which can't run on the 64-bit-only
# Pixel 8 series. Replace busybox/magiskboot/magiskpolicy with the arm64
# builds from an official Magisk release.
MAGISK_VER=v31.1
MAGISK_SHA256=89cefac0a318afa39fb3880c45c87b036c05bc1ebf02a7a715b7f8d7c26ac6e7
MAGISK_APK=$OUT/Magisk-$MAGISK_VER.apk
[ -f "$MAGISK_APK" ] || curl -fsSL -o "$MAGISK_APK" \
	"https://github.com/topjohnwu/Magisk/releases/download/$MAGISK_VER/Magisk-$MAGISK_VER.apk"
echo "$MAGISK_SHA256  $MAGISK_APK" | sha256sum -c -
for t in busybox magiskboot magiskpolicy; do
	unzip -p "$MAGISK_APK" "lib/arm64-v8a/lib$t.so" > "$STAGE/tools/$t"
done
chmod 755 "$STAGE"/tools/*
mkdir "$STAGE/boot-files" "$STAGE/vendor_kernel_boot-files"
cp "$OUT/arch/arm64/boot/Image" "$STAGE/boot-files/Image"
# Same order as ZUMA_DTBS in google-devices/zuma/constants.bzl
DTS=$OUT/google-devices/zuma/dts
cat "$DTS/zuma-a0-foplp.dtb" "$DTS/zuma-a0-ipop.dtb" \
    "$DTS/zuma-b0-foplp.dtb" "$DTS/zuma-b0-ipop.dtb" \
    > "$STAGE/vendor_kernel_boot-files/dtb"
# Files are already split per partition; skip AK3's auto multi-partition setup
touch "$STAGE/init_v4_setup"

ZIP=$OUT/Sultan-KSUN-husky-shiba-$(date +%Y%m%d).zip
rm -f "$ZIP"
(cd "$STAGE" && zip -qr9 "$ZIP" .)
echo "Done: $ZIP"
