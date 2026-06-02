# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dynmap is a dynamic web mapping plugin for Minecraft servers. It targets Paper on Minecraft 1.21.10+ and 26.1.2+ (Paper API for compile; NMS helpers use the matching Spigot server jar from BuildTools for internal types only).

## Build Commands

```bash
# Build all platforms (requires JDK 21 as default)
./gradlew setup build

# Build outputs go to /target directory

# Build specific module (for faster iteration, but NOT for PR submissions)
./gradlew :DynmapCore:build

# Run unit tests (DynmapCore only — JUnit 4)
./gradlew :DynmapCore:test
```

**JDK Requirements:**
- Default: JDK 21
- Runtime targets: JDK 8 (1.16-), JDK 16 (1.17.x), JDK 17 (1.18-1.20.4), JDK 21 (1.20.5+)

**Build notes:**
- `gradle.properties` sets `org.gradle.parallel=false` and `org.gradle.daemon=false` — do not change these
- `snakeyaml` is pinned at 1.23 intentionally — newer versions break on Windows-encoded config files

## Architecture

### Module Structure

**Core Shared Modules:**
- `DynmapCoreAPI/` - Stable public API for external plugins/mods (markers, mod support, rendering). Published to `repo.mikeprimm.com`. The `org.dynmap.renderer` package here defines `DynmapBlockState` — the central block state abstraction used everywhere.
- `DynmapCore/` - Internal shared implementation (NOT stable - subject to breaking changes)
- `dynmap-api/` - Bukkit-specific public API

**Platform Implementations:**
- `spigot/` - Bukkit/PaperMC implementation (`DynmapPlugin.java`)
- `bukkit-helper-121-10`, `bukkit-helper-121-11`, `bukkit-helper-26-1-2` - Version-specific NMS code for Minecraft 1.21.10+ and 26.1.2+

### Dependency Flow
```
External Plugins
    ↓
DynmapCoreAPI (stable, published to repo.mikeprimm.com)
    ↓
DynmapCore (internal, unstable)
    ↓
spigot + bukkit-helper-*
```

### Key Components in DynmapCore

- `DynmapCore.java` — Main coordination hub (~3,100 lines); bootstrapped by each platform
- `MapManager.java` — Tile rendering orchestration; owns the render thread pool and `FullWorldRenderState` queue
- `hdmap/` — HD map rendering pipeline:
  - `IsoHDPerspective` — Isometric raytrace engine (the hot rendering path)
  - `HDBlockModels` / `HDScaledBlockModels` — Block geometry (patch/volumetric/scaled models)
  - `TexturePack` / `TexturePackLoader` — Texture resolution from resource packs
  - `hdmap/renderer/` — Custom block renderers (stairs, fences, doors, etc.) implementing `CustomRenderer`
  - Shaders (`DefaultHDShader`, `CaveHDShader`, `TopoHDShader`, etc.) — post-process pixel color
  - Lighting (`DefaultHDLighting`, `ShadowHDLighting`, etc.) — light level calculation
- `storage/` — Storage backends (FileTree, MySQL, MariaDB, PostgreSQL, SQLite, MSSQL, AWS S3)
- `web/` — Embedded Jetty 9 server with custom HTTP routing (no standard servlet container)
- `markers/impl/` — Full marker system implementation; public interface is in `DynmapCoreAPI`
- `utils/MapChunkCache` + `utils/MapIterator` — Abstract interfaces that each platform implements to feed world data into the renderer

### Platform Integration Pattern

The Spigot module (`bukkit-helper-*`) must implement:
- `MapChunkCache` — Loads and caches chunk data for a tile's required chunks
- `MapIterator` — Block-by-block iteration over the loaded chunk cache
- A platform entry point (`DynmapPlugin` in `spigot/`) that bootstraps `DynmapCore`

The `bukkit-helper-*` modules contain version-specific NMS code; `spigot/` delegates to the appropriate helper at runtime via reflection.

## Testing

Unit tests exist in `DynmapCore/src/test/` (JUnit 4) covering `Matrix3D`, `Vector3D`, `IpAddressMatcher`, `DynIntHashMap`, and `BufferInputStream`. Run with `./gradlew :DynmapCore:test`.

Full verification requires:
1. Building: `./gradlew setup build`
2. Manual testing on target Minecraft server platforms

## Critical Contribution Rules

**PRs must build and test successfully. Changes to DynmapCore/DynmapCoreAPI require a full build.**

- **Java 8 compatibility required** — Code must compile and run on Java 8
- **Java only** — No Kotlin, Scala, or other JVM languages
- **No dependency updates** — Library versions are tied to platform compatibility
- **No platform-specific code** — Must work on Windows, Linux (x86/ARM), macOS, Docker
- **Small PRs only** — One feature per PR, no style/formatting changes
- **No mod-specific code** — Use Dynmap APIs instead; external mods should depend on DynmapCoreAPI
- **Apache License v2** — All code must be compatible
- **DynmapCoreAPI is the only stable API** — Do not add external dependencies on DynmapCore internals
