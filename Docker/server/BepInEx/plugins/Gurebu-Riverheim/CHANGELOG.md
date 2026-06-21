## v1.0.0

The release version, a major overhaul of all aspects of Riverheim.

- **New feature: budgeted generation** of biomes, lakes and mountains. Worlds are more consistent and even outliers should be playable.
- **New feature: channels** can cut through larger landmasses to connect distant bodies of water.
- **New feature: sub-biomes** present themselves to Valheim as existing biomes, but have distinct terrain.
- Marsh is a rare sub-biome of meadows that is mostly submerged in water. Patches of marsh can be found adjacent to water sources.
- Mistglade is a rare sub-biome of mistlands with mellow terrain and no mist. Patches of mistglade can be found deep within their parent biome.
- Mountains are rarer and grander in scale.
- More variety in the river network.
- Various local terrain features at key locations like river sources.
- Improved cliffs and biome-specific terrain variations.
- Ashlands no longer borrows terrain generation from the base game.
- Independent generation of different regions of the world to prepare for Deep North.
- New metadata format for save files. Some of the generation parameters are now stored in the save file enabling safe updates.
- Consistent generation across different 64-bit platforms.
- Improved performance.
- Innumerable improvements to the foundation code to ensure stability and reproducibility.

#### v0.12.0

- Merged mod assemblies into one.
- Rivers are now approximated by segments rather than points, eradicating occasional unnatural looks at low widths.
- River profile has changed to be less extreme at large heights, resulting in fewer blending artifacts.
- Different rivers are now blended separately which should eliminate sharp rock formations between them.
- River rendering has been optimized to be marginally faster.
- The above changes produce difference in heightmap compared to 0.11, but it is not drastic and is only contained in close proximity to rivers.

### v0.11.0

- Fixed a bug that occasionally prevented joining other servers with a client with other mods installed that presented in an "Incompatible version" error when in fact versions have been compatible.
- Starting from 0.11, version checks are relaxed to ***major.minor***. Patch versions are going to be compatible between each other.

#### v0.10.1

- Fixed a bug introduced in 0.10.0 that made all terrain rocky and impossible to cultivate.

### v0.10.0

- Fixed fish spawning, oceans are now slightly less deep so fish can properly rise to the surface.
- Fixed leviathans barely spawning.
- Slightly lowered overall height of Swamp, improving spawn of locations like the Bog Witch.
- Reduced the amount of unnavigable shallows at the coast of Plains.
- Added support for the None biome to support custom biomes in other mods. It will just use base heights with rivers/splats.
- Added world metrics logging after world generation.
- Patched server-side startup so that the server will terminate with an exception instead of silently creating a new world upon attempt to load a world that's not compatible.

#### v0.9.2

- Added a changelog
- Added a discord server link to the README (join and provide feedback!)

## v0.9.0

- Initial release
