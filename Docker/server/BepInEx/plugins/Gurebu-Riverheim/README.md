# Riverheim

Riverheim is a comprehensive overhaul of terrain and biome generation for Valheim.

It aims to provide a definitive upgrade to the game's terrain generation but to also preserve the look, feel and balance of all the biomes. You will still be playing Valheim, but with terrain that is more varied and exciting.

### Features

- Landmasses are greater in variety. Most worlds will have a few continents significantly larger than what was possible in vanilla and a scattering of smaller islands.
- Rivers now have sources and can join with other rivers at confluences as they flow towards the sea.
- Mountains are larger, more epic and tend to conform to the river network.
- Biome distribution is less random and more aware of the terrain and features around.
- Biomes are budgeted meaning worlds are guaranteed to have a certain amount of each biome.
- Greater overall variety of terrain, with steep cliffs, large swathes of lowlands, landmarks and other features meant to enhance nomap playthroughs.
- Landforms are completely unique to each seed, there's no "master map" and no repetition.
- All major platforms should be supported at least for 64-bit architectures. You can use the mod with a 32-bit system, and it will work, but multiplayer syncing has not been tested, so you're on your own here. I've also not tested the mod on Windows on ARM, but don't see a reason why it wouldn't work.
- Multiplayer is supported, but the server and every client all need to have the same version of the mod.

What isn't in the mod:

- No changes to how the game will place points of interest, trees and other objects. Stuff might end up in places that seem weird, but that's entirely due to how original placement code works.
- No progression breaks beyond what was already possible (for example, Ashlands is still on the South Pole and you will still need to navigate the boiling ocean to reach it).
- No UI changes.

Example worlds for the same seed:

| Vanilla                                    | Modded                                    |
|--------------------------------------------|-------------------------------------------|
| ![vanilla](https://imgur.com/6eMJCyV.jpeg) | ![modded](https://imgur.com/ql6C0Bt.jpeg) |

### Configuration & Usage Instruction

No configuration is available to the end user at the moment, just install the mod, create a new world and enjoy! Keep in mind, however, that the way the game generates terrain will require you to keep Riverheim (or any other terrain generation mod for that matter) on at all times. To avoid unexpected terrain changes Riverheim and vanilla worlds are two-way incompatible: you can't load a vanilla world with a modded client and vice versa. Incompatible worlds will show with a `[BAD_VERSION]` label in-game.

Install Riverheim with your mod manager as you would any other mod. If you're not using a mod manager, all you need to install Riverheim is to put the mod's dll (Riverheim.dll) into BepInEx's plugin folder.

If you've got any further questions or feedback, join the [Discord server](https://discord.gg/ES3J7mu6kW).

### Updates & World Stability

All the worlds created with Riverheim are intended to stay unchanged forever, even across updates to the mod or the game. Unless something truly catastrophic happens that will make this impossible, they're safe as "forever worlds". Doesn't hurt to make back-ups, though.

There's an exception here, and it's Deep North. Like the vanilla game, Riverheim will produce some stub terrain for Deep North, but it will be updated some time after Deep North goes live. Unless you're willing to start a new world with Valheim's upcoming 1.0 release or are skilled enough with modding to reset a part of your world, venturing into Deep North is best avoided.

### Performance

Riverheim will add a few seconds (depending on your machine) of loading time for your worlds for preprocessing. Real-time terrain generation is also quite a bit more sophisticated and is a little slower than vanilla, but not by a lot.

### Compatibility

Riverheim is a large mod, but for its size it patches a surprisingly low amount of the game's code. This makes it highly compatible both with other mods and with game updates, the exception being other world generation mods or game updates that alter world generation.

#### Compatibility with select worldgen mods

- **Better Continents**: `INCOMPATIBLE`. This is an alternative way to generate terrain, so you have to choose one or the other. Riverheim will not load when BetterContinents is present.
- **Expand World Size**: `MIXED`. At the moment only stretching is supported, so make sure that your stretching multiplier and world size (with edge added) increase match in value. You also need to exactly match terrain and biome stretching.
- **Expand World Data**: `MIXED`. Mods will load together, but EWD will override Riverheim's biome distribution (with catastrophic results) unless both `World Data` and `Biome Data` are disabled in EWD's config.
- **Expand World Rivers**: `INCOMPATIBLE`. EWR is designed to alter vanilla rivers which Riverheim doesn't use, there's no purpose to loading them together.
- Rest of the **Expand World** suite: `OK`. Those mods don't touch terrain or biome generation, so they play with Riverheim well.
- Worldgen mods that don't alter terrain or biome distribution like adding trees or locations: `OK`.

#### Example config for EWS for 2.0x world size with stretching

```ini
World radius = 20500
World edge size = 500
Stretch world = 2.0
Stretch biomes = 2.0
```

### Fate of the Beta

[Riverheim's beta](https://thunderstore.io/c/valheim/p/Riverheim_Dev/Riverheim/) is now deprecated. It might receive updates if a game patch breaks it down and the fix is simple enough, but nothing beyond that. Worlds created with Riverheim's beta are not compatible with 1.0 and beyond, and it's unfortunately not possible to make them so. You can still play them for as long as you want, you can't break them with the new version as they just won't load.

### Credits

This mod wouldn't have been possible without inspiration and help. Special thanks to:

- [Red Blob Games](https://www.redblobgames.com/) blog that gave the initial inspiration for this mod.
- [Sebastian Lague](https://www.youtube.com/@SebastianLague)'s YouTube channel on procedural generation.
- The amazing [DelaunatorSharp](https://github.com/nol1fe/delaunator-sharp) library.
- [BepInEx](https://github.com/AzumattDev/BepInEx) for making Valheim modding possible.
- [Iron Gate](https://www.valheimgame.com/) for making the game we love.
- Everyone on the discord server for helpful feedback and kind words.

### Screenshots

![01](https://imgur.com/WqEnIx7.jpeg)
![02](https://imgur.com/btIL1OT.jpeg)
![03](https://imgur.com/vvPOKia.jpeg)
![04](https://imgur.com/MJ1u12v.jpeg)
![05](https://imgur.com/WGJRKV4.jpeg)
![06](https://imgur.com/MoNuhou.jpeg)
![07](https://imgur.com/PSlWqLc.jpeg)
![08](https://imgur.com/su0r67x.jpeg)
![09](https://imgur.com/DjOYcrR.jpeg)
![10](https://imgur.com/AhST3QQ.jpeg)
![11](https://imgur.com/lTbJdfQ.jpeg)
