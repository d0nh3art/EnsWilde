<div align="center">
  <img src="https://github.com/YangJiiii/EnsWilde/blob/be10a7d93b70df3b40057f869e6cc82de92bc2f0/MyApp_Dark_1024.png?raw=true" width="120" alt="EnsWilde Logo" />
</div>
# EnsWilde (Mobile)

**EnsWilde** is a tool utilizing `itunesstored` & `bookassetd` exploits, designed for iPhone and iPad running the latest **iOS Version 26.2b1**.

It operates as a standalone on-device application, functioning independently like modern apps. It leverages the `sparserestore` exploit to write data to files situated outside of the intended restore location.

> [!WARNING]
> **DISCLAIMER:**
> I am **not responsible** if your device enters a bootloop. Use this software with caution.
> **Please back up your data before using!**

## Features
* **Disable call recording notification sound:** Turns off the audible warning when recording calls.
* **Change Apple Wallet background image:** Customize the Wallet pass/card background appearance.
* **Edit MobileGestalt file (advanced):** Modify MobileGestalt configuration values (for advanced users).
* **On-device patching (no PC required):** Works as a standalone app after initial setup.
* **More features coming soon:** Development is ongoing to add new capabilities.


## Getting Your .mobiledevicepairing File
There are two supported ways to obtain a pairing file:

### Option 1 — Generate it with jitterbugpair (recommended)
1.  Download `jitterbugpair` for your operating system here: [Jitterbug Releases](https://github.com/osy/Jitterbug/releases/latest)
    * **Note:** On Mac or Linux, you may need to make it executable first:
        ```bash
        chmod +x ./jitterbugpair
        ```
2.  Run the program (double-click it or run it via Terminal/PowerShell).
3.  Share the generated `.mobiledevicepairing` file to your iOS device (AirDrop, Files, etc.).
4.  Open **EnsWilde** and select the pairing file.

*You should only have to do this once, unless you lose the file or delete the app’s data.*

---

### Option 2 — Pick the pairing file directly from SideStore’s folder
If you already imported/placed a pairing file for SideStore, it’s typically stored in SideStore’s on-device folder.

1. Open **Files** on your iPhone/iPad
2. Go to **Browse** → **On My iPhone/iPad** → **SideStore**
3. Find the file ending in **`.mobiledevicepairing`**
4. Open **EnsWilde** and select that file directly from the SideStore folder

## Setting Up VPN
1.  Download **LocaldevVPN** or **Stikdebug** from the iOS App Store.
2.  Enable the VPN within that app.
3.  Launch **EnsWilde**.

## Troubleshooting

### DDI (Developer Disk Image) error
If you encounter a **DDI / mounting DDI**-related error, you may need to install **StikDebug** and run it **once** so it can download/mount the DDI:

1. Install **StikDebug**: https://github.com/StephenDev0/StikDebug  
2. Launch **StikDebug** and let it complete the DDI step (this is usually a one-time setup)

After the DDI has been created/mounted, you **won’t need StikDebug anymore**—you can simply use **LocaldevVPN** and launch **EnsWilde**.

> If the DDI error returns after a reboot or iOS update, just open StikDebug once again to mount it.


## Credits

Special thanks to the following for their contributions and support:

* **Carrot1211**:[ For cheering me on and supporting me during development.](https://x.com/Hihihehe1221).
* **@khanhduytran0**: [SparseBox](https://github.com/khanhduytran0/SparseBox).
* **@Little_34306**: [Original concept for "Disable Call Recording](https://github.com/34306).
* **@SideStore team**: [`idevice` and C bindings from StikDebug.](https://github.com/sidestore).
* **@JJTech0130**: [`SparseRestore` and backup exploit.](https://github.com/JJTech0130).
* **@hanakim3945**: [`bl_sbx` exploit files and writeup.](https://github.com/hanakim3945).
* **@Lakr233**: [BBackupp](https://github.com/Lakr233/BBackupp).
* **@libimobiledevice**: [For the underlying communication libraries.](https://github.com/libimobiledevice/libimobiledevice).
