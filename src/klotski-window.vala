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

/* Puzzle Info */
private struct LevelInfo
{
    string name;
    int group;
    int width;
    int height;
    string data;
}

[GtkTemplate (ui = "/org/gnome/Klotski/ui/klotski.ui")]
public class KlotskiWindow : ApplicationWindow
{
    /* Settings */
    private GLib.Settings settings;
    private bool is_tiled;
    private bool window_is_maximized;
    private int window_width;
    private int window_height;

    private const string KEY_LEVEL = "level";

    /* Widgets */
    [GtkChild] private HeaderBar headerbar;
    [GtkChild] private Stack stack_packs;
    [GtkChild] private Stack stack_puzzles;
    [GtkChild] private Popover puzzles_popover;
    private PuzzleView view;

    [GtkChild] private TreeView treeview_huarong;
    [GtkChild] private TreeView treeview_challenge;
    [GtkChild] private TreeView treeview_skill;

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

    private Games.Scores.Context scores_context;

    /* The "puzzle name" remarks provide context for translation. Add new
     * puzzles at the end, or you'll mess up saved scores.
     */
    private Gtk.ListStore liststore_huarong;
    private Gtk.ListStore liststore_challenge;
    private Gtk.ListStore liststore_skill;
    private TreeIter[] puzzles_items;

    private static Gee.List<Games.Scores.Category> score_categories;
    /* Warning: reordering these will screw up import of old scores. */
    private static const LevelInfo levels[] =
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

    private const GLib.ActionEntry win_actions[] =
    {
        {"prev-pack", prev_pack_cb},
        {"next-pack", next_pack_cb},
        {"prev-puzzle", prev_puzzle_cb},
        {"next-puzzle", next_puzzle_cb},
        {"start-game", start_puzzle_cb}
    };

    private static string normalize_map_name (string name)
    {
        return name.down ().replace (" ", "-");
    }

    class construct
    {
        score_categories = new Gee.ArrayList<Games.Scores.Category> ();
        for (var i = 0; i < levels.length; i++)
        {
            score_categories.add (new Games.Scores.Category (normalize_map_name (levels[i].name),
                                                             _(levels[i].name)));
        }
    }

    private Games.Scores.Category? category_request (string key)
    {
        for (int i = 0; i < levels.length; i++)
        {
            if (key == normalize_map_name (levels[i].name))
                return score_categories[i];
        }
        return null;
    }

    private void parse_old_score (string line, out Games.Scores.Score? score, out Games.Scores.Category? category)
    {
        score = null;
        category = null;

        var tokens = line.split (" ");
        if (tokens.length != 3)
            return;

        var date = Games.Scores.HistoryFileImporter.parse_date (tokens[0]);
        if (date == 0)
            return;

        var level = int.parse (tokens[1]);
        if (level == 0 && tokens[1] != "0")
            return;
        if (level < 0 || level > score_categories.size)
            return;

        var moves = int.parse (tokens[2]);
        if (moves <= 0)
            return;

        score = new Games.Scores.Score (moves, date);
        category = score_categories[level];
    }

    public KlotskiWindow ()
    {
        var css_provider = new CssProvider ();
        css_provider.load_from_resource ("/org/gnome/Klotski/ui/klotski.css");
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        settings = new GLib.Settings ("org.gnome.Klotski");
        set_default_size (settings.get_int ("window-width"), settings.get_int ("window-height"));
        if (settings.get_boolean ("window-is-maximized"))
            maximize ();

        add_action_entries (win_actions, this);
        prev_pack = lookup_action ("prev-pack") as SimpleAction;
        next_pack = lookup_action ("next-pack") as SimpleAction;
        prev_puzzle = lookup_action ("prev-puzzle") as SimpleAction;
        next_puzzle = lookup_action ("next-puzzle") as SimpleAction;
        start_game = lookup_action ("start-game") as SimpleAction;

        scores_context = new Games.Scores.Context.with_importer (
            "gnome-klotski",
             // Label on the scores dialog, next to dropdown */
             _("Puzzle"),
             this,
             category_request,
             Games.Scores.Style.POINTS_LESS_IS_BETTER,
             new Games.Scores.HistoryFileImporter (parse_old_score));

        // name, active, puzzle number (or -1), sensitive=false CSS hack
        liststore_huarong = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));
        liststore_challenge = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));
        liststore_skill = new Gtk.ListStore (4, typeof (string), typeof (bool), typeof (int), typeof (bool));

        puzzles_items = new TreeIter[levels.length];
        for (var i = 0; i < levels.length; i++)
        {
            switch (levels[i].group)
            {
            case 0:
                liststore_huarong.append (out puzzles_items[i]);
                liststore_huarong.set (puzzles_items[i],
                                       0, _(levels[i].name),
                                       1, false,
                                       2, i,
                                       3, false);
                break;
            case 1:
                liststore_challenge.append (out puzzles_items[i]);
                liststore_challenge.set (puzzles_items[i],
                                         0, _(levels[i].name),
                                         1, false,
                                         2, i,
                                         3, false);
                break;
            case 2:
                liststore_skill.append (out puzzles_items[i]);
                liststore_skill.set (puzzles_items[i],
                                     0, _(levels[i].name),
                                     1, false,
                                     2, i,
                                     3, false);
                break;
            }
        }

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
        add (view);

        load_solved_state ();       // TODO use GSettings, or the history…

        current_level = settings.get_int (KEY_LEVEL).clamp (0, levels.length - 1);
        puzzles_popover.show.connect (() => { update_popover (true); });
        update_popover (true);      // or “Start Over” logically complains

        start_puzzle ();
    }

    /*\
    * * Window management callbacks
    \*/

    [GtkCallback]
    private void on_size_allocate (Allocation allocation)
    {
        if (window_is_maximized || is_tiled)
            return;
        get_size (out window_width, out window_height);
    }

    [GtkCallback]
    private bool on_window_state_event (Gdk.EventWindowState event)
    {
        if ((event.changed_mask & Gdk.WindowState.MAXIMIZED) != 0)
            window_is_maximized = (event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0;
        /* We don’t save this state, but track it for saving size allocation */
        if ((event.changed_mask & Gdk.WindowState.TILED) != 0)
            is_tiled = (event.new_window_state & Gdk.WindowState.TILED) != 0;
        return false;
    }

    [GtkCallback]
    private void on_destroy ()
    {
        /* Save game state */
        settings.set_int (KEY_LEVEL, current_level);

        /* Save window state */
        settings.set_int ("window-width", window_width);
        settings.set_int ("window-height", window_height);
        settings.set_boolean ("window-is-maximized", window_is_maximized);
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
        next_puzzle.set_enabled (current_level < levels.length - 1);
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
        headerbar.set_title (_(levels[current_level].name));
        puzzle = new Puzzle (levels[current_level].width, levels[current_level].height, levels[current_level].data);
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

        scores_context.add_score.begin (puzzle.moves,
                                        score_categories[current_level],
                                        null,
                                        (object, result) => {
            try
            {
                scores_context.add_score.end (result);
            }
            catch (Error e)
            {
                warning ("Failed to add score: %s", e.message);
            }
        });
    }

    public void show_scores ()
    {
        scores_context.run_dialog ();
    }

    private string get_level_key (int level_number)
    {
        /* Calculate the CRC of the level data */
        uint32 result = 0xFFFFFFFFu;
        var data = levels[level_number].data;
        for (var i = 0; data[i] != '\0'; i++)
        {
            var octet = data[i];
            for (var j = 0; j < 8; j++)
            {
                if (((octet >> 7) ^ (result >> 31)) != 0)
                    result = (result << 1) ^ 0x04c11db7;
                else
                    result = (result << 1);
                result &= 0xFFFFFFFFu ;
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

        for (var i = 0; i < levels.length; i++)
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
