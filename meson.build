project('gstjitsimeet', 'cpp', version : '0.0', default_options : ['warning_level=3', 'cpp_std=c++23'])
cpp_compiler = meson.get_compiler('cpp')
if cpp_compiler.get_id() == 'msvc'
  add_project_arguments(['/std:c++latest', '/permissive-', '/Zc:preprocessor', '/EHsc', '/bigobj', '/DNOMINMAX', '/D_ITERATOR_DEBUG_LEVEL=0', '/MD'], language : 'cpp')
  add_project_link_arguments('/NODEFAULTLIB:LIBCMTD', language: 'cpp')
  add_project_link_arguments('/NODEFAULTLIB:MSVCRTD', language: 'cpp')
  add_project_link_arguments('/OPT:NOREF', language: 'cpp')
else
  add_project_arguments(['-Wfatal-errors', '-fpermissive', '-Wno-narrowing', '-Wno-missing-field-initializers', '-std=c++23'], language : 'cpp')
endif

gstreamer_dep = dependency('gstreamer-1.0', version : ['>=1.20'])

deps = [
  gstreamer_dep,
  dependency('gstreamer-rtp-1.0'),
  dependency('threads'),
  dependency('openssl'),
]

subdir('src/jitsi')

library('gstjitsimeet', files(
    'src/lib.cpp',
    'src/jitsibin.cpp',
    'src/props.cpp',
  ) + libjitsimeet_src,
  include_directories : include_directories('src/jitsi'),
  dependencies : deps + libjitsimeet_deps,
  install : true,
  install_dir : get_option('libdir') / 'gstreamer-1.0',
)

