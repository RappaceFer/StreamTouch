# Guide: play WoW on your phone with StreamTouch

*[Version française](GUIDE-FR.md)*

How it works: your PC runs World of Warcraft, **Sunshine** sends the picture to the phone, and **StreamTouch** shows it and
becomes a touch controller. The **Streaming Touch** addon adds the spell arc and the round menu inside the game. With
**Tailscale** it also works away from home (4G/5G, a friend's Wi-Fi), and the **Magic Packet** lets you turn the PC on remotely.

Count on 30 minutes the first time. After that, open StreamTouch and play.

## What you need

- A Windows PC with World of Warcraft, preferably **wired** (Ethernet) to your router.
- An Android 8.0 or newer phone (64-bit).
- A free Tailscale account (Google, Microsoft, GitHub or e-mail).

## 1. On the PC: Sunshine

Sunshine is the streaming server (free and open source).

1. Download and install Sunshine: https://github.com/LizardByte/Sunshine/releases (the Windows `.exe`).
   Accept the virtual gamepad driver (ViGEmBus) during setup: StreamTouch's controller mode uses it.
2. Open Sunshine's web interface on the PC: **https://localhost:47990**. Accept the security warning (the certificate is
   local), then create a user name and password.
3. Suggested settings (**Configuration** tab):
   - **Audio/Video > Display Device**: deactivate the other displays and set a **manual resolution** equal to your phone's
     (for example `2770x1280` on a Poco F7). The picture then fills the whole phone screen, without black bars.
   - **Input > Gamepad**: `x360`, driver `vigembus`.
4. Let Sunshine start with Windows (it does by default, it is a service).

The "Desktop" app is enough: start WoW from the desktop while streaming.

## 2. On the phone: StreamTouch

1. Download `StreamTouch-1.0.0.apk` from **Releases**: https://github.com/RappaceFer/StreamTouch/releases
2. Install it (Android asks you to allow installs from your browser or file manager).
3. The app comes **already set up** with Rappace's settings: button layout, sizes, opacity, touch mode at start.
   Change anything later in the round menu (Menu button, or hold Keyboard) > Settings.

## 3. Play at home (same Wi-Fi)

1. Phone and PC on the same network: StreamTouch finds the PC by itself. Otherwise press **+** and type the PC's local address
   (for example `192.168.1.20`, shown by `ipconfig`).
2. Tap the PC: StreamTouch shows a **PIN**. On the PC, in Sunshine's **PIN** tab, type it. This pairing is done once.
3. Tap **Desktop**: the PC desktop appears with the touch controls on top. Start WoW.

## 4. Play away from home: Tailscale

Tailscale links your phone to your PC as if they were at home, encrypted, without opening any port on your router.

1. Create an account on https://tailscale.com (free for personal use).
2. Install Tailscale **on the PC** (https://tailscale.com/download) and sign in.
3. Install Tailscale **on the phone** (Google Play) and sign in with **the same account**. Turn it on.
4. In the Tailscale app, find the PC's address: it starts with `100.` (for example `100.101.102.103`).
5. In StreamTouch: **+**, type that `100.x.x.x` address, then pair with the PIN as in step 3.
   This entry works everywhere, at home and away.
6. To play away: turn Tailscale on on the phone, open StreamTouch, tap the PC.

For a smooth picture away from home (StreamTouch stream settings):
- Start with **60 FPS** and a bitrate around **10 to 15 Mbps** on 4G/5G (20 Mbps or more on good Wi-Fi), then adjust.
- If the picture stutters, lower the bitrate before the resolution.
- Use **H.265 (HEVC)** if your phone supports it: same quality with less bitrate.

## 5. Turn the PC on remotely: the Magic Packet (Wake-on-LAN)

The "Magic Packet" is a small network message that wakes a PC that is off or asleep. Set it up once.

**On the PC:**
1. **BIOS / UEFI** (Del or F2 at boot): enable **Wake on LAN** (sometimes "Power On by PCI-E" or "Resume by LAN").
2. **Windows**: Device Manager > Network adapters > your **Ethernet** adapter > Properties.
   - **Advanced** tab: **Wake on Magic Packet** = Enabled, and **Shutdown Wake-On-LAN** = Enabled.
   - **Power Management** tab: tick "Allow this device to wake the computer" and "Only allow a magic packet to wake the computer".
3. Control Panel > Power Options > "Choose what the power buttons do": untick **Turn on fast startup**
   (otherwise the PC will not wake once shut down).
4. Write down the Ethernet adapter's **MAC address** (`ipconfig /all`, "Physical Address" line).

Wake-on-LAN works over Ethernet; most PCs do not wake over Wi-Fi.

**At home:** in StreamTouch, **long-press the PC > Send Wake-On-LAN request**. Wait 20 to 30 seconds, then tap the PC.

**Away from home:** a sleeping PC is no longer reachable through Tailscale, and the Magic Packet does not cross the Internet by
itself. A device **always on at home** has to send it for you. Either:
- **Your router**: many routers can wake a PC from their app (the Fritz!Box, for example). This is the simplest.
- **A small always-on device** with Tailscale (Raspberry Pi, mini PC, NAS): from the phone, a Wake-on-LAN app (or SSH with the
  `wakeonlan` command and the PC's MAC address) makes it send the Magic Packet on your network.

Then: Tailscale on, StreamTouch, tap the PC.

## 6. In World of Warcraft: the Streaming Touch addon

1. Download `StreamingTouch-2.4.0.zip` from **Releases**.
2. Unzip it into `World of Warcraft\_forever_\Interface\AddOns`: you should get `AddOns\StreamingTouch`.
3. Start the game. The addon comes **already set up**: spell arc around the camera stick with the suggested spells of your
   class, round menu, chat above the phone keyboard. Settings: minimap button or `/stouch`.

Rappace's optional settings, in the [`reglages-wow`](reglages-wow) folder:
- **Addon settings** (`streaming-touch-papa-rapace.txt`): `/stouch` > Commands > **Import settings (text)**, paste, **Import**.
- **Interface layout** (`disposition-mode-edition.txt`): Esc > **Edit Mode** > layout menu > **Import**, paste and name it.

The addon's texts are in French.

## 7. Controls in short

- **Left stick**: move. One tap: Use; double tap: auto run.
- **Right stick**: camera. One tap: target; double tap: jump. The spell arc is around it.
- **The rest of the screen** is a mouse: tap = click, hold = right click, drag, two fingers = scroll wheel.
- **Layer 2** (hold): second spell layer. **Target** held: nearest corpse to loot.
- **Keyboard**: the keyboard (hold: the round menu, with the built-in guide and all settings).

## Common problems

- **The PC does not show up**: same network? Otherwise add it by address (local, or Tailscale's `100.x.x.x`).
- **Works at home but not away**: is Tailscale on, on the phone **and** the PC, with the same account?
- **Black picture or black bars**: set Sunshine's manual resolution to your phone's.
- **The PC does not wake**: Ethernet cable, Wake on LAN in the BIOS, Windows fast startup off.
- **No sound**: check that audio is not muted in StreamTouch's stream settings.
