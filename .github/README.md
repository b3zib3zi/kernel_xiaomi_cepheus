# REVENIR kernel for the Xiaomi Mi 9 (cepheus)

REVENIR is a custom kernel for the Xiaomi Mi 9 (codename **cepheus**), built on
OpenELA LTS **4.14.357** with **KernelSU-Next** built in and optional **SUSFS**.
It comes in builds for Android 14/15 and Android 16 ROMs.

The name is a blend of the two kernels this work grew out of:
**REV**UELTO by balgxmr and Infini**R** by raystef66.

**[Download the latest release](https://github.com/b3zib3zi/kernel_xiaomi_cepheus/releases)**

> ⚠️ These are TEST builds. Flash at your own risk and keep a backup of your
> current boot image.

---

## Which build do I need?

| Your ROM | Root only | Root + SUSFS (conservative) | Root + SUSFS (newest) |
|---|---|---|---|
| **Android 14 / 15** (e.g. crDroid 10, 11) | `revenir-a15` | `revenir-a15-susfs-2.1.0` | `revenir-a15-susfs-2.4.0` |
| **Android 16** (e.g. crDroid 12) | `revenir-a16` | `revenir-a16-susfs-2.1.0` | `revenir-a16-susfs-2.4.0` |

Each name is both the source branch and the release tag (`revenir-1.0-...`).

- **Android version matters.** The A16 builds carry the extra syscalls and BPF
  support that Android 16 needs. Use the A15 builds on Android 14 and 15.
- **No SUSFS needed?** Take the root-only build. It has the smallest changes on
  top of the base.
- **SUSFS 2.1.0 or 2.4.0?** 2.1.0 has been around longer but only a part of
  its features work on this kernel (see below). 2.4.0 has the full feature set
  but is a newer port. If something misbehaves on 2.4.0, go back to 2.1.0.

## Installation

1. Install **KernelSU-Next manager v3.4.2**. This is the manager for all
   REVENIR builds.
2. Flash the zip in your recovery (OrangeFox, TWRP) or sideload it.
3. Reboot.
4. SUSFS builds only: install a susfs4ksu module that matches the SUSFS version
   of your build (for 2.4.0 the module must support v2.4.0).

The zips contain **no dtbo**, your current dtbo stays untouched.

Older managers will not work correctly: the SUSFS builds report KernelSU UAPI 5,
which manager v3.4.0 does not support.

## Display refresh rate (optional)

REVENIR runs the display at the stock **60 Hz** by default. You can raise the
refresh rate when you flash the kernel. Nothing is changed in the dtbo, and
going back to 60 Hz only takes another flash.

> **1.0.1 test builds:** without a rate in the zip name, the display offers
> two modes, **60 Hz and 50 Hz**. Android switches to 50 Hz on its own while
> nothing on screen moves, and back to 60 Hz for any movement. With a rate in
> the zip name, the display runs at that fixed rate, as in 1.0.

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
REVENIR-1.0-cepheus-A16-KSUN-3.4.2-20261116-69hz.zip
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

> ⚠️ This is display overclocking. Not every panel handles every step.
> Start with 66 or 69 Hz. Check for skipped frames with the frame skipping
> test on [testufo.com](https://www.testufo.com/frameskipping) (take a photo
> with about 1/10 s exposure; the boxes must be lit without gaps).
> Higher rates use a bit more battery. If the screen flickers, shows lines
> or stays black, reflash the zip without a rate in its name.

## Features

### Base
- OpenELA LTS **4.14.357** merged into REVUELTO
- Built with **clang 19** and ThinLTO
- **GPU**: frequency/voltage table from InfiniR, up to **810 MHz**
- **Display**: optional refresh rate from 66 to 90 Hz
  (see [Display refresh rate](#display-refresh-rate-optional))

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
A port of simonpunk's susfs4ksu v2.4.0 to this 4.14 tree. Every hook was
adapted by hand.

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

## Known limitations

- **GPU undervolting is chip-dependent.** The InfiniR GPU table runs the GPU
  at lower voltages than stock. Most phones handle this fine. If you see
  graphics glitches, freezes that recover after a few seconds, or reboots
  under GPU load, please report it with a log (see below).
- **SUSFS 2.4.0 is still young.** Not included: the experimental SELinux
  hiding of SUSFS (KernelSU-Next's own selinux_hide is used instead) and the
  kallsyms filter (kallsyms is off anyway). open_redirect does not work on
  FUSE paths such as `/sdcard`.
- **Display overclocking is panel-dependent.** Higher refresh rates may skip
  frames or flicker on some phones; 60 Hz stays the default.
- **No debugfs.** Apps that read kernel wakelocks from debugfs (e.g.
  BetterBatteryStats) cannot show them. App wakelocks are still visible.
- **Spectre branch-predictor hardening is off** in favour of performance.

## Reporting a problem

Please include:

1. The exact zip name you flashed
2. Your ROM and its version
3. Your modules (SUSFS module, Zygisk, others)
4. What happened and how often
5. Logs taken right after the problem, if possible:

```sh
su -c dmesg > /sdcard/dmesg.txt
logcat -d > /sdcard/logcat.txt
```

After an unexpected reboot, `/sys/fs/pstore/` may contain the log of the
previous boot.

## Building from source

Each branch has a self-contained `build.sh`.

Requirements (Ubuntu 24.04 example):

```sh
sudo apt install clang-19 lld-19 llvm-19 flex bison bc libssl-dev zip \
    binutils-aarch64-linux-gnu gcc-arm-linux-gnueabi
```

Build:

```sh
git clone -b revenir-a16 https://github.com/b3zib3zi/kernel_xiaomi_cepheus
cd kernel_xiaomi_cepheus
./build.sh
```

- The script fetches the matching KernelSU-Next commit. On SUSFS branches it
  also applies `KernelSU-Next-susfs-<version>-uapi5.patch`.
- Set `ANYKERNEL_DIR` to an AnyKernel3 template to get a flashable zip;
  without it you get `out/arch/arm64/boot/Image.gz-dtb`.

## Credits

REVENIR only exists because of the work of others. Thank you to:

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
- the upstream Linux developers whose patches are backported here
- **osm0sis** for AnyKernel3
- everyone who tested the builds and reported back

## License

The Linux kernel is licensed under the GNU General Public License v2.0.
See [COPYING](COPYING).

The original kernel README is still in place; see
[Documentation/admin-guide/README.rst](Documentation/admin-guide/README.rst).
