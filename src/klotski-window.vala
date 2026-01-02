/*
   This file is part of GNOME Klotski.

   Copyright (C) 2010-2013 Robert Ancell
   Copyright (C) 2026 Andrey Kutejko

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

[GtkTemplate (ui = "/org/gnome/Klotski/ui/klotski.ui")]
private class KlotskiWindow : Adw.ApplicationWindow
{
    /* Puzzle Info */
    private struct LevelInfo
    {
        string  name;
        uint8   group;
        uint8   width;
        uint8   height;
        string  data;
    }

    /* Settings */
    private GLib.Settings settings;

    private const string KEY_LEVEL = "level";

    /* Widgets */
    [GtkChild] private unowned Adw.WindowTitle window_title;
    [GtkChild] private unowned Stack stack_packs;
    [GtkChild] private unowned Stack stack_puzzles;
    [GtkChild] private unowned Popover puzzles_popover;
    [GtkChild] private unowned MenuButton game_menubutton;
    [GtkChild] private unowned MenuButton main_menubutton;
    private PuzzleView view;

    [GtkChild] private unowned ListView listview_huarong;
    [GtkChild] private unowned ListView listview_challenge;
    [GtkChild] private unowned ListView listview_skill;

    [GtkChild] private unowned Grid main_grid;
    [GtkChild] private unowned Button unfullscreen_button;

    /* Actions, to disable or enable */
    private SimpleAction prev_pack;
    private SimpleAction next_pack;
    private SimpleAction prev_puzzle;
    private SimpleAction next_puzzle;
    private SimpleAction start_game;

    /* The game being played */
    private bool puzzle_init_done = false;
    private Puzzle puzzle;

    private int current_pack = -1;

    private int _current_level = -1;
    internal int current_level {
        get { return _current_level; }
        set { _current_level = value.clamp (0, levels.length - 1); }
    }

    private Games.Scores.Context scores_context;

    /* The "puzzle name" remarks provide context for translation. Add new
     * puzzles at the end, or you'll mess up saved scores.
     */
    private GLib.ListStore puzzle_states;

    private string[] stack_names = { "huarong", "challenge", "skill" };

    private static GenericArray<Games.Scores.Category> score_categories;
    /* Warning: reordering these will screw up import of old scores. */
    private const LevelInfo levels [] =
    {
        /* Translators: puzzle name */
        {   N_("Only 18 Steps"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#m**n#" +
            "#cdef#" +
            "#ghij#" +
            "#k  l#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Daisy"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdef#" +
            "#zghi#" +
            "#j  k#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Violet"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdef#" +
            "#cghi#" +
            "#j  k#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Poppy"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdde#" +
            "#fghi#" +
            "#j  k#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Pansy"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdef#" +
            "#cghf#" +
            "#i  j#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Snowdrop"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdde#" +
            "#cfgh#" +
            "#i  j#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name — sometimes called by french name "L’Âne Rouge" (with the same meaning) */
        {   N_("Red Donkey"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**b#" +
            "#a**b#" +
            "#cdde#" +
            "#cfge#" +
            "#h  i#" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Trail"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**c#" +
            "#a**c#" +
            "#eddg#" +
            "#hffj#" +
            "# ii #" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Ambush"), /* group */ 0,
            /* width and height */ 6, 9,
            "######" +
            "#a**c#" +
            "#d**e#" +
            "#dffe#" +
            "#ghhi#" +
            "# jj #" +
            "##--##" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Agatka"), /* group */ 1,
            /* width and height */ 7, 7,
            "..     " +
            ".      " +
            "#####--" +
            "#**aab-" +
            "#*ccde#" +
            "#fgh  #" +
            "#######" },

        /* Translators: puzzle name */
        {   N_("Success"), /* group */ 1,
            /* width and height */ 9, 6,
            "#######  " +
            "#**bbc#  " +
            "#defgh#  " +
            "#ijkgh-  " +
            "#llk  #  " +
            "#######.." },

        /* Translators: puzzle name */
        {   N_("Bone"), /* group */ 1,
            /* width and height */ 6, 9,
            "######" +
            "#abc*#" +
            "# dd*#" +
            "# ee*#" +
            "# fgh#" +
            "##-###" +
            "     ." +
            "     ." +
            "     ." },

        /* Translators: puzzle name */
        {   N_("Fortune"), /* group */ 1,
            /* width and height */ 7, 10,
            "     .." +
            "     . " +
            "####-. " +
            "#ab  - " +
            "#ccd # " +
            "#ccd # " +
            "#**ee# " +
            "#*fgh# " +
            "#*iih# " +
            "###### " },

        /* Translators: puzzle name */
        {   N_("Fool"), /* group */ 1,
            /* width and height */ 10, 6,
            "  ########" +
            "  -aabc  #" +
            "  #aabdef#" +
            "  #ijggef#" +
            "  #klhh**#" +
            "..########" },

        /* Translators: puzzle name */
        {   N_("Solomon"), /* group */ 1,
            /* width and height */ 7, 9,
            " .     " +
            "..     " +
            "#--####" +
            "#  aab#" +
            "# cdfb#" +
            "#hcefg#" +
            "#hijk*#" +
            "#hll**#" +
            "#######" },

        /* Translators: puzzle name */
        {   N_("Cleopatra"), /* group */ 1,
            /* width and height */ 6, 8,
            "######" +
            "#abcd#" +
            "#**ee#" +
            "#f*g #" +
            "#fh i-" +
            "####--" +
            "    .." +
            "     ." },

        /* Translators: puzzle name */
        {   N_("Shark"), /* group */ 1,
            /* width and height */ 11, 8,
            "########   " +
            "#nrr s #   " +
            "#n*op q#   " +
            "#***jml#   " +
            "#hhijkl#   " +
            "#ffcddg-   " +
            "#abcdde- . " +
            "########..." },

        /* Translators: puzzle name */
        {   N_("Rome"), /* group */ 1,
            /* width and height */ 8, 8,
            "########" +
            "#abcc**#" +
            "#ddeef*#" +
            "#ddghfi#" +
            "#   jki#" +
            "#--#####" +
            " ..     " +
            "  .     " },

        /* Translators: puzzle name */
        {   N_("Pennant Puzzle"), /* group */ 1,
            /* width and height */ 6, 9,
            "######" +
            "#**aa#" +
            "#**bb#" +
            "#de  #" +
            "#fghh#" +
            "#fgii#" +
            "#--###" +
            "    .." +
            "    .." },

        /* Translators: puzzle name */
        {   N_("Ithaca"), /* group */ 2,
            /* width and height */ 19, 19,
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
            "ttttttuvvvvvvvwwwwx" },

        /* Translators: puzzle name */
        {   N_("Pelopones"), /* group */ 2,
            /* width and height */ 9, 8,
            "#########" +
            "#abbb***#" +
            "#abbb*c*#" +
            "#adeefgg#" +
            "#  eefhh#" +
            "#... ihh#" +
            "#. . ihh#" +
            "#########" },

        /* Translators: puzzle name */
        {   N_("Transeuropa"), /* group */ 2,
            /* width and height */ 15, 8,
            "    ###########" +
            "    -AAAAABBCC#" +
            "    -   DEFGHI#" +
            "    #   DEFGJI#" +
            "    #   KEFGLI#" +
            "    #   KEFG*I#" +
            "  . #   MM****#" +
            "....###########" },

        /* Translators: puzzle name */
        {   N_("Lodzianka"), /* group */ 2,
            /* width and height */ 9, 7,
            "#########" +
            "#**abbcc#" +
            "#**abbdd#" +
            "#eefgh  #" +
            "#iiijk..#" +
            "#iiijk..#" +
            "#########" },

        /* Translators: puzzle name */
        {   N_("Polonaise"), /* group */ 2,
            /* width and height */ 7, 7,
            "#######" +
            "#aab**#" +
            "#aabc*#" +
            "#defgg#" +
            "#..fhh#" +
            "# .ihh#" +
            "#######" },

        /* Translators: puzzle name */
        {   N_("Baltic Sea"), /* group */ 2,
            /* width and height */ 6, 8,
            "######" +
            "#.abc#" +
            "#.dec#" +
            "#fggc#" +
            "#fhhi#" +
            "#fjk*#" +
            "#flk*#" +
            "######" },

        /* Translators: puzzle name */
        {   N_("American Pie"), /* group */ 2,
            /* width and height */ 10, 12,
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
            "        . " },

        /* Translators: puzzle name */
        {   N_("Traffic Jam"), /* group */ 2,
            /* width and height */ 10, 7,
            "########  " +
            "#** ffi#  " +
            "#** fgh#  " +
            "#aacehh#  " +
            "#bbdjlm-  " +
            "#bddklm-.." +
            "########.." },

        /* Translators: puzzle name */
        {   N_("Sunshine"), /* group */ 2,
            /* width and height */ 17, 22,
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
            "#################" }
    };

    private const GLib.ActionEntry win_actions [] =
    {
        { "show-scores",    show_scores         },
        { "prev-pack",      prev_pack_cb        },
        { "next-pack",      next_pack_cb        },
        { "prev-puzzle",    prev_puzzle_cb      },
        { "next-puzzle",    next_puzzle_cb      },
        { "new-game-menu",  new_game_menu_cb     },
        { "start-game",     start_puzzle_cb     },
        { "unfullscreen",   unfullscreen        },

        { "help",           help_cb             },
        { "about",          about_cb            }
    };

    private static string normalize_map_name (string name)
    {
        return name.down ().replace (" ", "-");
    }

    class construct
    {
        score_categories = new GenericArray<Games.Scores.Category> ();
        for (uint8 i = 0; i < levels.length; i++)
        {
            score_categories.add (new Games.Scores.Category (normalize_map_name (levels [i].name),
                                                             _(levels [i].name)));
        }
    }

    private Games.Scores.Category? category_request (string key)
    {
        for (uint8 i = 0; i < levels.length; i++)
        {
            if (key == normalize_map_name (levels [i].name))
                return score_categories [i];
        }
        return null;
    }

    construct
    {
        CssProvider css_provider = new CssProvider ();
        css_provider.load_from_resource ("/org/gnome/Klotski/ui/klotski.css");
        Gdk.Display? gdk_display = Gdk.Display.get_default ();
        if (gdk_display != null) // else..?
            StyleContext.add_provider_for_display ((!) gdk_display, css_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

        settings = new GLib.Settings ("org.gnome.Klotski");

        settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-is-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

        bind_property ("fullscreened", unfullscreen_button, "visible", BindingFlags.SYNC_CREATE);

        init_keyboard ();
        manage_high_contrast ();

        add_action_entries (win_actions, this);
        lookup_non_nullable_action ("prev-pack",    out prev_pack);
        lookup_non_nullable_action ("next-pack",    out next_pack);
        lookup_non_nullable_action ("prev-puzzle",  out prev_puzzle);
        lookup_non_nullable_action ("next-puzzle",  out next_puzzle);
        lookup_non_nullable_action ("start-game",   out start_game);

        scores_context = new Games.Scores.Context (
            "gnome-klotski",
             /* Translators: in the Scores dialog, label indicating for which puzzle the best scores are displayed */
             _("Puzzle"),
             category_request,
             Games.Scores.Style.POINTS_LESS_IS_BETTER,
             "org.gnome.Klotski");

        puzzle_states = new GLib.ListStore (typeof (PuzzleState));
        for (uint8 i = 0; i < levels.length; i++)
        {
            var state = new PuzzleState ();
            state.name = _(levels [i].name);
            state.level_pack = levels [i].group;
            state.level_index = i;
            state.solved = false;
            puzzle_states.append (state);
        }

        var puzzle_row_factory = new SignalListItemFactory ();
        puzzle_row_factory.setup.connect (item => {
            var list_item = (ListItem) item;
            list_item.set_child (new PuzzleRow ());
        });
        puzzle_row_factory.bind.connect (item => {
            var list_item = (ListItem) item;
            var row = (PuzzleRow) list_item.get_child ();
            var state = (PuzzleState) list_item.get_item ();
            row.bind (state);
        });
        puzzle_row_factory.unbind.connect (item => {
            var list_item = (ListItem) item;
            var row = (PuzzleRow) list_item.get_child ();
            // row.unbind ();
        });

        listview_huarong.set_factory (puzzle_row_factory);
        listview_challenge.set_factory (puzzle_row_factory);
        listview_skill.set_factory (puzzle_row_factory);

        listview_huarong.model    = new SingleSelection (new FilterListModel (puzzle_states, new CustomFilter (s => ((PuzzleState ) s).level_pack == 0)));
        listview_challenge.model  = new SingleSelection (new FilterListModel (puzzle_states, new CustomFilter (s => ((PuzzleState ) s).level_pack == 1)));
        listview_skill.model      = new SingleSelection (new FilterListModel (puzzle_states, new CustomFilter (s => ((PuzzleState ) s).level_pack == 2)));

        listview_huarong.activate.connect (level_cb);
        listview_challenge.activate.connect (level_cb);
        listview_skill.activate.connect (level_cb);

        view = new PuzzleView ();
        view.halign = Align.FILL;
        view.can_focus = true;
        view.show ();
        view.hexpand = true;
        view.vexpand = true;
        main_grid.attach (view, 0, 0, 1, 1);

        load_solved_state ();       // TODO use GSettings, or the history…

        settings.bind (KEY_LEVEL, this, "current-level", SettingsBindFlags.DEFAULT);

        puzzles_popover.show.connect (() => update_popover (true));
        update_popover (true);      // or “Start Over” logically complains

        start_puzzle ();
    }

    private void lookup_non_nullable_action (string name, out SimpleAction action)
    {
        GLib.Action? nullable_action = lookup_action (name);
        if (nullable_action == null)
            assert_not_reached ();
        action = (SimpleAction) (!) nullable_action;
    }

    /*\
    * * Popover’s buttons callbacks
    \*/

    private void new_game_menu_cb ()
    {
        update_popover (false);
        puzzles_popover.popup ();
    }

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
        if (levels [current_level].group == current_pack)
            current_level--;
        else
        {
            int tmp_level;
            for (tmp_level = levels.length - 1; tmp_level >= 0; tmp_level--)
                if (levels [tmp_level].group == current_pack)
                    break;
            current_level = tmp_level;
        }
        update_popover (true);
        start_puzzle ();
    }

    private void next_puzzle_cb ()
    {
        if (!puzzles_popover.visible)
            return;
        if (levels [current_level].group == current_pack)
            current_level++;
        else
        {
            int tmp_level;
            for (tmp_level = 0; tmp_level < levels.length; tmp_level++)
                if (levels [tmp_level].group == current_pack)
                    break;
            current_level = tmp_level;
        }
        update_popover (true);
        start_puzzle ();
    }

    private void start_puzzle_cb ()
    {
        PuzzleState? state = null;

        var listview = listview_for_pack (current_pack);
        if (listview != null)
            state = (PuzzleState?) ((SingleSelection) ((!) listview).get_model ()).get_selected_item ();

        if (state != null)
            start_puzzle_from_state ((!) state);
        else
            start_puzzle ();
        puzzles_popover.hide ();
    }

    /*\
    * * Update popover
    \*/

    private void update_popover (bool make_current)
    {
        var puzzle_state = (PuzzleState) puzzle_states.get_item (current_level);
        int current_level_pack = puzzle_state.level_pack;

        if (make_current)
            current_pack = current_level_pack;

        select_puzzle_state ((!) listview_for_pack (current_level_pack), puzzle_state);

        update_buttons_state ();

        /* update stacks */
        stack_packs.set_visible_child_name (stack_names[current_pack]);
        stack_puzzles.set_visible_child_name (stack_names[current_pack]);
    }

    private ListView? listview_for_pack (int level_pack)
    {
        switch (level_pack)
        {
            case 0:
                return listview_huarong;

            case 1:
                return listview_challenge;

            case 2:
                return listview_skill;

            default:
                return null;
        }
    }

    private static void select_puzzle_state (ListView listview, PuzzleState state)
    {
        var model = (!) listview.get_model ();
        var n = model.get_n_items ();
        for (uint i = 0; i < n; ++i)
        {
            if (model.get_item (i) == state)
            {
                model.select_item (i, true);
                return;
            }
        }
        model.unselect_all ();
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

    private void level_cb (ListView view, uint row)
    {
        puzzles_popover.hide ();
        var state = (PuzzleState) ((!) view.get_model ()).get_item (row);
        start_puzzle_from_state (state);
    }

    /*\
    * * Creating and starting game
    \*/

    private void start_puzzle_from_state (PuzzleState state)
    {
        int requested_level = state.level_index;
        if (requested_level < 0)
            return;

        current_level = requested_level;
        update_buttons_state ();
        start_puzzle ();
    }

    private void start_puzzle ()
    {
        window_title.set_title (_(levels [current_level].name));
        if (puzzle_init_done)
            SignalHandler.disconnect_by_func (puzzle, null, this);
        puzzle = new Puzzle (levels [current_level].width, levels [current_level].height, levels [current_level].data);
        puzzle_init_done = true;
        puzzle.moved.connect (puzzle_moved_cb);     // TODO disconnect previous puzzle?
        view.puzzle = puzzle;

        update_moves_label ();
        game_menubutton.active = false;
        start_game.set_enabled (false);
        game_menubutton.sensitive = false;
    }

    private void puzzle_moved_cb ()
    {
        update_moves_label ();
    }

    private void update_moves_label ()
    {
        start_game.set_enabled (true);
        game_menubutton.sensitive = true;
        /* Translators: headerbar subtitle; the %d is replaced by the number of moves already done in the current game */
        game_menubutton.set_label (puzzle.moves.to_string ());
        if (puzzle.game_over ())
        {
            /* Translators: headerbar title, when the puzzle is solved */
            window_title.set_title (_("Level completed."));    // FIXME remove the dot
            game_score ();
        }
    }

    /*\
    * * Scores
    \*/

    private void game_score ()
    {
        /* Level is complete */
        string key = get_level_key (current_level);
        KeyFile keyfile = new KeyFile ();
        string filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");  // filename:~/.local/share/gnome-klotski/levels

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

        ((PuzzleState) puzzle_states.get_item (current_level)).solved = true;

        scores_context.add_score.begin (puzzle.moves,
                                        score_categories [current_level],
                                        this,
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

    private void show_scores ()
    {
        scores_context.present_dialog (this);
    }

    private string get_level_key (int level_number)
    {
        /* Calculate the CRC of the level data */
        uint32 result = 0xFFFFFFFFu;
        string data = levels [level_number].data;
        for (uint i = 0; data [i] != '\0'; i++)
        {
            char octet = data [i];
            for (uint8 j = 0; j < 8; j++)
            {
                if (((octet >> 7) ^ (result >> 31)) != 0)
                    result = (result << 1) ^ 0x04c11db7;
                else
                    result = (result << 1);
                result &= 0xFFFFFFFFu;
                octet <<= 1;
            }
        }

        return "%08X".printf (~result);
    }

    private void load_solved_state ()
    {
        KeyFile keyfile = new KeyFile ();
        string filename = Path.build_filename (Environment.get_user_data_dir (), "gnome-klotski", "levels");
        try
        {
            keyfile.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e)
        {
        }

        for (uint8 i = 0; i < levels.length; i++)
        {
            string key = get_level_key (i);
            bool is_solved = false;
            try
            {
                is_solved = keyfile.get_boolean (key, "solved");
            }
            catch (Error e)
            {
            }

            ((PuzzleState) puzzle_states.get_item (i)).solved = is_solved;
        }
    }

    /*\
    * * manage high-constrast
    \*/

    private inline void manage_high_contrast ()
    {
        Gtk.Settings? nullable_gtk_settings = Gtk.Settings.get_default ();
        if (nullable_gtk_settings == null)
            return;

        Gtk.Settings gtk_settings = (!) nullable_gtk_settings;
        gtk_settings.notify ["gtk-theme-name"].connect (update_highcontrast_state);
        _update_highcontrast_state (gtk_settings.gtk_theme_name);
    }

    private void update_highcontrast_state (Object gtk_settings, ParamSpec unused)
    {
        _update_highcontrast_state (((Gtk.Settings) gtk_settings).gtk_theme_name);
    }

    private bool highcontrast_state = false;
    private void _update_highcontrast_state (string theme_name)
    {
        bool highcontrast_new_state = "HighContrast" in theme_name;
        if (highcontrast_new_state == highcontrast_state)
            return;
        highcontrast_state = highcontrast_new_state;

        if (highcontrast_new_state)
            add_css_class ("hc-theme");
        else
            remove_css_class ("hc-theme");
    }

    /*\
    * * keyboard shortcuts
    \*/

    private inline void init_keyboard ()
    {
        var key_controller = new EventControllerKey ();
        key_controller.propagation_phase = PropagationPhase.CAPTURE;
        key_controller.key_pressed.connect (on_key_pressed);
        ((Widget) this).add_controller (key_controller);
    }

    private inline bool on_key_pressed (EventControllerKey _key_controller, uint keyval, uint keycode, Gdk.ModifierType state)
    {
        string name = (!) (Gdk.keyval_name (keyval) ?? "");

        if (name == "F1")   // Gtk handles badly having F1 or Shift-F1 as action shortcut while using Ctrl-F1 automatically
        {
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0)
                return false;   // help overlay
            if ((state & Gdk.ModifierType.SHIFT_MASK) == 0)
            {
                help_cb ();
                return true;
            }
            else
            {
                about_cb ();
                return true;
            }
         // return false;
        }
        if (name == "F10")  // Gtk handles badly having F10 and Ctrl-F10 as actions shortcuts
        {
            if (state == 0)
            {
                main_menubutton.active = !main_menubutton.active;
                return true;
            }
            if (game_menubutton.sensitive
             && (state & Gdk.ModifierType.CONTROL_MASK) != 0)
            {
                game_menubutton.active = !game_menubutton.active;
                return true;
            }
            return false;
        }
        return false;
    }

    /*\
    * * help and about
    \*/

    private inline void help_cb ()
    {
        new UriLauncher ("help:gnome-klotski").launch.begin (this, null, () => {});
    }

    private inline void about_cb ()
    {
        string [] authors = {
        /* Translators: text crediting an author, in the about dialog */
            _("Lars Rydlinge (original author)"),


        /* Translators: text crediting an author, in the about dialog */
            _("Robert Ancell (port to vala)"),


        /* Translators: text crediting an author, in the about dialog */
            _("John Cheetham (port to vala)"),


        /* Translators: text crediting an author, in the about dialog */
            _("Andrey Kutejko (port to Gtk4 and libadwaita)")
        };

        /* Translators: text crediting a documenter, in the about dialog */
        string [] documenters = { _("Andrew Sobala") };

        Adw.show_about_dialog (this,
                           /* Translators: name of the program, seen in the About dialog */
                           "application-name", Klotski.PROGRAM_NAME,
                           "application-icon", "org.gnome.Klotski",

                           "version", VERSION,
                           /* Translators: small description of the game, seen in the About dialog */
                           "comments", _("Sliding block puzzles"),

                           "copyright",
                             /* Translators: text crediting a maintainer, seen in the About dialog */
                             _("Copyright \xc2\xa9 1999-2008 – Lars Rydlinge") + "\n"+


                             /* Translators: text crediting a maintainer, seen in the About dialog; the %u are replaced with the years of start and end */
                             _("Copyright \xc2\xa9 %u-%u – Michael Catanzaro").printf (2014, 2016) + "\n"+


                             /* Translators: text crediting a maintainer, seen in the About dialog; the %u are replaced with the years of start and end */
                             _("Copyright \xc2\xa9 %u-%u – Arnaud Bonatti").printf (2015, 2020) + "\n"+

                             /* Translators: text crediting a maintainer, seen in the About dialog; the %u are replaced with the years of start and end */
                             _("Copyright \xc2\xa9 2026 – Andrey Kutejko"),

                           "license-type", License.GPL_3_0, // means "GNU General Public License, version 3.0 or later"
                           "developers", authors,
                           "documenters", documenters,
                           /* Translators: about dialog text; this string should be replaced by a text crediting yourselves and your translation team, or should be left empty. Do not translate literally! */
                           "translator-credits", _("translator-credits"),
                           "website", "https://gitlab.gnome.org/GNOME/gnome-klotski");
    }
}

class PuzzleState : Object
{
    public string name { get; set; }
    public int level_pack { get; set; }
    public int level_index { get; set; }
    public bool solved { get; set; default = false; }
}

class PuzzleRow : Widget {
    public string puzzle_name { get; set; }
    public bool solved { get; set; }

    private Label name_label;
    private Picture solved_picture;
    private GenericArray<Binding> bindings = new GenericArray<Binding> ();

    construct {
        var layout = new BoxLayout (Orientation.HORIZONTAL);
        layout.spacing = 2;
        layout_manager = layout;

        hexpand = true;
        vexpand = true;

        name_label = new Gtk.Label ("");
        name_label.hexpand = true;
        name_label.xalign = 0;
        name_label.set_parent (this);

        solved_picture = new Picture.for_resource ("/org/gnome/Klotski/ui/solved.svg");
        solved_picture.set_parent (this);

        bind_property ("puzzle_name", name_label, "label", BindingFlags.SYNC_CREATE);
        bind_property ("solved", solved_picture, "visible", BindingFlags.SYNC_CREATE);
    }

    public void bind (PuzzleState state)
    {
        unbind ();
        bindings.add (state.bind_property ("name", this, "puzzle_name", BindingFlags.SYNC_CREATE));
        bindings.add (state.bind_property ("solved", this, "solved", BindingFlags.SYNC_CREATE));
    }

    public void unbind ()
    {
        foreach (var b in bindings)
            b.unbind ();
        bindings.remove_range (0, bindings.length);
    }
}
