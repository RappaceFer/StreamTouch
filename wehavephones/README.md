# StreamTouch layout for WeHavePhones

`StreamTouch-WoW.icp` is an on-screen controls profile for [WeHavePhones](https://github.com/ashmerra/wehavephones)
(Winlator format) that follows the StreamTouch layout, made to go with the Streaming Touch WoW addon.

**Import:** in WeHavePhones, Input Controls → Import Profile → choose `StreamTouch-WoW.icp`.

| Control | Key | Where |
| --- | --- | --- |
| Move stick | W A S D | bottom left |
| Camera area (trackpad) | mouse | bottom right, the addon's spell arc sits around it |
| Cam (toggle) | holds the right mouse button, so the camera area turns the view | right |
| Esc | Esc | right |
| Target / Use / Jump / Run | Tab / F / Space / Num Lock (auto run) | above the move stick |
| L2 | F12: second layer of the addon's spell arc | right of the move stick |
| Map / Bags / Talents | M / B / N | top right |

Positions and sizes are a starting point: adjust them in WeHavePhones' controls editor.
In StreamTouch, taps on the sticks also act as buttons (tap the move stick = Use, double tap = auto run; tap the camera
stick = target, double tap = jump). That needs code in the app: see
[`StickTapGesture.java`](../app/src/main/java/com/limelight/wowtouch/StickTapGesture.java), also available under the
MIT License (see `LICENSE-MIT-couche-tactile.txt`).

---

**Français :** profil de commandes à l'écran pour WeHavePhones, sur la disposition de StreamTouch. Import : Input Controls →
Import Profile → `StreamTouch-WoW.icp`. Les places et tailles se règlent ensuite dans l'éditeur de commandes de WeHavePhones.
