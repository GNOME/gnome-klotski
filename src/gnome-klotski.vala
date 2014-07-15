/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

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
    private Settings settings;
    private const int MINWIDTH = 250;
    private const int MINHEIGHT = 250;
    private const int SPACE_PADDING = 5;

    private const string KEY_LEVEL = "level";

    /* Main window */
    private Gtk.Window window;
    private int window_width;
    private int window_height;
    private bool is_maximized;

    private Gtk.Box puzzles_panel;

    private Gtk.Button next_button;
    private Gtk.Button prev_button;
    private SimpleAction next_level_action;
    private SimpleAction prev_level_action;

    private SimpleAction new_game_action;

    private PuzzleView view;

    private Gtk.HeaderBar headerbar;

    private Puzzle puzzle;

    private int current_level = -1;

    private History history;

    /* The "puzzle name" remarks provide context for translation. */
    private Gtk.TreeStore puzzles;
    private Gtk.TreeIter[] puzzles_items;
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

    private const GLib.ActionEntry[] action_entries =
    {
        { "new-game",             restart_level_cb  },
        { "show-puzzles",         toggle_puzzles_cb },
        { "next-level",           next_level_cb     },
        { "prev-level",           prev_level_cb     },
        { "scores",               scores_cb         },
        { "help",                 help_cb           },
        { "about",                about_cb          },
        { "quit",                 quit_cb           }
    };

    public Klotski ()
    {
        Object (application_id: "org.gnome.klotski", flags: ApplicationFlags.FLAGS_NONE);

        add_main_option_entries (option_entries);
    }

    protected override void startup ()
    {
        base.startup ();

        Environment.set_application_name (_("Klotski"));

        settings = new Settings ("org.gnome.klotski");

        Gtk.Window.set_default_icon_name ("gnome-klotski");

        add_action_entries (action_entries, this);
        new_game_action = lookup_action ("new-game") as SimpleAction;
        new_game_action.set_enabled (false);
        next_level_action = lookup_action ("next-level") as SimpleAction;
        next_level_action.set_enabled (current_level < level.length - 1);
        prev_level_action = lookup_action ("prev-level") as SimpleAction;
        prev_level_action.set_enabled (current_level > 0);

        add_accelerator ("<Primary>n", "app.new-game", null);
        add_accelerator ("<Primary>q", "app.quit", null);
        add_accelerator ("F1", "app.help", null);
        add_accelerator ("Page_Up", "app.next-level", null);
        add_accelerator ("Page_Down", "app.prev-level", null);

        string histfile = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "history");

        history = new History (histfile);
        history.load ();

        headerbar = new Gtk.HeaderBar ();
        headerbar.show_close_button = true;
        headerbar.show ();

        window = new Gtk.ApplicationWindow (this);
        window.set_titlebar (headerbar);
        window.configure_event.connect (window_configure_event_cb);
        window.window_state_event.connect (window_state_event_cb);

        int ww = int.max (settings.get_int ("window-width"), MINWIDTH);
        int wh = int.max (settings.get_int ("window-height"), MINHEIGHT);
        window.set_default_size (ww, wh);

        if (settings.get_boolean ("window-is-maximized"))
            window.maximize ();

        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        window.add (vbox);
        vbox.show ();

        /* Create the menu */

        var builder_str =
               "<interface>" +
                /* string for menu */
               """
               <menu id='app-menu'>
                  <section>
                   <item>
                      <attribute name='label' translatable='yes'>_New Game</attribute>
                      <attribute name='action'>app.new-game</attribute>
                   </item>
                   <item>
                      <attribute name='label' translatable='yes'>_Scores</attribute>
                      <attribute name='action'>app.scores</attribute>
                   </item>
                  </section>
                  <section>
                   <item>
                      <attribute name='label' translatable='yes'>_Help</attribute>
                      <attribute name='action'>app.help</attribute>
                   </item>
                   <item>
                      <attribute name='label' translatable='yes'>_About</attribute>
                      <attribute name='action'>app.about</attribute>
                   </item>
                   <item>
                      <attribute name='label' translatable='yes'>_Quit</attribute>
                      <attribute name='action'>app.quit</attribute>
                   </item>
                  </section>
                </menu>
               </interface>
               """;

        Gtk.Builder builder = new Gtk.Builder ();

        try
        {
            builder.add_from_string (builder_str, -1);
        }
        catch (GLib.Error e)
        {
            stderr.printf ("%s\n", "Error in gnome-klotski.vala function startup() - builder.add_from_string failed");
            GLib.error(e.message);
        }

        set_app_menu (builder.get_object ("app-menu") as MenuModel);

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        hbox.show();

        puzzles = new Gtk.TreeStore (3, typeof (string), typeof (bool), typeof (int));

        Gtk.TreeIter huarong_item;
        puzzles.append (out huarong_item, null);
        puzzles.set (huarong_item, 0, "HuaRong Trail", 2, -1, -1);

        Gtk.TreeIter challenge_item;
        puzzles.append (out challenge_item, null);
        puzzles.set (challenge_item, 0, "Challenge Pack", 2, -1, -1);

        Gtk.TreeIter skill_item;
        puzzles.append (out skill_item, null);
        puzzles.set (skill_item, 0, "Skill Pack", 2, -1, -1);

        puzzles_items = new Gtk.TreeIter[level.length];

        for (var i = 0; i < level.length; i++)
        {
            switch (level[i].group)
            {
            case 0:
                puzzles.append (out puzzles_items[i], huarong_item);
                puzzles.set (puzzles_items[i], 0, _(level[i].name), 1, false, 2, i, -1);
                break;
            case 1:
                puzzles.append (out puzzles_items[i], challenge_item);
                puzzles.set (puzzles_items[i], 0, _(level[i].name), 1, false, 2, i, -1);
                break;
            case 2:
                puzzles.append (out puzzles_items[i], skill_item);
                puzzles.set (puzzles_items[i], 0, _(level[i].name), 1, false, 2, i, -1);
                break;
            }
        }

        puzzles_panel = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        puzzles_panel.visible = false;

        var puzzles_view = new Gtk.TreeView.with_model (puzzles);
        puzzles_view.set_headers_visible (false);

        var cell = new Gtk.CellRendererText ();
        var col = new Gtk.TreeViewColumn.with_attributes ("Puzzle", cell, "text", 0, null);
        col.set_data<Klotski> ("app", this);
        col.set_cell_data_func (cell, (Gtk.CellLayoutDataFunc) render_puzzle_name);
        puzzles_view.append_column (col);

        puzzles_view.insert_column_with_attributes (-1, "Complete", new CellRendererLevel (), "visible", 1, null);
        puzzles_view.row_activated.connect (level_cb);
        puzzles_view.show_all ();

        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroll.add (puzzles_view);
        scroll.show ();
        puzzles_panel.pack_start (scroll, true, true, 0);

        var bbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bbox.show();

        prev_button = new Gtk.Button.with_label (_("Previous Puzzle"));
        prev_button.clicked.connect (prev_level_cb);
        prev_button.sensitive = current_level > 0;
        prev_button.show ();
        bbox.add (prev_button);

        next_button = new Gtk.Button.with_label (_("Next Puzzle"));
        next_button.clicked.connect (next_level_cb);
        next_button.sensitive = current_level < level.length - 1;
        next_button.show ();
        bbox.add (next_button);

        puzzles_panel.pack_start (bbox, false, true, 0);
        hbox.pack_start (puzzles_panel, false, true, 0);

        view = new PuzzleView ();
        view.set_size_request (MINWIDTH, MINHEIGHT);
        view.show ();
        hbox.pack_start (view, true, true, 0);

        var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
        bbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
        bbox.show ();
        hbox.pack_start (bbox, false, true, 15);

        Gtk.Button button = new Gtk.ToggleButton.with_mnemonic (_("_View Puzzles"));
        button.action_name = "app.show-puzzles";
        ((Gtk.Label) button.get_child ()).margin = 12;
        button.show ();
        sizegroup.add_widget (button);
        bbox.pack_end (button, false, true, 0);

        button = new Gtk.Button.with_mnemonic (_("_Start Over"));
        button.action_name = "app.new-game";
        ((Gtk.Label) button.get_child ()).margin = 12;
        button.show ();
        sizegroup.add_widget (button);
        bbox.pack_end (button, false, true, 0);

        vbox.pack_start (hbox, true, true, 15);

        vbox.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);

        load_solved_state ();

        var startup_level = settings.get_int (KEY_LEVEL);
        new_game (startup_level);
    }

    private static void render_puzzle_name (Gtk.CellLayout cell_layout, Gtk.CellRendererText cell,
                                            Gtk.TreeModel tree_model, Gtk.TreeIter iter)
    {
        Value val;
        tree_model.get_value (iter, 2, out val);
        int selected_level = (int) val;
        Klotski app = cell_layout.get_data<Klotski> ("app");
        if (app.current_level == selected_level)
            cell.weight = 700;
        else
            cell.weight = 400;
    }

    private bool window_configure_event_cb (Gdk.EventConfigure event)
    {
        if (!is_maximized)
        {
            window_width = event.width;
            window_height = event.height;
        }

        return false;
    }

    private bool window_state_event_cb (Gdk.EventWindowState event)
    {
        if ((event.changed_mask & Gdk.WindowState.MAXIMIZED) != 0)
            is_maximized = (event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0;
        return false;
    }

    private void scores_cb ()
    {
        show_scores (null, false);
    }

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

        puzzles.set (puzzles_items[current_level], 1, true, -1);

        var date = new DateTime.now_local ();
        var entry = new HistoryEntry (date, current_level, puzzle.moves);
        history.add (entry);
        history.save ();

        if (show_scores (entry, true) == Gtk.ResponseType.OK)
            new_game (current_level);
    }

    private int show_scores (HistoryEntry? selected_entry = null, bool show_close = false)
    {
        var dialog = new ScoreDialog (history, selected_entry, show_close);
        dialog.modal = true;
        dialog.transient_for = window;

        var result = dialog.run ();
        dialog.destroy ();

        return result;
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
            puzzles.set (puzzles_items[i], 1, value, -1);
        }
    }

    private void update_menu_state ()
    {
        puzzles_panel.queue_draw ();

        next_button.sensitive = current_level < level.length - 1;
        prev_button.sensitive = current_level > 0;

        next_level_action.set_enabled (current_level < level.length - 1);
        prev_level_action.set_enabled (current_level > 0);

        update_moves_label ();
    }

    private void new_game (int requested_level)
    {
        current_level = requested_level.clamp (0, level.length - 1);

        settings.set_int (KEY_LEVEL, current_level);

        headerbar.set_title (_(level[current_level].name));
        puzzle = new Puzzle (level[current_level].width, level[current_level].height, level[current_level].data);
        puzzle.moved.connect (puzzle_moved_cb);
        view.puzzle = puzzle;
        new_game_action.set_enabled (false);
        update_menu_state ();
    }

    private void puzzle_moved_cb ()
    {
        update_moves_label ();
        new_game_action.set_enabled (true);
    }

    private void update_moves_label ()
    {
        headerbar.set_subtitle (_("Moves: %d").printf (puzzle.moves));
        if (puzzle.game_over ())
        {
            headerbar.set_title (_("Level completed."));
            game_score ();
        }
    }

    private void quit_cb ()
    {
        window.destroy ();
    }

    private void level_cb (Gtk.TreePath path, Gtk.TreeViewColumn column)
    {
        Gtk.TreeIter iter;
        Value val;

        puzzles.get_iter (out iter, path);
        puzzles.get_value (iter, 2, out val);

        int requested_level = (int) val;
        if (requested_level < 0)
            return;

        if (current_level != requested_level)
            new_game (requested_level);
    }

    private void restart_level_cb ()
    {
        new_game (current_level);
    }

    private void toggle_puzzles_cb ()
    {
        puzzles_panel.visible = !puzzles_panel.visible;
    }

    private void next_level_cb ()
    {
        new_game (current_level + 1);
    }

    private void prev_level_cb ()
    {
        new_game (current_level - 1);
    }

    private void help_cb ()
    {
        try
        {
            Gtk.show_uri (window.get_screen (), "help:gnome-klotski", Gtk.get_current_event_time ());
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
        }
    }

    protected override void shutdown ()
    {
        base.shutdown ();

        /* Save window state */
        settings.set_int ("window-width", window_width);
        settings.set_int ("window-height", window_height);
        settings.set_boolean ("window-is-maximized", is_maximized);
    }

    protected override int handle_local_options (GLib.VariantDict options)
    {
        if (options.contains ("version"))
        {
            /* NOTE: Is not translated so can be easily parsed */
            stderr.printf ("%1$s %2$s\n", "gnome-klotski", VERSION);
            return Posix.EXIT_SUCCESS;
        }

        /* Activate */
        return -1;
    }

    protected override void activate ()
    {
        window.present ();
    }

    private void about_cb ()
    {
        const string authors[] = { "Lars Rydlinge (original author)", "Robert Ancell (port to vala)", "John Cheetham (port to vala)", null };
        const string documenters[] = { "Andrew Sobala", null };

        Gtk.show_about_dialog (window,
                               "program-name", _("Klotski"),
                               "version", VERSION,
                               "comments", _("Sliding block puzzles\n\nKlotski is a part of GNOME Games."),
                               "copyright",
                               "Copyright © 1999–2008 Lars Rydlinge",
                               "license-type", Gtk.License.GPL_2_0,
                               "authors", authors,
                               "documenters", documenters,
                               "translator-credits", _("translator-credits"),
                               "logo-icon-name", "gnome-klotski",
                               "website", "https://wiki.gnome.org/Apps/Klotski",
                               null);

    }

    public static int main (string[] args)
    {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        var app = new Klotski ();
        return app.run (args);
    }
}

private class CellRendererLevel : Gtk.CellRenderer
{
    private const int icon_size = 10;

    public CellRendererLevel ()
    {
        GLib.Object ();
    }

    public override void get_size (Gtk.Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height)
    {
        x_offset = 0;
        y_offset = 0;
        width = height = icon_size;
    }

    public override void render (Cairo.Context ctx, Gtk.Widget widget,
                                 Gdk.Rectangle background_area,
                                 Gdk.Rectangle cell_area,
                                 Gtk.CellRendererState flags)
    {
        Gdk.cairo_rectangle (ctx, background_area);

        try
        {
            var icon_theme = Gtk.IconTheme.get_default ();
            var icon = icon_theme.load_icon ("gtk-yes", icon_size, 0);

            int x = background_area.x + (background_area.width - icon_size)/2;
            int y = background_area.y + (background_area.height - icon_size)/2;
            Gdk.cairo_set_source_pixbuf (ctx, icon, x, y);
        }
        catch (Error e)
        {
            warning (e.message);
        }

        ctx.fill ();
    }
}

