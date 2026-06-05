project ('valash', ['c', 'vala'],
  version:         '0.0.1',
  meson_version:   '>= 1.0.0',
  default_options: ['warning_level=2', 'werror=false']
)

application_id = 'com.github.driverding.Valash'

i18n  = import ('i18n')
gnome = import ('gnome')

add_project_arguments ('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()), language: 'c')

subdir ('po')
subdir ('data')
subdir ('src')

gnome.post_install (
  glib_compile_schemas:    true,
  gtk_update_icon_cache:   true,
  update_desktop_database: true,
)
