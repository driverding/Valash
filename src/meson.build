srcs = [
  'main.vala',
  'application.vala',
  
  'data.vala',
  'clash.vala',
  'utils.vala',
  
  'graph.vala',
  'proxy-button-box.vala',
  'proxy-group-row.vala',
  'proxy-provider-row.vala',
  'preference-dialog.vala',
  
  'login-window.vala',
  'main-window.vala',
  'overview-page.vala',
  'proxies-page.vala',
  'connection-page.vala',
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

blps = files (
	'proxy-button-box.blp',
	'proxy-group-row.blp',
	'proxy-provider-row.blp',

	'login-window.blp',
	'main-window.blp',
	'overview-page.blp',
	'proxies-page.blp',
	
)

srcs += gnome.compile_resources ('gresources', 'valash.gresource.xml',
  c_name: 'valash',
  dependencies: custom_target ('blueprints',
    input:   blps,
    output:  '.',
    command: [find_program ('blueprint-compiler'), 
      'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'
    ],
  )
)

deps = [
  dependency ('gtk4'),
  dependency ('libadwaita-1', version: '>= 1.4'),
  dependency ('gio-2.0'),
  dependency ('gee-0.8'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0'),
]

executable ('valash', srcs,
  dependencies: deps,
  install:      true,
)
