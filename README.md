# Audio Fix - Samsung Galaxy S20 FE (Snapdragon) 🔊

This repository provides a software-based solution (Magisk/KernelSU module) to bypass the chronic issue of a dead audio chip (short-circuited Audio Codec) on the Samsung Galaxy S20 FE Snapdragon 4G (Model SM-G780G / Platform kona) running AOSP-based Custom ROMs (such as crDroid, LineageOS, etc.).

## 🔍 The Problem

When the motherboard's integrated audio chip burns out or short-circuits, the Android operating system (via the audioserver process) attempts to initialize the default sound hardware (Speakers/Microphone) and enters a timeout/panic state.

This causes a ripple effect throughout the system:

- **Videos freezing:** Apps like YouTube, Instagram, and TikTok freeze upon playback attempt.
- **Broken audio routing:** The short circuit causes the system to fail at recognizing any audio channel, returning "Null" in the logs.
- **No audio output works:** Headphones, speakers, or any other audio devices become completely unresponsive due to the short circuit.

## 🛠️ The Solution (Architectural Bypass)

Instead of spending money on physical motherboard repairs, this patch performs a "clean amputation" at the software level within the operating system's configuration file.

**Result:** Videos run smoothly again without freezing. Audio is processed directly by the CPU, fully restoring sound output for Bluetooth headphones/devices (A2DP), HDMI, and digital wired USB-C headphones (with an integrated DAC). *(Disclaimer: Analog wired USB-C headphones/adapters will not work, as they still rely on the dead internal audio chip for signal passthrough)*.

### 🧩 How It Works (Technical Summary)

The module performs three key operations during boot:

**1. HAL Stub Swap (`post-fs-data.sh` — runs before audioserver starts)**

```bash
mount --bind /vendor/lib64/hw/audio.primary.default.so /vendor/lib64/hw/audio.primary.kona.so
```

The broken `audio.primary.kona.so` (which tries to talk to the dead codec and crashes) is replaced in-memory by `audio.primary.default.so` — a silent stub HAL already present on the device. This prevents the audioserver from crashing at boot.

**2. SELinux Context Fix + XML Bind Mount (`service.sh` — runs after Magisk overlay is applied)**

```bash
cp /vendor/etc/audio_policy_configuration.xml /data/local/tmp/audio_policy_configuration.xml
chcon u:object_r:vendor_configs_file:s0 /data/local/tmp/audio_policy_configuration.xml
mount --bind /data/local/tmp/audio_policy_configuration.xml /vendor/etc/audio_policy_configuration.xml
```

Magisk's Magic Mount overlay sets the wrong SELinux context (`vendor_file:s0`) on the XML config file. The audioserver process requires `vendor_configs_file:s0` to read it. Without this fix, the audioserver silently fails to read the config and falls back to a minimal default with **no Bluetooth/USB audio modules loaded**. The fix copies the file, corrects the SELinux label, and bind-mounts it back.

**3. Audioserver Restart (`service.sh`)**

```bash
killall audioserver
```

After fixing the XML context, the audioserver is restarted. On its second initialization, it successfully reads the full `audio_policy_configuration.xml` and loads **all 4 hardware modules**: `primary`, `bluetooth` (A2DP), `usb`, and `r_submix` — restoring audio routing to external devices.

### 📊 Before vs After

| State | AudioPolicyManager | Hardware Modules | Bluetooth A2DP | USB Audio |
|---|---|---|---|---|
| No module (broken codec) | `NULL` (crash) | 0 | ❌ | ❌ |
| Module installed | Active | 4 (primary, bluetooth, usb, r_submix) | ✅ | ✅ |

> **⚠️ Note:** There is a ~5 second delay after boot before audio becomes available, as the `service.sh` script needs time to execute and restart the audioserver.

## 🚀 How to Install (Systemless Method via Magisk/KernelSU)

Since modern Android partitions are Read-Only (EROFS/EXT4), the modification is safely injected into RAM via Magisk (Bind Mount):

1. Download the `.zip` file from the [Releases](../../releases) tab.
2. Open the **Magisk** or **KernelSU** app.
3. Go to the **Modules** tab and select **Install from storage**.
4. Choose the downloaded `.zip` and **reboot** your device.

> **Note:** If your device enters a bootloop after installation due to ROM incompatibility, simply boot into your Custom Recovery (TWRP Recovery or other) and delete the module folder located at `/data/adb/modules/`.

### 🔧 Verifying It Works

After rebooting, connect to a Bluetooth audio device and run the following via ADB to confirm:

```bash
adb shell su -c "dumpsys media.audio_policy | grep -E 'Config source|Hardware modules'"
```

**Expected output (working):**

```
Config source: /vendor/etc/audio_policy_configuration.xml
Hardware modules (4):
```

**If you see this instead, the module did not load correctly:**

```
Config source: AudioPolicyConfig::setDefault
Hardware modules (1):
```

## 📱 Compatibility

| Device | ROM Type | Status |
|---|---|---|
| S20 FE Snapdragon (G780G/G781B) | AOSP ROMs (crDroid, PulsarOS, LineageOS, EvolutionX, etc.) | ✅ Tested |
| S20 FE Snapdragon (G780G/G781B) | Stock OneUI + Magisk | ⚠️ May need XML/SELinux adjustments |
| S20 FE Exynos (G780F) | Any | ❌ Different HAL (`exynos990`) |
| Other Samsung Snapdragon 865 devices | Any | ⚠️ Untested, may work with adjustments |

## 📂 Module Structure

```
audio-fix-s20fe/
├── module.prop              # Module metadata
├── post-fs-data.sh          # Bind mounts stub HAL (runs early boot)
├── service.sh               # Fixes SELinux + restarts audioserver (runs late boot)
├── system.prop              # Disables codec-dependent features (offload, spkr_prot, etc.)
├── META-INF/                # Magisk installer scripts
└── system/vendor/etc/
    └── audio_policy_configuration.xml  # Simplified config with BT/USB/r_submix modules
```

## ⚠️ Disclaimer / Legal Notice

This is a damage mitigation patch. The device's internal speakers and built-in microphone will remain disabled. Audio output will be strictly limited to Bluetooth headphones or digital outputs. Use at your own risk.

**WARNING:** This module was exclusively tested on crDroid (A16) and PulsarOS. I do not know and cannot guarantee its functionality on other ROMs (especially on OneUI or OneUI-based ROMs). Feel free to fork and modify the module if you have the necessary knowledge.

## 📄 License

This project is provided as-is under the [MIT License](LICENSE). No warranty is provided.
