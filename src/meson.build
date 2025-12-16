subdir('ui')

valash_sources = [
  'main.vala',
  'application.vala',

  'login-window.vala',
  'main-window.vala',

  'overview-page.vala',
  'proxies-page.vala',
  'connection-page.vala',

	'proxy-provider-row.vala',
	# 'proxy-group-row.vala',
	'proxy-button-box.vala',
  'graph.vala',

  'clash.vala',
  'utils.vala',
]

valash_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('gio-2.0'),
  dependency('gee-0.8'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0'),
]

valash_sources += gnome.compile_resources('valash-resources',
  'valash.gresource.xml',
  c_name: 'valash',
  dependencies: custom_target(
		'blueprints',
		input: blueprints,
		output: '.',
		command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
  )
)

executable('valash', valash_sources,
  dependencies: valash_deps,
  include_directories: config_inc,
       install: true,
)
