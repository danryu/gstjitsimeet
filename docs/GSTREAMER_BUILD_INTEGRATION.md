# Integrating gstjitsimeet with gst-build (static gst-full)

This document explains the changes made to `gstjitsimeet` so it can be consumed as a Meson subproject by GStreamer's `gst-build` and linked into the static `libgstreamer-full-1.0.a` build.

## Summary of required changes

- Export the plugin via `GST_PLUGIN_DEFINE` so a static registration symbol is available (`gst_plugin_jitsimeet_register`).
- Provide a local `PACKAGE` macro when not using Autotools-generated `config.h` (needed by `GST_PLUGIN_DEFINE`).
- Export the plugin target via Meson's `gst_plugins` variable so `gst-build` can discover and link it into `gst-full`.
- Include libnice's public umbrella header `<nice.h>` instead of a private path.

## Details

### 1) Plugin entry point for static gst-full

`gst-build` generates a `gstinitstaticplugins.c` and calls `GST_PLUGIN_STATIC_REGISTER(jitsimeet)`. That requires the symbol `gst_plugin_jitsimeet_register`, which is emitted by `GST_PLUGIN_DEFINE`.

The plugin entry was updated accordingly:

```cpp
#include "jitsibin.hpp"
#include <gst/gst.h>

#ifndef PACKAGE
#define PACKAGE "gstjitsimeet"
#endif

namespace {
static gboolean register_callback(GstPlugin* plugin) {
    return gst_element_register(plugin, "jitsibin", GST_RANK_NONE, gst_jitsibin_get_type());
}
} // namespace

GST_PLUGIN_DEFINE(
    GST_VERSION_MAJOR,
    GST_VERSION_MINOR,
    jitsimeet,
    "Jitsi Meet gst binding",
    register_callback,
    "1.0",
    "LGPL",
    "unknown",
    "unknown"
)
```

Notes:
- `GST_PLUGIN_DEFINE` uses `PACKAGE` for the `source` field. Because this project does not use Autotools, we define `PACKAGE` locally to a sensible string.

### 2) Meson export for gst-build discovery

`gst-build` expects subprojects to export a `gst_plugins` array of dependencies describing plugin targets. `gstjitsimeet/meson.build` was adjusted to name the library target and export it:

```meson
gstjitsimeet_plugin = library('gstjitsimeet', files(
  'src/lib.cpp',
  'src/jitsibin.cpp',
  'src/props.cpp',
) + libjitsimeet_src,
  dependencies : deps + libjitsimeet_deps,
  install : true,
  install_dir : get_option('libdir') / 'gstreamer-1.0',
)

gst_plugins = [
  declare_dependency(
    link_with: gstjitsimeet_plugin,
    variables: {'full_path': gstjitsimeet_plugin.full_path()}
  )
]
```

This lets `gst-build` add the plugin to the `all_plugins` list and link it into `gst-full`.

### 3) Libnice public header

The include was updated from a private header path to the public umbrella header so it works both in-tree and when installed:

```diff
-#include <nice/agent.h>
+#include <nice.h>
```

## Integration notes for gst-build

- Add a wrap or symlink for this repo under `gstreamer/subprojects/gstjitsimeet`.
- Configure `gst-build` with `-Dcustom_subprojects=gstjitsimeet` so it is picked up.
- Ensure external deps are resolvable during configure:
  - `libnice` is built as a subproject by `gst-build` and is overridden via `meson.override_dependency('nice', ...)`.
  - `coop` is provided via pkg-config. If built inside this repo, expose:
    `subprojects/gstjitsimeet/deps/coop-install/lib/pkgconfig` in `PKG_CONFIG_PATH` before configuring.

## Why these changes are needed

- Without `GST_PLUGIN_DEFINE`, the static gst-full build cannot find the required registration symbol and fails to link user apps with `undefined symbol: _gst_plugin_jitsimeet_register`.
- Without `gst_plugins` export, `gst-build` would not discover the plugin target for inclusion in `gst-full`.
- Using `<nice.h>` avoids relying on private include layout and matches libnice's public API.

## App linking tips

When linking against `libgstreamer-full-1.0.a`, you generally do not need to link individual plugin static libraries manually; gst-full registers them at startup via `gst_init_static_plugins()`. Only add plugin `.a` libraries to `target_link_libraries()` if you intentionally want to force-link them for reachability.

