/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

using Gtk;

/* Puzzle Info */
private struct LevelInfo
{
    string name;
    int group;
    int width;
    int height;
    string data;
}

public class Klotski : Gtk.Application
{
    /* Settings */
    private GLib.Settings settings;
    private bool is_tiled;
    private bool is_maximized;
    private int window_width;
    private int window_height;

    private const string KEY_LEVEL = "level";

    /* Widgets */
    private ApplicationWindow window;
    private HeaderBar headerbar;
    private Stack stack_packs;
    private Stack stack_puzzles;
    private Popover puzzles_popover;
    private PuzzleView view;

    /* Actions, to disable or enable */
    private SimpleAction prev_pack;
    private SimpleAction next_pack;
    private SimpleAction prev_puzzle;
    private SimpleAction next_puzzle;
    private SimpleAction start_game;

    /* The game being played */
    private Puzzle puzzle;

    private int current_pack = -1;
    private int current_level = -1;

    private History history;

    /* The "puzzle name" remarks provide context for translation. */
    private Gtk.ListStore liststore_huarong;
    private Gtk.ListStore liststore_challenge;
    private Gtk.ListStore liststore_skill;
    private TreeIter[] puzzles_items;
    public const LevelInfo level[] =
    {
      /* puzzle name */
      {N_("Only 18 Steps"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#m**n#" +
       "#cdef#" +
       "#ghij#" +
       "#k  l#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Daisy"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdef#" +
       "#zghi#" +
       "#j  k#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Violet"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdef#" +
       "#cghi#" +
       "#j  k#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Poppy"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdde#" +
       "#fghi#" +
       "#j  k#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Pansy"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdef#" +
       "#cghf#" +
       "#i  j#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Snowdrop"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdde#" +
       "#cfgh#" +
       "#i  j#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name - sometimes called "Le'Ane Rouge" */
      {N_("Red Donkey"), 0,
       6, 9,
       "######" +
       "#a**b#" +
       "#a**b#" +
       "#cdde#" +
       "#cfge#" +
       "#h  i#" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Trail"), 0,
       6, 9,
       "######" +
       "#a**c#" +
       "#a**c#" +
       "#eddg#" +
       "#hffj#" +
       "# ii #" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Ambush"), 0,
       6, 9,
       "######" +
       "#a**c#" +
       "#d**e#" +
       "#dffe#" +
       "#ghhi#" +
       "# jj #" +
       "##--##" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Agatka"), 1,
       7, 7,
       "..     " +
       ".      " +
       "#####--" +
       "#**aab-" +
       "#*ccde#" +
       "#fgh  #" +
       "#######"},

      /* puzzle name */
      {N_("Success"), 1,
       9, 6,
       "#######  " +
       "#**bbc#  " +
       "#defgh#  " +
       "#ijkgh-  " +
       "#llk  #  " +
       "#######.."},

      /* puzzle name */
      {N_("Bone"), 1,
       6, 9,
       "######" +
       "#abc*#" +
       "# dd*#" +
       "# ee*#" +
       "# fgh#" +
       "##-###" +
       "     ." +
       "     ." +
       "     ."},

      /* puzzle name */
      {N_("Fortune"), 1,
       7, 10,
       "     .." +
       "     . " +
       "####-. " +
       "#ab  - " +
       "#ccd # " +
       "#ccd # " +
       "#**ee# " +
       "#*fgh# " +
       "#*iih# " +
       "###### "},

      /* puzzle name */
      {N_("Fool"), 1,
       10, 6,
       "  ########" +
       "  -aabc  #" +
       "  #aabdef#" +
       "  #ijggef#" +
       "  #klhh**#" +
       "..########"},

      /* puzzle name */
      {N_("Solomon"), 1,
       7, 9,
       " .     " +
       "..     " +
       "#--####" +
       "#  aab#" +
       "# cdfb#" +
       "#hcefg#" +
       "#hijk*#" +
       "#hll**#" +
       "#######"},

      /* puzzle name */
      {N_("Cleopatra"), 1,
       6, 8,
       "######" +
       "#abcd#" +
       "#**ee#" +
       "#f*g #" +
       "#fh i-" +
       "####--" +
       "    .." +
       "     ."},

      /* puzzle name */
      {N_("Shark"), 1,
       11, 8,
       "########   " +
       "#nrr s #   " +
       "#n*op q#   " +
       "#***jml#   " +
       "#hhijkl#   " +
       "#ffcddg-   " +
       "#abcdde- . " +
       "########..."},

      /* puzzle name */
      {N_("Rome"), 1,
       8, 8,
       "########" +
       "#abcc**#" +
       "#ddeef*#" +
       "#ddghfi#" +
       "#   jki#" +
       "#--#####" +
       " ..     " +
       "  .     "},

      /* puzzle name */
      {N_("Pennant Puzzle"), 1,
       6, 9,
       "######" +
       "#**aa#" +
       "#**bb#" +
       "#de  #" +
       "#fghh#" +
       "#fgii#" +
       "#--###" +
       "    .." +
       "    .."},

      /* puzzle name */
      {N_("Ithaca"), 2,
       19, 19,
       ".aaaaaaaaaaaaaaaaab" +
       "..  cddeffffffffffb" +
       " .. cddeffffffffffb" +
       "  . cddeffffffffffb" +
       "ggg-############hhb" +
       "ggg-  ABCDEFFGH#hhb" +
       "ggg-       FFIJ#hhb" +
       "ggg#       KLMJ#hhb" +
       "ggg#NNNNOOOPQMJ#hhb" +
       "ggg#NNNNOOOP*RS#hhb" +
       "ggg#TTTTTUVW**X#hhb" +
       "ggg#YZ12222W3**#hhb" +
       "ggg#YZ12222W34*#iib" +
       "jjj#YZ155555367#klb" +
       "jjj#############mmb" +
       "jjjnooooooooooppppb" +
       "jjjqooooooooooppppb" +
       "       rrrssssppppb" +
       "ttttttuvvvvvvvwwwwx"},

      /* puzzle name */
      {N_("Pelopones"), 2,
       9, 8,
       "#########" +
       "#abbb***#" +
       "#abbb*c*#" +
       "#adeefgg#" +
       "#  eefhh#" +
       "#... ihh#" +
       "#. . ihh#" +
       "#########"},

      /* puzzle name */
      {N_("Transeuropa"), 2,
       15, 8,
       "    ###########" +
       "    -AAAAABBCC#" +
       "    -   DEFGHI#" +
       "    #   DEFGJI#" +
       "    #   KEFGLI#" +
       "    #   KEFG*I#" +
       "  . #   MM****#" +
       "....###########"},

      /* puzzle name */
      {N_("Lodzianka"), 2,
       9, 7,
       "#########" +
       "#**abbcc#" +
       "#**abbdd#" +
       "#eefgh  #" +
       "#iiijk..#" +
       "#iiijk..#" +
       "#########"},

      /* puzzle name */
      {N_("Polonaise"), 2,
       7, 7,
       "#######" +
       "#aab**#" +
       "#aabc*#" +
       "#defgg#" +
       "#..fhh#" +
       "# .ihh#" +
       "#######"},

      /* puzzle name */
      {N_("Baltic Sea"), 2,
       6, 8,
       "######" +
       "#.abc#" +
       "#.dec#" +
       "#fggc#" +
       "#fhhi#" +
       "#fjk*#" +
       "#flk*#" +
       "######"},

      /* puzzle name */
      {N_("American Pie"), 2,
       10, 12,
       "##########" +
       "#a*bcdefg#" +
       "#**bhhhhg#" +
       "#*iijjkkg#" +
       "#liimnoop#" +
       "#qiirrr  #" +
       "#qstuvv  #" +
       "#qwwxvv  #" +
       "######--##" +
       "         ." +
       "        .." +
       "        . "},

      /* puzzle name */
      {N_("Traffic Jam"), 2,
       10, 7,
       "########  " +
       "#** ffi#  " +
       "#** fgh#  " +
       "#aacehh#  " +
       "#bbdjlm-  " +
       "#bddklm-.." +
       "########.."},

      /* puzzle name */
      {N_("Sunshine"), 2,
       17, 22,
       "       ...       " +
       "      .. ..      " +
       "      .   .      " +
       "      .. ..      " +
       "       ...       " +
       "######-----######" +
       "#hh0iilltmmpp;qq#" +
       "#hh,iill mmpp:qq#" +
       "#2y{45v s w89x/z#" +
       "#jj6kkaa nnoo<rr#" +
       "#jj7kkaaunnoo>rr#" +
       "#33333TTJWW11111#" +
       "#33333TTJWW11111#" +
       "#33333GG HH11111#" +
       "#33333YYIgg11111#" +
       "#33333YYIgg11111#" +
       "#ddFeeA***BffOZZ#" +
       "#ddFee** **ffOZZ#" +
       "#MMKQQ*   *PPS^^#" +
       "#VVLXX** **bbRcc#" +
       "#VVLXXD***EbbRcc#" +
       "#################"}
    };

    private const OptionEntry[] option_entries =
    {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print release version and exit"), null },
        { null }
    };

    private const GLib.ActionEntry app_actions[] =
    {
        {"scores", scores_cb},
        {"help", help_cb},
        {"about", about_cb},
        {"quit", quit}
    };
    private const GLib.ActionEntry win_actions[] =
    {
        {"prev-pack", prev_pack_cb},
        {"next-pack", next_pack_cb},
        {"prev-puzzle", prev_puzzle_cb},
        {"next-puzzle", next_puzzle_cb},
        {"start-game", start_puzzle_cb}
    };

    public static int main (string[] args)
    {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        var app = new Klotski ();
        return app.run (args);
    }

    public Klotski ()
    {
        Object (application_id: "org.gnome.klotski", flags: ApplicationFlags.FLAGS_NONE);

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

        /* Activate */
        return -1;
    }

    protected override void startup ()
    {
        base.startup ();

        Environment.set_application_name (_("Klotski"));
        Window.set_default_icon_name ("gnome-klotski");

        var css_provider = new CssProvider ();
        css_provider.load_from_resource ("/org/gnome/klotski/ui/klotski.css");
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        settings = new GLib.Settings ("org.gnome.klotski");

        var builder = new Builder.from_resource ("/org/gnome/klotski/ui/klotski.ui");
        window = builder.get_object ("window") as ApplicationWindow;
        window.size_allocate.connect (size_allocate_cb);
        window.window_state_event.connect (window_state_event_cb);
        window.set_default_size (settings.get_int ("window-width"), settings.get_int ("window-height"));
        if (settings.get_boolean ("window-is-maximized"))
            window.maximize ();

        add_action_entries (app_actions, this);
        window.add_action_entries (win_actions, this);
        prev_pack = window.lookup_action ("prev-pack") as SimpleAction;
        next_pack = window.lookup_action ("next-pack") as SimpleAction;
        prev_puzzle = window.lookup_action ("prev-puzzle") as SimpleAction;
        next_puzzle = window.lookup_action ("next-puzzle") as SimpleAction;
        start_game = window.lookup_action ("start-game") as SimpleAction;
        // set_accels_for_action ("win.start-game", {"<Primary>n"}); /* or <Primary>r ? or both ? */
        set_accels_for_action ("win.prev-puzzle", {"Up"});       // TODO
        set_accels_for_action ("win.next-puzzle", {"Down"});     // TODO a weird behaviour exists when you first change puzzle pack, then go to
        set_accels_for_action ("win.prev-pack", {"Page_Up"});    // TODO the first/last one, click on a puzzle, and immediatly hit Up or Down arrows.
        set_accels_for_action ("win.next-pack", {"Page_Down"});  // TODO that makes these keybindings sometimes act strangely, but they’re good.

        string histfile = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "history");

        history = new History (histfile);
        history.load ();

        headerbar = builder.get_object ("headerbar") as HeaderBar;
        stack_packs = builder.get_object ("stack-packs") as Stack;
        stack_puzzles = builder.get_object ("stack-puzzles") as Stack;
        puzzles_popover = builder.get_object ("puzzles-popover") as Popover;

        // name, active, puzzle number (or -1), sensitive=false CSS hack
        liststore_huarong = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));
        liststore_challenge = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));
        liststore_skill = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));

        puzzles_items = new TreeIter[level.length];
        for (var i = 0; i < level.length; i++)
        {
            switch (level[i].group)
            {
            case 0:
                liststore_huarong.append (out puzzles_items[i]);
                liststore_huarong.set (puzzles_items[i],
                                       0, _(level[i].name),
                                       1, false,
                                       2, i,
                                       3, false);
                break;
            case 1:
                liststore_challenge.append (out puzzles_items[i]);
                liststore_challenge.set (puzzles_items[i],
                                         0, _(level[i].name),
                                         1, false,
                                         2, i,
                                         3, false);
                break;
            case 2:
                liststore_skill.append (out puzzles_items[i]);
                liststore_skill.set (puzzles_items[i],
                                     0, _(level[i].name),
                                     1, false,
                                     2, i,
                                     3, false);
                break;
            }
        }

        var treeview_huarong = builder.get_object ("treeview-huarong") as TreeView;
        var treeview_challenge = builder.get_object ("treeview-challenge") as TreeView;
        var treeview_skill = builder.get_object ("treeview-skill") as TreeView;

        treeview_huarong.set_model (liststore_huarong);
        treeview_challenge.set_model (liststore_challenge);
        treeview_skill.set_model (liststore_skill);

        treeview_huarong.row_activated.connect (level_huarong_cb);
        treeview_challenge.row_activated.connect (level_challenge_cb);
        treeview_skill.row_activated.connect (level_skill_cb);

        view = new PuzzleView ();
        view.halign = Align.FILL;
        view.can_focus = true;
        view.show ();
        window.add (view);

        load_solved_state ();       // TODO use GSettings, or the history…

        current_level = settings.get_int (KEY_LEVEL).clamp (0, level.length - 1);
        puzzles_popover.show.connect (() => { update_popover (true); });
        update_popover (true);      // or “Start Over” logically complains

        start_puzzle ();
        add_window (window);
    }

    protected override void activate ()
    {
        window.present ();
    }

    protected override void shutdown ()
    {
        base.shutdown ();

        /* Save game state */
        settings.set_int (KEY_LEVEL, current_level);

        /* Save window state */
        settings.set_int ("window-width", window_width);
        settings.set_int ("window-height", window_height);
        settings.set_boolean ("window-is-maximized", is_maximized);
    }

    /*\
    * * Window events
    \*/

    private void size_allocate_cb (Allocation allocation)
    {
        if (is_maximized || is_tiled)
            return;
        window_width = allocation.width;
        window_height = allocation.height;
    }

    private bool window_state_event_cb (Gdk.EventWindowState event)
    {
        if ((event.changed_mask & Gdk.WindowState.MAXIMIZED) != 0)
            is_maximized = (event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0;
        /* We don’t save this state, but track it for saving size allocation */
        if ((event.changed_mask & Gdk.WindowState.TILED) != 0)
            is_tiled = (event.new_window_state & Gdk.WindowState.TILED) != 0;
        return false;
    }

    /*\
    * * App-menu callbacks
    \*/

    private void scores_cb ()
    {
        show_scores (null);
    }

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
        const string authors[] = { "Lars Rydlinge (original author)", "Robert Ancell (port to vala)", "John Cheetham (port to vala)", null };
        const string documenters[] = { "Andrew Sobala", null };

        show_about_dialog (window,
                           "program-name", _("Klotski"),
                           "version", VERSION,
                           "comments", _("Sliding block puzzles"),
                           "copyright",
                             "Copyright © 1999–2008 Lars Rydlinge\n"+
                             "Copyright © 2014–2015 Michael Catanzaro\n"+
                             "Copyright © 2015 Arnaud Bonatti\n",
                           "license-type", License.GPL_2_0,     // TODO
                           "authors", authors,
                           "documenters", documenters,
                           "translator-credits", _("translator-credits"),
                           "logo-icon-name", "gnome-klotski",
                           "website", "https://wiki.gnome.org/Apps/Klotski",
                           null);
    }

    /*\
    * * Popover’s buttons callbacks
    \*/

    private void prev_pack_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        current_pack--;
        update_popover (false);
    }

    private void next_pack_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        current_pack++;
        update_popover (false);
    }

    private void prev_puzzle_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        current_level--;
        update_popover (true);
        start_puzzle ();
    }

    private void next_puzzle_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        current_level++;
        update_popover (true);
        start_puzzle ();
    }

    private void start_puzzle_cb ()
    {
        TreeView tree = ((TreeView) (((ScrolledWindow) (stack_puzzles.get_children ().nth_data (current_pack))).get_child ()));
        TreeModel model = tree.get_model ();
        TreeIter iter;

        if (tree.get_selection ().get_selected (out model, out iter))
            start_puzzle_from_iter ((Gtk.ListStore) model, iter);
        else
            start_puzzle ();
        puzzles_popover.hide ();
    }

    /*\
    * * Update popover
    \*/

    private void update_popover (bool make_current)
    {
        int current_level_pack;
        TreeIter iter = puzzles_items[current_level];
        if (liststore_huarong.iter_is_valid (iter))          // "slow"
            current_level_pack = 0;
        else if (liststore_challenge.iter_is_valid (iter))   // same here
            current_level_pack = 1;
        else
            current_level_pack = 2;

        if (make_current)
            current_pack = current_level_pack;

        /* select or not a level */
        TreeSelection selection = ((TreeView) (((ScrolledWindow) (stack_puzzles.get_children ().nth_data (current_pack))).get_child ())).get_selection ();
        if (current_pack == current_level_pack)
            selection.select_iter (iter);
        else
            selection.unselect_all ();

        update_buttons_state ();

        /* update stacks */
        stack_packs.set_visible_child (stack_packs.get_children ().nth_data (current_pack));
        stack_puzzles.set_visible_child (stack_puzzles.get_children ().nth_data (current_pack));
    }

    private void update_buttons_state ()
    {
        prev_pack.set_enabled (current_pack > 0);
        next_pack.set_enabled (current_pack < 2);

        prev_puzzle.set_enabled (current_level > 0);
        next_puzzle.set_enabled (current_level < level.length - 1);
    }

    /*\
    * * Selecting puzzle by the treeview
    \*/

    private void level_huarong_cb (TreePath path, TreeViewColumn column)
    {
        level_cb (liststore_huarong, path, column);
    }
    private void level_challenge_cb (TreePath path, TreeViewColumn column)
    {
        level_cb (liststore_challenge, path, column);
    }
    private void level_skill_cb (TreePath path, TreeViewColumn column)
    {
        level_cb (liststore_skill, path, column);
    }
    private void level_cb (Gtk.ListStore liststore, TreePath path, TreeViewColumn column)
    {
        TreeIter iter;

        liststore.get_iter (out iter, path);
        start_puzzle_from_iter (liststore, iter);
    }

    /*\
    * * Creating and starting game
    \*/

    private void start_puzzle_from_iter (Gtk.ListStore model, TreeIter iter)
    {
        Value val;
        model.get_value (iter, 2, out val);

        int requested_level = (int) val;
        if (requested_level < 0)
            return;

        current_level = requested_level;
        update_buttons_state ();
        start_puzzle ();
    }

    private void start_puzzle ()
    {
        headerbar.set_title (_(level[current_level].name));
        puzzle = new Puzzle (level[current_level].width, level[current_level].height, level[current_level].data);
        puzzle.moved.connect (puzzle_moved_cb);     // TODO disconnect previous puzzle?
        view.puzzle = puzzle;

        update_moves_label ();
        start_game.set_enabled (false);
    }

    private void puzzle_moved_cb ()
    {
        update_moves_label ();
    }

    private void update_moves_label ()
    {
        start_game.set_enabled (true);
        headerbar.set_subtitle (_("Moves: %d").printf (puzzle.moves));
        if (puzzle.game_over ())
        {
            headerbar.set_title (_("Level completed."));
            game_score ();
        }
    }

    /*\
    * * Scores
    \*/

    private void game_score ()
    {
        /* Level is complete */
        var key = get_level_key (current_level);
        var keyfile = new KeyFile ();
        var filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");  // filename:~/.local/share/gnome-klotski/levels

        try
        {
            keyfile.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e)
        {
        }

        keyfile.set_boolean (key, "solved", true);

        try
        {
            FileUtils.set_contents (filename, keyfile.to_data ());
        }
        catch (Error e)
        {
        }

        puzzle_solved (puzzles_items[current_level], true);

        var date = new DateTime.now_local ();
        var entry = new HistoryEntry (date, current_level, puzzle.moves);
        history.add (entry);
        history.save ();

        show_scores (entry);
    }

    private void show_scores (HistoryEntry? selected_entry = null)
    {
        var dialog = new ScoreDialog (history, selected_entry);
        dialog.set_transient_for (window);

        /* var result = */ dialog.run ();
        dialog.destroy ();
    }

    private string get_level_key (int level_number)
    {
        /* Calculate the CRC of the level data */
        uint32 result = 0xFFFFFFFFu;
        var data = level[level_number].data;
        for (var i = 0; data[i] != '\0'; i++)
        {
            var octet = data[i];
            for (var j = 0; j < 8; j++)
            {
                if (((octet >> 7) ^ (result >> 31)) != 0)
                    result = (result << 1) ^ 0x04c11db7;
                else
                    result = (result << 1);
                result &= 0xFFFFFFFF;
                octet <<= 1;
            }
        }

        return "%08X".printf (~result);
    }

    private void load_solved_state ()
    {
        var keyfile = new KeyFile ();
        var filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");
        try
        {
            keyfile.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e)
        {
        }

        for (var i = 0; i < level.length; i++)
        {
            var key = get_level_key (i);
            var value = false;
            try
            {
                value = keyfile.get_boolean (key, "solved");
            }
            catch (Error e)
            {
            }

            puzzle_solved (puzzles_items[i], value);
        }
    }

    private void puzzle_solved (TreeIter iter, bool solved)
    {
        if (liststore_huarong.iter_is_valid (iter))          // "slow"
            liststore_huarong.set (iter, 1, solved);
        else if (liststore_challenge.iter_is_valid (iter))   // same here
            liststore_challenge.set (iter, 1, solved);
        else
            liststore_skill.set (iter, 1, solved);
    }
}
