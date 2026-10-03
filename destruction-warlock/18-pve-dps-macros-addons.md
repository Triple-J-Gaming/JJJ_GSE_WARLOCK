# Destruction Warlock DPS Macros and Addons

Source: https://www.icy-veins.com/wow/destruction-warlock-pve-dps-macros-addons
Retrieved: 2026-10-03

On this page, you will find a number of useful macros and addons to make your life easier when playing your Destruction Warlock in World of Warcraft Patch 12.1.

## Best Macros

Below are examples of useful macros; you can adapt them for whatever spell you deem fit.

### Pet Macros

These macros allow you to manage your demon, as playing with your Pet Stance on Assist is the preferred way to play.

Pet Attack
/petattack
 Copy

This orders your demon to attack your target.

Pet Follow
/petfollow
 Copy

This orders your demon to follow you.

Pet Move
/petmoveto
 Copy

This orders your demon to move to a location specified by you. This macro is especially useful for situations where you need your pet in a predetermined position in order to accomplish a given task — such as an interrupt on a otherwise out of range target — but can also be used to maximize Felguard cleave/ Felstorm damage, just be aware that any imparted commands will also make your Dreadstalkers, Vilefiend (if talented) and Tyrant move, resulting in a much bigger loss when used improperly.

#### DoT Mouseover
Corruption Mouseover
#showtooltip Corruption
/use [@mouseover,harm] [harm] Corruption
 Copy

Casts Corruption on current mouseover target if hostile and alive, else cast it on your current target.

Worth mentioning that Blizzard has added the ability to toggle all casts to follow a mouseover logic in the control settings, however some abilities may not function correctly, and thus it is still recommended to take the time and make a macro for any ability with a mouseover use case.

#### Banish Focus
Banish Focus
#showtooltip Banish
/use [mod:shift,@focus] [] Banish
 Copy

Cast Banish on focus target by holding also shift, else cast it on your current target.

#### Soulstone Mouseover
Soulstone Mouseover
#showtooltip Soulstone
/target [@mouseover] Soulstone
/use Soulstone
/targetlasttarget
 Copy

Workaround macro for the current bug related to mouseover dead allies. The Macro itself will target the mouseover in order to cast Soulstone then target the previous target.

#### Demonic Circle
Demonic Circle
#showtooltip
/stopcasting
/use [mod:shift] Demonic Circle(Summon); [nomod] Demonic Circle: Teleport(Teleport)
 Copy

Place the Demonic Circle while holding shift, or teleport to the circle without any modifiers, while cancelling any ongoing casts. This saves you the trouble (and the time!) of interrupting your spell cast manually.

#### Shadowfury/Howl of Terror
Shadowfury/Howl of Terror
#showtooltip
/use [known:Shadowfury,@cursor] Shadowfury; [known:Howl of Terror] Howl of Terror
 Copy

Depending on the talent selected cast Shadowfury at cursor or Howl of Terror instead.

### Havoc
Havoc
#showtooltip
/cast [@mouseover,harm] Havoc; [harm] Havoc
 Copy

This macro casts Havoc on your mouseover target if you have any, otherwise it casts it on your target (provided it is an enemy). Mouseover macros are not recommended for this ability, as it can easily lead to applying Havoc to the wrong target. Only use this if mouseovers are your preference.

### Cursor Rain of Fire
Cursor Rain of Fire
#showtooltip
/cast [@cursor] Rain of Fire
 Copy

Some people might find this macro very useful. It places the Rain of Fire where your cursor is, instead of having to constantly place the green circle where you want it. It can be a much quicker way to put Rain of Fire down.

### Cursor Cataclysm
Cursor Cataclysm
#showtooltip
/cast [@cursor] Cataclysm
 Copy

Similar to the above macro, this one cast Cataclysm at cursor bypassing the reticle and the need to click twice.

### Shadowburn
Shadowburn
#showtooltip
/cast [known:Shadowburn,@mouseover,harm] Shadowburn;
[known:Shadowburn,harm] Shadowburn
 Copy

This is a mouseover macro for Shadowburn as it helps sniping dying targets from nameplates quicker than targeting them individually. If no targets are available on mouse location it will cast on your current target instead.

## Best Addons

Before you go downloading a bunch of different Addons, we recommend you set up your base UI first. Blizzard has added a wide variety of improvements to the base UI, and many Addons you may think you cannot do without, are now available through the standard interface. Once you've set up your UI, we recommend thinking about which aspects or customization layers you would like to add, and then look for Addons that do those things, instead of downloading an entire suite's worth of Addons that you may not even need anymore.

It might even be worth it to see how far you can get without any additional Addons, and maybe you'll even enjoy not having to spend hours every Patch updating and reconfiguring your UI. Many Addons are still in development or are specifically aiming to launch with all their options for Midnight launch, so some of your favorites may not be available just yet.

### ElvUI

ElvUI is a complete replacement for the default User Interface, and you will often find even the best players in the world use ElvUI for certain customization options. ElvUI is extremely user friendly, and takes very little time to set up and master. It also comes already furnished with almost everything you need; unit frames, raid frames, minimap, buffs and debuffs, and much more. You can easily unlock and drag all the components around so your UI will look exactly the way you want it to. ElvUI is clean, easy to use, and a great starting point for your UI.

### Boss Mods

Boss Mods are helpful pre-made timers that allow you to keep track of the noteworthy mechanics in any given encounter. Usually they come equipped with helpful prompts, visuals, and sounds to ensure you do not miss anything important.

#### BigWigs Bossmods

BigWigs is the best boss mod available currently. It is extremely customizable, allowing you to change what is displayed on an individual boss level and how boldly you want each alert customized.

#### LittleWigs Bossmods

This is really just BigWigs, but for dungeons. It has the same customization options, and allows you to prepare as best as you can for all mechanics that will be thrown at you in regular or Mythic+ dungeons.

#### Deadly Boss Mods

Deadly Boss Mods is an alternative to BigWigs, and offers almost the exact same customization options for keeping track of boss abilities, trash mobs, and combat timers. It is a great tool to help you focus more on your own character, instead of having to worry about keeping track of all those pesky boss mechanics!

### Name Plates

Nameplates are essential for allowing you to easily keep track of basic debuffs and quickly select new targets in combat. While ElvUI nameplates do come standard with the AddOn, they are a little limited and occasionally buggy. Listed below are some good alternatives.

#### Plater Nameplates

Plater offers a very high degree of customization and accuracy, although somewhat limited due to the Addon changes in Midnight. You can still configure the nameplates to enlarge and change color in certain circumstances, and it might help you keep track of important buffs and debuffs in a chaotic fight, so you do not get lost in the weeds. Some setup is required, although it is very simple and straightforward.

#### Platynator

Platynator is a new Addon developed by plusmouse, who is known for many super helpful addons like Auctionator, Baganator, Prat, and many more. They have now developed a very customizable Nameplate addon that offers numerous options for debuffs, status colors, icons, textures, and much more. It is definitely worth checking out, especially if you end up having any issues with Plater for any reason.

#### Details

Details is still around as the #1 Addon to customize damage and healing meters. While it may not offer as many tracking options as before due to the limits imposed by Blizzard, it is still around and kicking to help you customize the Blizzard Damage, Healing, and Other metrics pane.
