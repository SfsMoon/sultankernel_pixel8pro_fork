### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Sultan Kernel + KernelSU-Next for Pixel 8 / 8 Pro (husky/shiba)
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=husky
device.name2=shiba
device.name3=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
# boot: kernel Image only (hdr v4, generic ramdisk lives in init_boot)
BLOCK=boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# the dtb in this zip is picked up automatically and written to
# vendor_kernel_boot by ak3-core (hdr v4 + init_boot + vendor_kernel_boot)
split_boot;
flash_boot;
## end boot install

## vendor_kernel_boot: Sultan's zuma dtb (required by his EH/zram driver)
BLOCK=vendor_kernel_boot;
IS_SLOT_DEVICE=1;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

reset_ak;
split_boot;
flash_boot;
## end vendor_kernel_boot install
