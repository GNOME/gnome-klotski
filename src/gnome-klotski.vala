/*
   This file is part of GNOME Klotski.

   Copyright (C) 2010-2013 Robert Ancell

   GNOME Klotski is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   GNOME Klotski is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with GNOME Klotski.  If not, see <https://www.gnu.org/licenses/>.
*/

using Gtk;

private class Klotski : Gtk.Application
{
    /* Translators: application name, as used in the window manager, the window title, the about dialog... */
    internal static string PROGRAM_NAME = _("Klotski");

    private KlotskiWindow window;

    private const OptionEntry [] option_entries =
    {
        /* Translators: command-line option description, see 'gnome-klotski --help' */
        { "version", 'v', OptionFlags.NONE, OptionArg.NONE, null, N_("Print release version and exit"), null },
        {}
    };

    private const GLib.ActionEntry action_entries [] =
    {
        { "quit", quit }
    };

    /*\
    * * application life
    \*/

    private static int main (string [] args)
    {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        Environment.set_application_name (PROGRAM_NAME);
        Window.set_default_icon_name ("org.gnome.Klotski");

        Klotski app = new Klotski ();
        return app.run (args);
    }

    private Klotski ()
    {
        Object (application_id: "org.gnome.Klotski", flags: ApplicationFlags.FLAGS_NONE);

        add_main_option_entries (option_entries);
    }

    protected override int handle_local_options (GLib.VariantDict options)
    {
        if (options.contains ("version"))
        {
            /* NOTE: Is not translated so can be easily parsed */
            stdout.printf ("%1$s %2$s\n", "gnome-klotski", VERSION);
            return Posix.EXIT_SUCCESS;
        }
        return -1;
    }

    protected override void startup ()
    {
        base.startup ();

        add_action_entries (action_entries, this);

        window = new KlotskiWindow ();
        add_window (window);

        set_accels_for_action ("win.prev-puzzle",   {"Up"});        // TODO
        set_accels_for_action ("win.next-puzzle",   {"Down"});      // TODO a weird behaviour exists when you first change puzzle pack, then go to
        set_accels_for_action ("win.prev-pack",     {"Page_Up"});   // TODO the first/last one, click on a puzzle, and immediately hit Up or Down arrows.
        set_accels_for_action ("win.next-pack",     {"Page_Down"}); // TODO that makes these keybindings sometimes act strangely, but they’re good.

        set_accels_for_action ("win.start-game",    { "<Shift><Primary>n",
                                                      "<Shift><Primary>r"   }); // TODO just <Primary>n/r?

        set_accels_for_action ("win.show-scores",   {        "<Primary>s",      // TODO that's a weird shortcut
                                                      "<Shift><Primary>s"   });
     // set_accels_for_action ("win.help",          {                 "F1"  }); // TODO fix dance with
     // set_accels_for_action ("win.about",         {          "<Shift>F1"  }); // the shortcuts dialog
        set_accels_for_action ("app.quit",          {        "<Primary>q",
                                                      "<Shift><Primary>q"   });
    }

    protected override void activate ()
    {
        window.present ();
    }

    protected override void shutdown ()
    {
        window.destroy ();
        base.shutdown ();
    }
}
