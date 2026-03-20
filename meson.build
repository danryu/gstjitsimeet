project('gstjitsimeet', 'cpp', version : '0.0', default_options : ['warning_level=3'])

add_project_arguments(
  '-std=c++23',
  '-Wfatal-errors',
  '-fpermissive',
  '-Wno-narrowing',
  '-Wno-missing-field-initializers',
  language : 'cpp'
)

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
