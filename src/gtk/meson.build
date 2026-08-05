blps = files (
  'proxy-button-box.blp',
  'proxy-group-row.blp',
  'proxy-provider-row.blp',
  'preferences-dialog.blp',
  'login-window.blp',
  'main-window.blp',
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