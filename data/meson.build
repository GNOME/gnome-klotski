# Install icons
icon_sizes = ['16', '22', '24', '32', '48']
foreach size : icon_sizes
  install_data(
    join_paths('icons', 'hicolor', '@0@x@0@'.format(size), '@0@.png'.format(meson.project_name())),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', '@0@x@0@'.format(size), 'apps')
  )
endforeach
# Install scalable icon
install_data(
  join_paths('icons', 'hicolor', 'scalable', '@0@.svg'.format(meson.project_name())),
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

# Install symbolic icon
install_data(
  join_paths('icons', 'hicolor', 'scalable', '@0@-symbolic.svg'.format(meson.project_name())),
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'symbolic', 'apps')
)

# Install extra icon
install_data(
  '@0@.svg'.format(meson.project_name()),
  install_dir : datadir
)

# Install gschema
install_data(
  '@0@.gschema.xml'.format(project_id),
  install_dir : join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

# Desktop file
desktop_file = i18n.merge_file(
    input: '@0@.desktop.in'.format(meson.project_name()),
    output: '@0@.desktop'.format(meson.project_name()),
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

# Validate desktop file
desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test(
    'validate-desktop --no-net',
    desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

# AppData file
appdata_file = i18n.merge_file(
    input: '@0@.appdata.xml.in'.format(meson.project_name()),
    output: '@0@.appdata.xml'.format(meson.project_name()),
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

# Validate AppData file
appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  test(
    'validate-appdata', appstream_util,
    args: [
      'validate-relax', appdata_file.full_path()
    ]
  )
endif

# Install man page
install_man('@0@.6'.format(meson.project_name()))