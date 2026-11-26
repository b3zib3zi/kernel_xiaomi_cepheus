# reVeniR kernel for the Xiaomi Mi 9 (cepheus)

reVeniR is a custom kernel for the Xiaomi Mi 9 (codename **cepheus**), built on
OpenELA LTS **4.14.357** with **KernelSU-Next** built in and optional **SUSFS**.
It comes in builds for Android 14/15 and Android 16 ROMs.

The name is a blend of the two kernels this work grew out of:
**REV**UELTO by balgxmr and Infini**R** by raystef66. Up to version 1.0 it
was released as REVENIR.

**[Download the latest release](https://github.com/b3zib3zi/kernel_xiaomi_cepheus/releases)**

> ⚠️ These are TEST builds. Flash at your own risk and keep a backup of your
> current boot image.

---

## What's new in 1.1

reVeniR 1.1 is 1.0 plus:

- **22 security and stability fixes** for the Qualcomm drivers, USB and the
  kernel core. Most of them close holes listed in Qualcomm's security
  bulletins and are taken from the LineageOS sm8150 kernel, where they are
  already in use.
- **A GPU table without the unstable top steps.**
- **Two fixes for false error messages** in the kernel log.
- **A fix for apps that hung while saving to the internal storage**, for
  example the MIUI camera when it saves a video.
- **The stock defaults of the video encoder** again.
- **The kernel version now says reVeniR** instead of REVENIR.

Everything else stays as in 1.0: same KernelSU-Next, same SUSFS, same
display options.

### Security and stability fixes

- **GPU (kgsl):** use-after-free when an ION buffer is released; wrong buffer
  alignment caused by sign extension of the alignment value; error handling
  when switching draw contexts
- **DSP / FastRPC (adsprpc):** use-after-free in the global map list; DMA
  handle maps left behind after an error; buffer allocated one byte short of
  the terminating NULL; attribute and flag checks when a map is created
- **NPU:** two use-after-free fixes; a size check of the execute response the
  firmware sends back
- **Video (vidc):** use-after-free when buffers are unregistered
- **Secure channel (smcinvoke):** the reference count of server objects is
  dropped under the mutex
- **WLAN:** out-of-bounds read when the RNR element of a beacon is parsed
- **Audio:**
  - length check in the voice host PCM copy (buffer overflow), which also
    releases its lock and the buffer again when it rejects a packet
  - size checks of DSP replies in the AFE driver
  - the module count the DSP reports to the ADM driver is treated as
    unsigned, so a negative value no longer slips past the size check
  - the PCM capture copy checks the offset the DSP reports and stays inside
    the DSP buffer
- **USB and LED drivers:** three values that could be used uninitialised: in
  the USB gadget log, in USB-PD voltage selection while the charger is being
  verified, and in the LED pattern helpers
- **Kernel (rt-mutex):** two fixes in the error path of priority-inheritance
  locking (PI futexes) that could corrupt the waiter list and crash the kernel

### GPU table

The InfiniR table caused GPU hangs under load on the test phone, in OpenGL
and Vulkan apps alike. Tests pinned to single clocks traced them to the two
highest steps:

- **810 MHz is removed.** It was unstable under load, even at the TURBO
  voltage level. A still higher voltage just for this one step does not
  seem sensible to us, so the step is gone.
- **765 MHz now runs at the TURBO voltage level** instead of NOM_L1. That
  stopped the hangs at this clock.
- All other steps are unchanged: effectively two voltage levels below
  stock, 257 and 195 MHz one level. For 675, 585 and 499.2 MHz the device
  tree now names the voltage levels the chip actually uses. The old names
  were rounded up to these levels anyway, so their voltage stays the same.
- Highest GPU clock on speed bin 0 is now 765 MHz (REVUELTO: 675 MHz,
  Qualcomm's original table: 585 MHz). Speed bin 1 stays at 675 MHz.

### Cleaner kernel log

- **Charger driver (smb5):** after every wake-up the log showed
  `failed to read out thermal zone (-61)`. The "usb" thermal zone asks for
  the temperature of a USB port thermistor that the Mi 9 does not have. The
  driver now reports this in a way the thermal core skips silently. This fix
  was added after the 1.0 release and ships for the first time in 1.1.
- **Audio codec driver (wcd9xxx):** every boot logged
  `failed to get slimbus pahu-slim-pgd logical address: -6`. The kernel
  looked for a second codec type, the WCD9360 ("Pahu"), which the Mi 9 does
  not have and whose driver is not built. It now only looks for it when that
  driver is enabled. The Mi 9's WCD934x ("Tavil") codec works as before.

### Saving to the internal storage

- **FUSE:** when an app overwrote part of an existing file on the internal
  storage (`/sdcard`), the kernel kept a lock on that file. The next write to
  it waited forever. The MIUI camera port on crDroid ran into this every
  time it saved a video: the recording itself was complete, but the video
  stayed a hidden `.pending` file, the camera could not be closed and only
  started again after a reboot. The cause was a backport for parallel writes
  that never released its lock. The code is back to the version LineageOS
  and InfiniR use. 1.0 has the same bug.
- Videos from earlier attempts may still be in `DCIM/Camera` as hidden
  `.pending-…mp4` files.

### Video encoder

- **Video encoder (vidc):** the default values of the hardware encoder are
  back to those of the Qualcomm and LineageOS kernel. REVUELTO had raised
  them, for example to constant quality at the maximum, a 300 Mbit/s
  bitrate and the low-latency real-time mode. Camera apps and Android's
  media framework normally set these values themselves, so in most cases
  nothing changes. Where they do not, the encoder now starts from the stock
  values.

### Kernel name

- The kernel version (`uname -r`) now contains `reVeniR` instead of
  `REVENIR`, and the zips are called `reVeniR-1.1-…`.

### README

- Display overclocking (66 to 90 Hz) is now marked as not recommended: it
  runs the panel outside its specification and can damage it.
- The commands for collecting logs under
  [Reporting a problem](#reporting-a-problem) are fixed.

## Which build do I need?

| Your ROM | Root only | Root + SUSFS (conservative) | Root + SUSFS (newest) |
|---|---|---|---|
| **Android 14 / 15** (e.g. crDroid 10, 11) | `revenir-1.1-a15` | `revenir-1.1-a15-susfs-2.1.0` | `revenir-1.1-a15-susfs-2.4.0` |
| **Android 16** (e.g. crDroid 12) | `revenir-1.1-a16` | `revenir-1.1-a16-susfs-2.1.0` | `revenir-1.1-a16-susfs-2.4.0` |

Each name is the source branch of that build. The sources of 1.0 stay
in the branches without a version number (`revenir-a16`, `revenir-a15-susfs-2.4.0`
and so on).

- **Android version matters.** The A16 builds carry the extra syscalls and BPF
  support that Android 16 needs. Use the A15 builds on Android 14 and 15.
- **No SUSFS needed?** Take the root-only build. It has the smallest changes on
  top of the base.
- **SUSFS 2.1.0 or 2.4.0?** 2.1.0 has been around longer but only a part of
  its features work on this kernel (see below). 2.4.0 has the full feature set
  but is a newer port. If something misbehaves on 2.4.0, go back to 2.1.0.

## Supported ROMs

- **Tested:** crDroid 10 and 11 with the A15 builds, crDroid 12 with the A16
  builds.
- **Other AOSP ROMs** for the Mi 9 on Android 14 to 16 may work, most likely
  LineageOS and ROMs based on it, as crDroid is. They are not tested. If you
  try one, check the in-display fingerprint, double tap to wake, the refresh
  rate, charging, the camera, calls, Wi-Fi, Bluetooth and NFC, and please
  [report back](#reporting-a-problem).
- **MIUI is not supported.** Its display, fingerprint and thermal services
  rely on Xiaomi kernel interfaces that this kernel does not have.
- **Android 13 and older** are not tested.

## Installation

1. Install **KernelSU-Next manager v3.4.2**. This is the manager for all
   reVeniR builds.
2. Flash the zip in your recovery (OrangeFox, TWRP) or sideload it.
3. Reboot.
4. SUSFS builds only: install a susfs4ksu module that matches the SUSFS version
   of your build (for 2.4.0 the module must support v2.4.0).

The zips contain **no dtbo**, your current dtbo stays untouched.

Older managers will not work correctly: the SUSFS builds report KernelSU UAPI 5,
which manager v3.4.0 does not support.

## Display refresh rate (optional, not recommended)

> ⛔ **Not recommended.** Every rate above 60 Hz overclocks the display panel
> and runs it outside its specification. This can damage the panel. reVeniR
> stays at the stock 60 Hz unless you turn this on, and we recommend leaving
> it there. If you use it anyway, you do so at your own risk.

reVeniR runs the display at the stock **60 Hz** by default. If you still want
a higher rate, you can set it when you flash the kernel. Nothing is changed in
the dtbo, and going back to 60 Hz only takes another flash.

| Refresh rate | Display link clock |
|---|---|
| 60 Hz (default) | 1.103 GHz |
| 66 Hz | 1.21 GHz |
| 69 Hz | 1.265 GHz |
| 72 Hz | 1.32 GHz |
| 75 Hz | 1.375 GHz |
| 81 Hz | 1.485 GHz |
| 84 Hz | 1.54 GHz |
| 90 Hz | 1.65 GHz |

**Option 1: rename the zip.** Add the rate to the file name before flashing,
for example:

```
reVeniR-1.1-cepheus-A16-KSUN-3.4.2-20261127-69hz.zip
```

Allowed: `66hz`, `69hz`, `72hz`, `75hz`, `81hz`, `84hz`, `90hz` (or `69fps`
and so on). Use a lowercase `hz`: `69Hz` is not recognised.

**Option 2: a file on your phone.** Create `/sdcard/framerate_override`
containing only the number, e.g. `69`, then flash the zip with its normal
name. The setting is picked up again on every future kernel update.

The recovery log confirms the setting, e.g. `Setting 69 Hz refresh rate`.

**Check what is active:**

```sh
cat /sys/module/msm_drm/parameters/framerate_override
```

`0` means 60 Hz, `1` to `7` are the steps from 66 to 90 Hz. crDroid can also
show the current rate (Developer options → Show refresh rate).

**Back to 60 Hz:** flash the zip without a rate in its name and delete
`/sdcard/framerate_override` if you created it.

> ⚠️ If you use it anyway: the higher the rate, the further the panel runs
> beyond its specification. Stay at the lowest step you need. If the screen
> flickers, shows lines or stays black, reflash the zip without a rate in its
> name at once. A clean result in the
> [frame skipping test](https://www.testufo.com/frameskipping) (photo with about
> 1/10 s exposure, the boxes must be lit without gaps) only
> shows that no frames are lost. It does not show that the rate is safe for
> the panel. Higher rates also use a bit more battery.

## Features

### Base
- OpenELA LTS **4.14.357** merged into REVUELTO
- Built with **clang 19** and ThinLTO
- **GPU**: frequency/voltage table based on InfiniR, up to **765 MHz**
- **Display**: optional refresh rate from 66 to 90 Hz, not recommended
  because it can damage the panel
  (see [Display refresh rate](#display-refresh-rate-optional-not-recommended))

### Root
- **KernelSU-Next legacy**, built into the kernel
- Manual hooks for non-GKI kernels, including the `sys_reboot` hook that ksud
  needs to talk to the driver

| Build | Kernel reports |
|---|---|
| root only | 33314 / `v3.4.0-legacy` |
| SUSFS 2.1.0 | 33315 / `v3.4.0-legacy-susfs`, UAPI 5 |
| SUSFS 2.4.0 | 33322 / `v3.4.2-legacy-susfs`, UAPI 5 |

The tag `v3.4.0-legacy` comes from the legacy branch of KernelSU-Next.
The builds already contain the later legacy fixes, and manager v3.4.2 is the
right one for all of them.

### SUSFS 2.1.0
Taken from InfiniR, with additional hardening of the userspace interface.

- Working: try_umount, uname and cmdline spoofing, stat (kstat) spoofing,
  hiding of mount IDs
- **Not wired** in this port: sus_path, sus_map, open_redirect.
  Use the 2.4.0 build if you need them.

### SUSFS 2.4.0
A port of simonpunk's susfs4ksu v2.4.0 to this 4.14 tree, with every hook
adapted to the 4.14 code.

- sus_path, sus_mount, sus_kstat, sus_map, open_redirect
- uname and `/proc/cmdline` spoofing, priority UID filter, AVC log spoofing
- Unmounting is done by KernelSU-Next itself; try_umount is deprecated in
  SUSFS v2.4.0
- SUSFS kernel logging is off by default and can be switched on by the module

### Android 16 additions (A16 builds)
- `epoll_pwait2()`: Android 16's graphics stack needs it. Without it, apps
  spin in a retry loop and logcat fills with
  `epoll_wait error while waiting for buffer release. errno=38`
- `close_range()` (flags `0` and `CLOSE_RANGE_CLOEXEC`)
- A slim BPF backport (LPM-trie `MAP_GET_NEXT_KEY` and its fixes), the same
  approach as InfiniR A16

### Fixes and hardening
- Display (anti-flicker): fixed a memory leak on every brightness change
- Touch driver (fts_521): fixed a stack buffer overflow and an unbounded stack
  allocation in two debug interfaces
- WLAN: fixed a crash on firmware hang events
- Thermal driver: fewer lookups per poll, same throttling behaviour
- SLAB freelist randomization and hardening, SYN cookies, restricted perf events
- No debugfs, no tracing, no loadable modules, kallsyms off
- Since 1.1: 22 security and stability fixes for the Qualcomm drivers, USB
  and the rt-mutex code (see [What's new in 1.1](#whats-new-in-11))
- Since 1.1: writes into existing files on the internal storage no longer
  hang (FUSE)

## Known limitations

- **GPU undervolting is chip-dependent.** The GPU table runs most steps at
  lower voltages than stock. It was tested on a Mi 9 with speed bin 0, and
  how far a chip can be undervolted differs from phone to phone. If you see
  graphics glitches, freezes that recover after a few seconds, or reboots
  under GPU load, please report it with a log (see below).
- **SUSFS 2.4.0 is still young.** Not included: the experimental SELinux
  hiding of SUSFS (KernelSU-Next's own selinux_hide is used instead) and the
  kallsyms filter (kallsyms is off anyway). open_redirect does not work on
  FUSE paths such as `/sdcard`.
- **Display overclocking is not recommended.** Rates above 60 Hz run the
  panel outside its specification and can damage it. They may also skip
  frames or flicker on some phones. 60 Hz stays the default.
- **No debugfs.** Apps that read kernel wakelocks from debugfs (e.g.
  BetterBatteryStats) cannot show them. App wakelocks are still visible.
- **Spectre branch-predictor hardening is off** in favour of performance.

## Reporting a problem

Please include:

1. The exact zip name you flashed
2. Your ROM and its version
3. Your modules (SUSFS module, Zygisk, others)
4. What happened and how often
5. Logs taken right after the problem, before you reboot. Please send the
   full files, not only lines filtered for "error" or "fail": a GPU hang, for
   example, contains neither word.

```sh
su -c 'dmesg > /sdcard/Download/dmesg.txt'
su -c 'logcat -d > /sdcard/Download/logcat.txt'
```

Keep the quotes as shown. Without them only `dmesg` runs as root and your
terminal app writes the file itself, which often fails on `/sdcard`.
`logcat` without `su` only shows the logs of the terminal app.

After an unexpected reboot, run this first, before you turn the phone off or
reboot again. It holds the log of the previous boot (it is empty if the phone
was switched off before):

```sh
su -c 'cat /proc/last_kmsg > /sdcard/Download/last_kmsg.txt'
```

## Building from source

Each branch has a self-contained `build.sh`.

Requirements (Ubuntu 24.04 example):

```sh
sudo apt install clang-19 lld-19 llvm-19 flex bison bc libssl-dev zip \
    binutils-aarch64-linux-gnu gcc-arm-linux-gnueabi
```

Build:

```sh
git clone -b revenir-1.1-a16 https://github.com/b3zib3zi/kernel_xiaomi_cepheus
cd kernel_xiaomi_cepheus
./build.sh
```

- The script fetches the matching KernelSU-Next commit. On SUSFS branches it
  also applies `KernelSU-Next-susfs-<version>-uapi5.patch`.
- Set `ANYKERNEL_DIR` to an AnyKernel3 template to get a flashable zip;
  without it you get `out/arch/arm64/boot/Image.gz-dtb`.
- `/proc/config.gz` on the phone contains a fixed stock-style configuration,
  not the one the kernel was built with. The real configuration is
  `arch/arm64/configs/cepheus_defconfig`.

## Credits

reVeniR only exists because of the work of others. Thank you to:

- **balgxmr** for REVUELTO, the base of this tree
- **raystef66** for InfiniR: the GPU frequency/voltage table and the SUSFS
  2.1.0 port for cepheus
- **Niviann** for the cepheus bringup and **kondors1995** for SOVIET-STAR,
  which REVUELTO builds on
- **simonpunk** for SUSFS (susfs4ksu)
- **sidex15** for the SUSFS backports to older kernels and the KernelSU-Next
  legacy SUSFS glue
- **rifsxd** and the KernelSU-Next team, **tiann** for the original KernelSU
- **backslashxx** for the manual hooks and backports for non-GKI kernels,
  **ShevT** for the devpts fix
- the **OpenELA** project for keeping the 4.14 LTS kernel alive
- the **LineageOS** sm8150 maintainers (xiaomi-sm8150-devs), whose kernel the
  1.1 security fixes are taken from, and the Qualcomm engineers who wrote them
- the upstream Linux developers whose patches are backported here
- **osm0sis** for AnyKernel3
- everyone who tested the builds and reported back

## License

The Linux kernel is licensed under the GNU General Public License v2.0.
See [COPYING](COPYING).

The original kernel README is still in place; see
[Documentation/admin-guide/README.rst](Documentation/admin-guide/README.rst).
