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

private class PuzzleView : Gtk.DrawingArea
{
    private const int SPACE_OFFSET = 4;
    private const int SPACE_PADDING = 5;
    private const int THEME_OVERLAY_SIZE = 8;
    private const int THEME_TILE_SEGMENTS = 27;
    private const int THEME_TILE_CENTER = 14;
    private const int THEME_TILE_SIZE = 34;

    private int render_size = 0;

    private uint8 piece_x = 0;
    private uint8 piece_y = 0;
    private bool piece_unmoved = false;

    private char _piece_id = '\0';
    private char piece_id
    {
        get { return _piece_id; }
        set { _piece_id = value; queue_draw (); }
    }

    private char last_piece_id = '\0';

    private double kx = 0;
    private double ky = 0;

    private bool tiles_handle_init_done = false;
    private Rsvg.Handle tiles_handle;
    private File image_file;
    private Cairo.Surface surface;

    private bool puzzle_init_done = false;
    private Puzzle _puzzle;
    internal Puzzle puzzle
    {
        private  get { if (!puzzle_init_done) assert_not_reached (); return _puzzle; }
        internal set
        {
            if (puzzle_init_done)
                SignalHandler.disconnect_by_func (_puzzle, null, this);
            _puzzle = value;
            _puzzle.changed.connect (queue_draw);
            puzzle_init_done = true;
            piece_x = 0;
            piece_y = 0;
            piece_unmoved = false;
            piece_id = '\0';
            last_piece_id = '\0';
            queue_draw ();
        }
    }

    Gtk.StyleContext style_context;
    construct
    {
        init_mouse ();

        style_context = get_style_context ();

        set_size_request (250, 250);    // probably too small, but window requests 600x400 anyway
        set_events (Gdk.EventMask.EXPOSURE_MASK         |
                    Gdk.EventMask.BUTTON_PRESS_MASK     |
                    Gdk.EventMask.POINTER_MOTION_MASK   |
                    Gdk.EventMask.BUTTON_RELEASE_MASK   );

        load_image ();
    }

    private int tile_size
    {
        get
        {
            int s = int.min ((get_allocated_width () - SPACE_PADDING) / puzzle.width, (get_allocated_height () - SPACE_PADDING) / puzzle.height);
            /* SVG theme renders best when tile size is multiple of 2 */
            if (s % 2 != 0)
                s--;
            return s;
        }
    }

    private void load_image ()
    {
        image_file = File.new_for_uri ("resource:///org/gnome/Klotski/ui/assets.svg");

        try
        {
            tiles_handle = new Rsvg.Handle.from_gfile_sync (image_file, FLAGS_NONE);
        }
        catch (Error e)
        {
         /* Gtk.MessageDialog dialog = new Gtk.MessageDialog (window,
                                                              Gtk.DialogFlags.MODAL,
                                                              Gtk.MessageType.ERROR,
                                                              Gtk.ButtonsType.OK,
                                                              _("Could not find the image:\n%s\n\nPlease check that Klotski is installed correctly."),
                                                              e.message);
            dialog.run (); */
            stderr.printf ("%s %s\n", "Error in puzzle-view.vala load image:", e.message);
            Posix.exit (Posix.EXIT_FAILURE);
        }
        tiles_handle_init_done = true;
    }

    protected override bool draw (Cairo.Context cr)
    {
        if (tile_size != render_size)
        {
            if (tiles_handle_init_done)
            {
                int height = tile_size * 2;
                int width = tile_size * THEME_TILE_SEGMENTS;

                surface = new Cairo.Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, width, height);
                Cairo.Context c = new Cairo.Context (surface);

                /* calc scale factor */
                double sfw = (double) width / 918.0;
                double sfh = (double) height / 68.0;

                c.scale (sfw, sfh);

                tiles_handle.render_cairo (c);
            }
            render_size = tile_size;
        }

        style_context.save ();
        style_context.set_state (Gtk.StateFlags.NORMAL);
        Gdk.RGBA fg = style_context.get_color (Gtk.StateFlags.NORMAL);
        Gdk.RGBA bg = style_context.get_background_color (Gtk.StateFlags.NORMAL);
        style_context.restore ();

        Gdk.cairo_set_source_rgba (cr, bg);
        cr.paint ();

        int width = this.get_allocated_width ();
        int height = this.get_allocated_height ();

        Gdk.cairo_set_source_rgba (cr, fg);
        cr.set_line_width (1.0);

        double kwidth  = puzzle.width  * tile_size + SPACE_PADDING - 2.0;
        double kheight = puzzle.height * tile_size + SPACE_PADDING - 2.0;
        kx = (width  - kwidth)  / 2.0;
        ky = (height - kheight) / 2.0;

        cr.rectangle (kx, ky, kwidth, kheight);
        cr.stroke ();

        for (uint8 y = 0; y < puzzle.height; y++)
            for (uint8 x = 0; x < puzzle.width; x++)
            {
                draw_square (cr, x, y, kx, ky);

                if (piece_id == puzzle.get_piece_id (puzzle.map, x, y))
                {
                    Gdk.cairo_set_source_rgba (cr, {1.0, 1.0, 1.0, 0.2});
                    cr.rectangle (x*tile_size + kx, y*tile_size + ky, tile_size, tile_size);
                    cr.fill ();
                }
            }

        return false;
    }

    private void draw_square (Cairo.Context cr, uint8 x, uint8 y, double kx, double ky)
    {
        Gdk.Rectangle rect = Gdk.Rectangle ();
        rect.x = x * tile_size + SPACE_OFFSET + (int) kx - 1;
        rect.y = y * tile_size + SPACE_OFFSET + (int) ky - 1;
        rect.width = tile_size;
        rect.height = tile_size;

        style_context.save ();
        style_context.set_state (Gtk.StateFlags.NORMAL);
        Gdk.RGBA bg = style_context.get_background_color (Gtk.StateFlags.NORMAL);
        style_context.restore ();

        Gdk.cairo_rectangle (cr, rect);
        Gdk.cairo_set_source_rgba (cr, bg);

        cr.fill ();

        if (puzzle.get_piece_id (puzzle.map, x, y) != ' ')
        {
            Gdk.cairo_rectangle (cr, rect);
            cr.set_source_surface (surface, rect.x - puzzle.get_piece_nr (x, y) * tile_size, rect.y - tile_size / 2);
            cr.fill ();
        }

        if (puzzle.get_piece_id (puzzle.map, x, y) == '*')
        {
            uint8 tile_value = 22;  // pyramid; only the center will be used, for marking the red donkey
            if (puzzle.get_piece_id (puzzle.orig_map, x, y) == '.')
                tile_value = 20;    // if at the final place, just use the green dots as usual

            int overlay_size = THEME_OVERLAY_SIZE * tile_size / THEME_TILE_SIZE;
            int overlay_offset = THEME_TILE_CENTER * tile_size / THEME_TILE_SIZE - overlay_size / 2;

            cr.rectangle (rect.x + overlay_offset, rect.y + overlay_offset,
                          overlay_size, overlay_size);

            cr.set_source_surface (surface, rect.x - tile_value * tile_size, rect.y - tile_size / 2);
            cr.fill ();
        }
    }

    /*\
    * * mouse user actions
    \*/

    private Gtk.EventControllerMotion motion_controller;    // for keeping in memory
    private Gtk.GestureMultiPress click_controller;         // for keeping in memory

    private void init_mouse ()  // called on construct
    {
        motion_controller = new Gtk.EventControllerMotion (this);
        motion_controller.motion.connect (on_motion);

        click_controller = new Gtk.GestureMultiPress (this);    // only targets Gdk.BUTTON_PRIMARY
        click_controller.pressed.connect (on_click);
        click_controller.released.connect (on_release);
    }

    private static inline void on_click (Gtk.GestureMultiPress _click_controller, int n_press, double event_x, double event_y)
    {
        PuzzleView _this = (PuzzleView) _click_controller.get_widget ();
        if (_this.puzzle.game_over ())
            return;

        int new_piece_x = (int) (event_x - _this.kx) / _this.tile_size;
        int new_piece_y = (int) (event_y - _this.ky) / _this.tile_size;
        if (new_piece_x < 0 || new_piece_x >= (int) _this.puzzle.width
         || new_piece_y < 0 || new_piece_y >= (int) _this.puzzle.height)
            return;
        _this.piece_x = (uint8) new_piece_x;
        _this.piece_y = (uint8) new_piece_y;
        char new_piece_id = _this.puzzle.get_piece_id (_this.puzzle.map, _this.piece_x, _this.piece_y);

        bool already_moving = _this.piece_id != '\0';
        if (already_moving && _this.piece_unmoved)
        {
            _this.piece_id = '\0';
            return;
        }
        if (Puzzle.is_static_tile (new_piece_id) || new_piece_id == _this.piece_id)
            return;

        if (already_moving)
        {
            _this.validate_move ();
            if (!_this.puzzle.can_be_moved (new_piece_id))
                return;
        }

        _this.piece_unmoved = true;
        _this.piece_id = new_piece_id;
        _this.puzzle.move_map = _this.puzzle.map;
    }

    private static inline void on_release (Gtk.GestureMultiPress _click_controller, int n_press, double event_x, double event_y)
    {
        PuzzleView _this = (PuzzleView) _click_controller.get_widget ();
        if (_this.piece_id != '\0')
            _this.validate_move ();
    }

    private void validate_move ()
    {
        if (piece_unmoved)
            return;

        if (!Puzzle.is_static_tile (piece_id) && puzzle.mapcmp (puzzle.move_map, puzzle.map))
        {
            if (last_piece_id == '\0' || last_piece_id != piece_id)
            {
                puzzle.undomove_map = puzzle.lastmove_map;
                if (puzzle.moves < 10000 /* or up to uint16.MAX */)
                    puzzle.moves++;
            }

            if (puzzle.moves > 0 && !puzzle.mapcmp (puzzle.undomove_map, puzzle.map))
            {
                puzzle.moves--;
                last_piece_id = '\0';
            }
            else
                last_piece_id = piece_id;

            puzzle.lastmove_map = puzzle.map;

            puzzle.moved ();
        }
        piece_id = '\0';
    }

    private static inline void on_motion (Gtk.EventControllerMotion _motion_controller, double event_x, double event_y)
    {
        PuzzleView _this = (PuzzleView) _motion_controller.get_widget ();
        if (_this.piece_id != '\0')
        {
            int new_piece_x = (int) (event_x - _this.kx) / _this.tile_size;
            int new_piece_y = (int) (event_y - _this.ky) / _this.tile_size;
            if (event_x < 0 || new_piece_x > (int) _this.puzzle.width
             || event_y < 0 || new_piece_y > (int) _this.puzzle.height)
                return;
            if (_this.puzzle.move_piece (_this.piece_id, _this.piece_x, _this.piece_y, (uint8) new_piece_x, (uint8) new_piece_y))
            {
                _this.piece_unmoved = false;
                _this.piece_x = (uint8) new_piece_x;
                _this.piece_y = (uint8) new_piece_y;
            }
        }
    }
}
