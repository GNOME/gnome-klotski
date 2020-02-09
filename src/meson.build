resource_files = files ('@0@.gresource.xml'.format('klotski'))
resources = gnome.compile_resources ('klotski', resource_files)

executable(meson.project_name(),[
        'config.vapi',
        'gnome-klotski.vala',
        'klotski-window.vala',
        'puzzle.vala',
        'puzzle-view.vala'
     ] + resources,
    install: true,
    c_args: [
        '-include', 'config.h'
    ],
    vala_args: [
        '--gresources', resource_files,
        '--target-glib', '2.44',
        '--enable-experimental-non-null',
        '--vapidir', join_paths(meson.current_source_dir(), 'vapi')
    ],
    dependencies: [
        gee_dependency,
        glib_dependency,
        gnome_games_support_dependency,
        gtk_dependency,
        posix_dependency,
        rsvg_dependency
    ]
)
