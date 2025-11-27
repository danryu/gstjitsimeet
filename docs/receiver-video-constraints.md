## Receiver video constraints (Colibri) in gstjitsimeet

### Background
- JVB defaults new receivers to `defaultConstraints.maxHeight = 180`, which yields ~180p tiles until the client asks for more.
- Clients must send a Colibri bridge-channel message of class `ReceiverVideoConstraints` to raise quality.
- This message must be sent after the endpoint is established (after Jingle "accept").

See `jitsi-videobridge/doc/allocation.md` for the full spec and examples.

### What we implemented
- Added Colibri helpers in `libjitsimeet`:
  - `Colibri::set_last_n(int n)`
  - `Colibri::set_default_max_height(int maxHeight)` → sends:
    {"colibriClass":"ReceiverVideoConstraints","defaultConstraints":{"maxHeight":<value>}}
  - Both calls log the exact JSON payload; the WebSocket client can dump frames for verification.

- Exposed a new GObject property on `jitsibin`:
  - `receive-max-height` (int)
    - -2: do not send any defaultConstraints (keep JVB default)
    - -1: unlimited (no constraint)
    - >=0: set `defaultConstraints.maxHeight` to that value

- Corrected send timing in `jitsibin`:
  - Connect to Colibri and send ReceiverVideoConstraints only after sending the Jingle `accept` IQ.
  - Drive the Colibri WebSocket briefly to flush outbound messages.

### Usage
- Configure `jitsibin` properties when building the pipeline:
  - `"receive-max-height", -1` to request highest available layers.
  - Optionally `"receive-limit", N` to control LastN.
  - Ensure sender codec is VP9 (or AV1) if you want scalable layers.

Example payloads sent (logged):
- {"colibriClass":"ReceiverVideoConstraints","lastN":3}
- {"colibriClass":"ReceiverVideoConstraints","defaultConstraints":{"maxHeight":-1}}

#### Runtime per-source control (source names)
- Call from your app at any time to change just one source (e.g., `"<endpointId>-v0"`):

```cpp
#include "jitsibin.hpp"

// Raise a specific source to 720p
gst_jitsibin_set_source_max_height(jitsibin, "22bbfb7a-v0", 720);

// Drop it back to 180p
gst_jitsibin_set_source_max_height(jitsibin, "22bbfb7a-v0", 180);
```

### Verifying it works
- App logs (stdout):
  - Look for lines starting with `Colibri send:` showing the JSON we transmit.
  - With websocket dump enabled, you will see server frames like `{"colibriClass":"ServerHello"}` and `ForwardedSources`.

- JVB logs (enable DEBUG for these packages):
  - `org.jitsi.videobridge.message`
  - `org.jitsi.videobridge.cc.allocation`
  - You should see handling of `ReceiverVideoConstraints` and changes in effective constraints/allocations.

### Troubleshooting
- Still 180p:
  - Confirm the `ReceiverVideoConstraints` JSON is sent after `accept` (check order in logs).
  - Ensure `receive-max-height` is `-1` or a sufficiently high target (e.g., 720/1080).
  - Bandwidth estimation may cap actual forwarded layers under poor network conditions.
  - You can force prioritization by sending `onStageEndpoints`/`onStageSources` for the desired remote source.

### Future extensions
- Per-source constraints using `constraints: { "<sourceName>": { "maxHeight": ... } }`.
- Set `onStageSources` or `selectedSources` to prioritize important videos (e.g., screenshare).

### Code touchpoints
- `gstjitsimeet/submodules/libjitsimeet/src/colibri.hpp|.cpp` — Colibri helpers, websocket logging.
- `gstjitsimeet/src/props.hpp|.cpp` — new `receive-max-height` property.
- `gstjitsimeet/src/jitsibin.cpp` — send constraints after `accept`, flush websocket.
- Example: `gstreamer-build/example_04_qnujitsi/main.cpp` — set `"receive-max-height", -1`.



