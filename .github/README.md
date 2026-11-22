# REVENIR 2.0 (TEST) for the Xiaomi Mi 9 (cepheus), Android 16

This branch is **REVENIR 2.0**, a new base for REVENIR. Instead of REVUELTO it
starts from the **LineageOS sm8150 kernel**
([xiaomi-sm8150-devs/android_kernel_xiaomi_sm8150](https://github.com/xiaomi-sm8150-devs/android_kernel_xiaomi_sm8150),
branch `lineage-23.2`) and adds the REVENIR features on top.

> ⚠️ **First test build.** It has not yet been tested on a phone. Make a
> backup of **boot and dtbo** before flashing. Read "dtbo" below first.

For the REVENIR 1.x builds (REVUELTO base) see the
[`revenir-a16`](https://github.com/b3zib3zi/kernel_xiaomi_cepheus/tree/revenir-a16)
branch.

---

## Why a LineageOS base?

The LineageOS kernel is maintained for all sm8150 Xiaomi phones and carries
far more upstream backports than the REVUELTO tree: about 3,100 backported
commits since 2022 (BPF, networking, security, memory management, `clone3()`,
`pidfd`, `epoll_pwait2()`, `close_range()` and more), against about 500 in
REVENIR 1.x. That makes it the better starting point for current and future
Android versions.

## What REVENIR adds

- **KernelSU-Next legacy** (33314 / `v3.4.0-legacy`, manager **v3.4.2**),
  built in, with manual hooks for non-GKI kernels
- **GPU**: InfiniR frequency/voltage table, up to **810 MHz**
- **Display overclock** by zip name, as in REVENIR 1.x (66 to 90 Hz, see below)
- **Compatibility with crDroid**: crDroid's fingerprint (FOD) and
  double-tap HALs expect the node layout of the InfiniR kernel. The touch
  driver now offers both layouts:
  - `/sys/devices/virtual/touch/tp_dev/fod_status` and `fod_state`
  - `/proc/touchpanel/wake_gesture`
  - plus the LineageOS nodes in `/sys/touchpanel/`
- Build script, AnyKernel3 zip and version string `-REVENIR`

Everything else follows LineageOS on purpose in this first stage: memory
management and low-memory killer (no simple_lmk), thermal, CPU and scheduler
settings, I/O.

## dtbo

The dtbo partition of crDroid comes from the InfiniR source and does not
match the LineageOS device tree of this kernel. The zip therefore flashes its
own **dtbo** (the LineageOS cepheus overlay) together with the kernel.

Before writing it, the installer saves the current dtbo to
`/sdcard/REVENIR/dtbo-backup-<date>-<time>.img`. If the backup cannot be
written (for example /data is not decrypted in recovery), the installer stops
and changes nothing.

**Going back to REVENIR 1.x or the ROM kernel:**
flash the kernel you want, then restore the backup, e.g. in OrangeFox via
"Install image" → dtbo, or with `fastboot flash dtbo dtbo-backup-....img`.
Reflashing the ROM zip also restores both.

The REVENIR 4000 mAh dtbo add-on is made for the crDroid dtbo and does not
work with 2.0.

## Display refresh rate

As in REVENIR 1.x the panel can run at a fixed higher refresh rate. Put the
rate into the zip name before flashing (e.g. `...-75hz.zip`) or write it to
`/sdcard/framerate_override` (e.g. `75`). Supported: 66, 69, 72, 75, 81, 84,
90 Hz. Without either the panel stays at 60 Hz. Not every panel handles every
rate; if the screen flickers or stays black, flash again without a rate.

## Installation

1. Install **KernelSU-Next manager v3.4.2**.
2. Back up boot and dtbo.
3. Flash the zip in your recovery (OrangeFox, TWRP) with /data decrypted.
4. Reboot.

## What to test

Please report with the exact zip name, ROM and version:

- boots, Wi-Fi, mobile data, calls, Bluetooth, NFC, camera, audio
- **fingerprint under the display** (enrolling and unlocking)
- double tap to wake, proximity sensor during calls
- GPU: `su -c cat /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies` should
  start with `810000000`
- KernelSU-Next: manager shows the kernel version, modules install
- battery drain and deep sleep

```sh
su -c dmesg > /sdcard/dmesg.txt
logcat -d > /sdcard/logcat.txt
```

## Building

```sh
git clone -b revenir-2.0-a16 https://github.com/b3zib3zi/kernel_xiaomi_cepheus
cd kernel_xiaomi_cepheus
./build.sh
```

Needs clang/lld 19, aarch64 and arm32 binutils and python3. The script fetches
the KernelSU-Next commit, merges the config fragments
`vendor/sm8150-perf_defconfig`, `vendor/xiaomi/sm8150-common.config`,
`vendor/xiaomi/cepheus.config` and `vendor/xiaomi/revenir.config`, and writes
`out/arch/arm64/boot/Image-dtb` and `out/arch/arm64/boot/dtbo.img`.
Set `ANYKERNEL_DIR` to an AnyKernel3 template to get a flashable zip.

## Plans

- Stage 2: SUSFS builds and the TEO cpuidle governor
- Stage 3 (optional): MGLRU

## Credits

- the **LineageOS** team and the **xiaomi-sm8150-devs** maintainers for the
  kernel this branch is built on
- **raystef66** for InfiniR (GPU table, crDroid for cepheus)
- **balgxmr** for REVUELTO, the base of REVENIR 1.x
- **rifsxd** and the KernelSU-Next team, **tiann** for KernelSU,
  **backslashxx** for the manual hooks for non-GKI kernels
- the **OpenELA** project and the upstream Linux developers
- **osm0sis** for AnyKernel3
- everyone who tests and reports back

## License

GPL-2.0, see [COPYING](COPYING).
