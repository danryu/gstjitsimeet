#include "jitsibin.hpp"
#include <gst/gst.h>

#ifndef PACKAGE
#define PACKAGE "gstjitsimeet"
#endif

namespace {
auto register_callback(GstPlugin* const plugin) -> gboolean {
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
