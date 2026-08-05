srcs = [
  'main.vala',
  'application.vala',
  
  'json.vala',
  'clash.vala',
  'utils.vala',
  
  'graph.vala',
  'proxy-button-box.vala',
  'proxy-group-row.vala',
  'proxy-provider-row.vala',
  'connection-view.vala',
  'preferences-dialog.vala',
  
  'login-window.vala',
  'main-window.vala',
]

conf = configuration_data ()
conf.set_quoted ('APPLICATION_ID', application_id)
conf.set_quoted ('VERSION', meson.project_version ())
conf.set_quoted ('GETTEXT_PACKAGE', meson.project_name ())
conf.set_quoted ('LOCALEDIR', get_option ('prefix') / get_option ('localedir'))

srcs += configure_file (
  configuration: conf,
  input:         'config.vala.in',
  output:        'config.vala',
)

subdir ('gtk')

deps = [
  dependency ('gtk4'),
  dependency ('libadwaita-1', version: '>= 1.4'),
  dependency ('gio-2.0'),
  dependency ('gee-0.8'),
  dependency ('libsoup-3.0'),
  dependency ('json-glib-1.0'),
]

executable ('valash', srcs,
  dependencies: deps,
  install:      true,
)
