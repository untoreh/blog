+++
date = "8/3/2022"
title = "Why Windows is an unfixable mountain of bugs"
tags = ["software"]
rss_description = "Windows (11) rant."
+++

Here's is a list of reasons why windows will never be better than shifting sands.

### It's full of telemetry
How many endpoints does the OS ping? how frequently? Can telemetry be disabled entirely? Probably not.
The OS is not developed with telemetry disabled, it will incur in some weird timeouts / stalls behaviour because it expects MS endpoints to be _reachable_.

### Cryptic error codes with unspecified causes
All Windows give you when something goes awry is an error code, almost never an error message, and if it does it is incomprehensible because it references some runtime that is most likely closed source. 

### ACL everywhere
Of course, ACL is the better security model. Good luck finding out where and what permissions are required when you get a permission denied error.

### Drivers
Windows hasn't recognized this device...So how do you fix this? Can I poke somewhere pretty please? 
I am not even mentioning _driver signatures_.

### User State
User data is stored in `%APPDATA%` `local` and `roaming`. If I browse the two folders I don't see clear definitions, some apps store cache in one folder despite it being for _configuration_ others do the opposite...Does windows even have proper conventions?

### Windows has no PATH
Every binary is usually store within its own directory (along with all the vendored dependencies). If you try to generalize the path you would end up with a list of thousand directories where binaries are stored, at least there is `scoop`.

### Windows updates are pushed...very angrily
Apparently can happen that windows pushes bad updates, which than pulls back, or updates that aren't even for the platform that their are pushed to! Also there is no mention of windows upgrades being atomic, so every time you perform an upgrade, you are rolling the dice.

### UI
The windows shell is more like a `kiosk` than an UI you can press buttons and click on stuff, as long as it is sanctioned by the windows UI team, there is no proper API for shortcuts. Every application to configure keyboard shortcuts is a hack.
