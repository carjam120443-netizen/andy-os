# Andy OS

![Android Robot](assets/android-robot.svg)

> **Andy OS** is a customizable Android-for-PC project targeting generic **x86_64** hardware and virtual machines.

## Current base

This repository starts from the latest stable **Android-x86 x86_64** release currently published by the Android-x86 project: **Android-x86 9.0-r2 (Pie)**. The official Android-x86 documentation provides the `android_x86_64` target and the `iso_img` build target for producing a bootable ISO.

The full Android source tree is fetched during the build instead of being committed here, keeping this customization repository small.

### Tooling baseline

- Android SDK Platform-Tools **37.0.1**
- Android SDK Command-Line Tools **15859902**
- Android CLI **1.0.16406183**
- AOSP Android 16 is tracked as the modern Android platform reference for future porting work
- Android-x86 `android_x86_64-userdebug` is the initial ISO-producing base

## Repository layout

```text
andy-os/
├── assets/
│   └── android-robot.svg
├── build/
│   ├── build-iso.sh
│   └── requirements-debian.txt
├── configs/
│   └── buildspec.mk
├── manifests/
│   └── android-x86.env
├── scripts/
│   ├── bootstrap.sh
│   └── doctor.sh
├── .gitignore
└── README.md
```

## Build

Use a Linux x86_64 build environment. Android platform builds are large, so allow substantial disk space and RAM.

### 1. Install host dependencies

```bash
sudo apt update
sudo apt install -y $(cat build/requirements-debian.txt)
```

Install Google's `repo` launcher separately if it is not already available.

### 2. Check the environment

```bash
bash scripts/doctor.sh
```

### 3. Bootstrap Android-x86

```bash
bash scripts/bootstrap.sh
```

### 4. Build the ISO

```bash
bash build/build-iso.sh
```

Expected output:

```text
out/target/product/android_x86_64/android_x86_64.iso
```

### VirtualBox testing

The ISO is intended to be testable in a virtual machine before physical-hardware testing. For VirtualBox, use an x86_64 VM and enable EFI when testing the EFI boot path.

## Customization

The repository is deliberately small so we can add our own layer without committing the entire Android source tree.

Planned customization areas:

- Andy OS branding and boot graphics
- system properties and defaults
- preinstalled applications
- launcher and desktop-style UI
- wallpapers and themes
- kernel configuration
- x86_64 hardware fixes
- boot configuration
- packages and build-time modules
- Android framework changes

## Version note

There is an important distinction between the **newest Android platform** and the **newest released Android-x86 ISO**. Google publishes newer Android platform releases, while the official Android-x86 project currently lists **9.0-r2** as its newest stable Android-x86 release. This repository therefore uses Android-x86 as the immediately buildable ISO foundation instead of pretending that an official Android 16/17 PC ISO exists.

## Android robot attribution

The Android robot in this repository is reproduced/modified from work created and shared by Google and is used according to the Creative Commons 3.0 Attribution License.

> The Android robot is reproduced or modified from work created and shared by Google and used according to terms described in the Creative Commons 3.0 Attribution License.

Android is a trademark of Google LLC.

## Sources

- Android-x86: https://www.android-x86.org/
- Android-x86 source/build documentation: https://github.com/android-x86/android-x86-com.github.io/blob/master/source.html
- Android Developers branding guidance: https://developer.android.com/distribute/marketing-tools/brand-guidelines
- Android SDK Platform-Tools: https://developer.android.com/tools/releases/platform-tools
- Android Studio and command-line tools: https://developer.android.com/studio
- Android Open Source Project: https://source.android.com/

## Status

🚧 **Early build foundation — customization comes next.**
