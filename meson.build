project('gstjitsimeet', 'cpp', version : '0.0', default_options : ['warning_level=3', 'cpp_std=c++23'])
add_project_arguments('-Wfatal-errors', language : 'cpp')
add_project_arguments('-fpermissive', language : 'cpp')
add_project_arguments('-Wno-narrowing', language : 'cpp')
add_project_arguments('-Wno-missing-field-initializers', language : 'cpp')
add_project_arguments('-std=c++23', language : 'cpp')

gstreamer_dep = dependency('gstreamer-1.0', version : ['>=1.20'])


deps = [
  gstreamer_dep,
  dependency('gstreamer-rtp-1.0'),
  dependency('threads'),
  dependency('openssl'),
]


subdir('src/jitsi')

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

# examples - disabled for static builds due to qml6 plugin Qt dependencies
# The main libgstjitsimeet.a library builds fine
# executable('receiver-example', files(
#     'src/gstutil/pipeline-helper.cpp',
#     'src/examples/receiver.cpp',
#   ),
#   dependencies : [gstreamer_dep],
# )
#
# executable('room-to-room-example', files(
#     'src/gstutil/pipeline-helper.cpp',
#     'src/examples/room-to-room.cpp',
#   ),
#   dependencies : [gstreamer_dep],
# )
