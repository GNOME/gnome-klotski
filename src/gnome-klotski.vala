/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

using Gtk;

public class Klotski : Gtk.Application
{
    private const OptionEntry [] option_entries =
    {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print release version and exit"), null },
        { null }
    };

    private const GLib.ActionEntry action_entries [] =
    {
        {"scores", scores_cb},
        {"help", help_cb},
        {"about", about_cb},
        {"quit", quit_cb}
    };

    /*\
    * * Application init
    \*/

    public static int main (string [] args)
    {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        Klotski app = new Klotski ();
        return app.run (args);
    }

    public Klotski ()
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

        Environment.set_application_name (_("Klotski"));
        Window.set_default_icon_name ("org.gnome.Klotski");

        add_action_entries (action_entries, this);

        add_window (new KlotskiWindow ());

        // set_accels_for_action ("win.start-game", {"<Primary>n"}); /* or <Primary>r ? or both ? */
        set_accels_for_action ("win.prev-puzzle", {"Up"});       // TODO
        set_accels_for_action ("win.next-puzzle", {"Down"});     // TODO a weird behaviour exists when you first change puzzle pack, then go to
        set_accels_for_action ("win.prev-pack", {"Page_Up"});    // TODO the first/last one, click on a puzzle, and immediatly hit Up or Down arrows.
        set_accels_for_action ("win.next-pack", {"Page_Down"});  // TODO that makes these keybindings sometimes act strangely, but they’re good.
    }

    protected override void activate ()
    {
        get_active_window ().present ();
    }

    /*\
    * * App-menu callbacks
    \*/

    private void scores_cb ()
    {
        ((KlotskiWindow) get_active_window ()).show_scores ();
    }

    private void help_cb ()
    {
        try
        {
            show_uri (get_active_window ().get_screen (), "help:gnome-klotski", get_current_event_time ());
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
        }
    }

    private void about_cb ()
    {
        const string authors [] = { "Lars Rydlinge (original author)", "Robert Ancell (port to vala)", "John Cheetham (port to vala)", null };
        const string documenters [] = { "Andrew Sobala", null };

        show_about_dialog (get_active_window (),
                           "program-name", _("Klotski"),
                           "version", VERSION,
                           "comments", _("Sliding block puzzles"),
                           "copyright",
                             "Copyright © 1999–2008 Lars Rydlinge\n"+
                             "Copyright © 2014–2016 Michael Catanzaro\n"+
                             "Copyright © 2015 Arnaud Bonatti\n",
                           "license-type", License.GPL_3_0,
                           "authors", authors,
                           "documenters", documenters,
                           "translator-credits", _("translator-credits"),
                           "logo-icon-name", "org.gnome.Klotski",
                           "website", "https://wiki.gnome.org/Apps/Klotski",
                           null);
    }

    private void quit_cb ()
    {
        get_active_window ().destroy ();
    }
}
