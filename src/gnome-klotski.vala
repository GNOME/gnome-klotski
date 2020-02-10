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
    internal const string PROGRAM_NAME = _("Klotski");

    private KlotskiWindow window;

    private const OptionEntry [] option_entries =
    {
        /* Translators: command-line option description, see 'gnome-klotski --help' */
        { "version", 'v', OptionFlags.NONE, OptionArg.NONE, null, N_("Print release version and exit"), null },
        {}
    };

    private const GLib.ActionEntry action_entries [] =
    {
        { "help",   help_cb  },
        { "about",  about_cb },
        { "quit",   quit     }
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
        set_accels_for_action ("win.prev-pack",     {"Page_Up"});   // TODO the first/last one, click on a puzzle, and immediatly hit Up or Down arrows.
        set_accels_for_action ("win.next-pack",     {"Page_Down"}); // TODO that makes these keybindings sometimes act strangely, but they’re good.

        set_accels_for_action ("win.start-game",    { "<Shift><Primary>n",
                                                      "<Shift><Primary>r"   }); // TODO just <Primary>n/r?

        set_accels_for_action ("win.show-scores",   {        "<Primary>s",      // TODO that's a weird shortcut
                                                      "<Shift><Primary>s"   });
        set_accels_for_action ("app.help",          {                 "F1"  });
        set_accels_for_action ("app.about",         {          "<Shift>F1"  });
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

    /*\
    * * help and about
    \*/

    private void help_cb ()
    {
        try
        {
            show_uri (window.get_screen (), "help:gnome-klotski", get_current_event_time ());
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
        }
    }

    private void about_cb ()
    {
        string [] authors = {
        /* Translators: text crediting an author, in the about dialog */
            _("Lars Rydlinge (original author)"),


        /* Translators: text crediting an author, in the about dialog */
            _("Robert Ancell (port to vala)"),


        /* Translators: text crediting an author, in the about dialog */
            _("John Cheetham (port to vala)")
        };

        /* Translators: text crediting a documenter, in the about dialog */
        string [] documenters = { _("Andrew Sobala") };

        show_about_dialog (window,
                           /* Translators: name of the program, seen in the About dialog */
                           "program-name", PROGRAM_NAME,

                           "version", VERSION,
                           /* Translators: small description of the game, seen in the About dialog */
                           "comments", _("Sliding block puzzles"),

                           "copyright",
                             /* Translators: text crediting a maintainer, seen in the About dialog */
                             _("Copyright \xc2\xa9 1999-2008 – Lars Rydlinge") + "\n"+


                             /* Translators: text crediting a maintainer, seen in the About dialog; the %u are replaced with the years of start and end */
                             _("Copyright \xc2\xa9 %u-%u – Michael Catanzaro").printf (2014, 2016) + "\n"+


                             /* Translators: text crediting a maintainer, seen in the About dialog; the %u are replaced with the years of start and end */
                             _("Copyright \xc2\xa9 %u-%u – Arnaud Bonatti").printf (2015, 2020),
                           "license-type", License.GPL_3_0, // means "GNU General Public License, version 3.0 or later"
                           "authors", authors,
                           "documenters", documenters,
                           "logo-icon-name", "org.gnome.Klotski",
                           /* Translators: about dialog text; this string should be replaced by a text crediting yourselves and your translation team, or should be left empty. Do not translate literally! */
                           "translator-credits", _("translator-credits"),
                           "website", "https://wiki.gnome.org/Apps/Klotski");
    }
}
