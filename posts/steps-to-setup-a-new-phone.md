+++
date = "6/27/2021"
title = "Steps to setup a new phone"
tags = ["guides"]
rss_description = "Follow the steps to de-bloat a stock android phone"
+++

- Find the phone based on your preferences, amazon warehouse deals or aliexpress refurbished have the best bang for the buck AFAIK.
- The phone might require an unlock code from the manufacturer
- Check in fastboot `oem unlock` if it requires a code
- Consider if a OEM stock firmware has to be flashed from fastboot before flashing a custom ROM (check flashfile.xml)
- Flash a recovery `fastboot flash recovery twrp.bin`
- Boot into recovery flash rom
- Flash microG through the unofficial setup script
- Flash magisk
- Magisk module uninstaller to remove modules causing bootloops from recovery
- Maybe flash a custom kernel
- Check microG self-test to see what needs to be configured (apk spoofing, unified nlp, etc)
- Install xposed with magisk
- Configure lucky patcher
- Install markets: f-droid, aurora, aptoide
- Replace apps: calendar->etar, messages->signal(session?), mail->deltachat(or nothing..), keyboard->anysoftkb, files->mixplorer, browser->bromite/firefox, youtube->newpipe, camera->open camera, music->vynil/phonograph, workspaces->shelter
- Battery apps: betterbatterystats, stop battery charging (should not be needed), greenify
