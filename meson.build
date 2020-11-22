project('gnome-klotski', 'vala', 'c',
        version: '3.38.2')

project_id = 'org.gnome.Klotski'

# used to install help
gnome = import('gnome')
# used for internationalization
i18n = import('i18n')
# used to run post install script
python3 = import('python3')

gee_dependency = dependency('gee-0.8')
glib_dependency = dependency('glib-2.0', version: '>= 2.42.0')
gnome_games_support_dependency = dependency('libgnome-games-support-1', version: '>= 1.7.1')
gtk_dependency = dependency('gtk+-3.0', version: '>= 3.24.0')
rsvg_dependency = dependency('librsvg-2.0', version: '>= 2.32.0')
posix_dependency = meson.get_compiler('vala').find_library('posix')

appstream_util          = find_program('appstream-util',        required: false)
desktop_file_validate   = find_program('desktop-file-validate', required: false)
glib_compile_schema     = find_program('glib-compile-schemas',  required: true) # useful?

# Set gettext package name
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language: 'c')

localedir   = join_paths(get_option('prefix'), get_option('localedir'))
datadir     = join_paths(get_option('prefix'), get_option('datadir'))
bindir      = join_paths(get_option('prefix'), get_option('bindir'))
icondir     = join_paths(datadir, 'icons', 'hicolor')
pkgdatadir  = join_paths(datadir, meson.project_name())

conf = configuration_data ()
conf.set_quoted ('VERSION', meson.project_version())
conf.set_quoted ('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted ('DATA_DIRECTORY', pkgdatadir)
conf.set_quoted ('LOCALEDIR', localedir)

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

subdir('data')
subdir('help')
subdir('po')
subdir('src')

meson.add_install_script(python3.find_python().path(),
                         join_paths(meson.source_root(), 'build-aux', 'meson_post_install.py'))
