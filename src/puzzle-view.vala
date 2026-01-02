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

private class PuzzleView : Gtk.Widget
{
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

    private int kx {
        private get {
            int kwidth  = puzzle.width  * tile_size + SPACE_PADDING;
            return (get_width ()  - kwidth)  / 2;
        }
    }
    private int ky {
        private get {
            int kheight = puzzle.height * tile_size + SPACE_PADDING;
            return (get_height () - kheight) / 2;
        }
    }

    private Rsvg.Handle tiles_handle;
    private File image_file;
    private Gdk.MemoryTexture[] sprites;

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

    construct
    {
        init_mouse ();

        set_size_request (250, 250);    // probably too small, but window requests 600x400 anyway

        load_image ();
    }

    private int tile_size
    {
        get
        {
            int s = int.min ((get_width () - SPACE_PADDING) / puzzle.width, (get_height () - SPACE_PADDING) / puzzle.height);
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
    }

    protected override void snapshot (Gtk.Snapshot snapshot)
    {
        snapshot.translate ({ (float) kx, (float) ky });

        var builder = new Gsk.PathBuilder ();
        builder.add_rect ({ { 0, 0 }, { puzzle.width * tile_size, puzzle.height * tile_size } });
        var rect_path = builder.to_path ();

        snapshot.append_stroke (rect_path, new Gsk.Stroke (1), get_color ());

        if (tile_size != render_size)
        {
            try
            {
                int theight = tile_size * 2;
                int twidth = tile_size * THEME_TILE_SEGMENTS;

                var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, twidth, theight);

                Cairo.Context c = new Cairo.Context (surface);
                tiles_handle.render_document (c, {0.0, 0.0, (double) twidth, (double) theight});

                int stride = surface.get_stride ();
                unowned uchar[] data = surface.get_data ();
                data.length = theight * stride;

                var bytes = new Bytes (data);

                sprites = new Gdk.MemoryTexture[THEME_TILE_SEGMENTS];
                for (int s = 0; s < THEME_TILE_SEGMENTS; ++s)
                {
                    var offset = tile_size / 2 * stride + tile_size * s * 4;
                    var size = tile_size * stride;
                    assert (offset + size < bytes.get_size ());
                    var sprite_bytes = new Bytes.from_bytes (bytes, offset, size);

                    sprites[s] = new Gdk.MemoryTexture (
                        tile_size,
                        tile_size,
                        Gdk.MemoryFormat.B8G8R8A8_PREMULTIPLIED,
                        sprite_bytes,
                        stride
                    );
                }

                render_size = tile_size;
            }
            catch (Error e)
            {
                stderr.printf ("%s %s\n", "Error in puzzle-view.vala render texture:", e.message);
                return;
            }
        }

        snapshot.translate ({ (SPACE_PADDING + 1) / 2, (SPACE_PADDING + 1) / 2 });

        for (uint8 y = 0; y < puzzle.height; y++)
            for (uint8 x = 0; x < puzzle.width; x++)
            {
                char tile_id = puzzle.get_piece_id (puzzle.map, x, y);
                if (tile_id == ' ')
                    continue;

                snapshot.save ();
                snapshot.translate ({ x * tile_size, y * tile_size });

                draw_sprite (snapshot, puzzle.get_piece_nr (x, y));

                if (tile_id == '*')
                {
                    uint8 tile_value = 22;  // pyramid; only the center will be used, for marking the red donkey
                    if (puzzle.get_piece_id (puzzle.orig_map, x, y) == '.')
                        tile_value = 20;    // if at the final place, just use the green dots as usual

                    int overlay_size = THEME_OVERLAY_SIZE * tile_size / THEME_TILE_SIZE;
                    int overlay_offset = THEME_TILE_CENTER * tile_size / THEME_TILE_SIZE - overlay_size / 2;

                    snapshot.push_clip ({ { overlay_offset, overlay_offset }, { overlay_size, overlay_size } });
                    draw_sprite (snapshot, tile_value);
                    snapshot.pop ();
                }

                if (piece_id == tile_id)
                    snapshot.append_color (
                        { 1.0f, 1.0f, 1.0f, 0.2f },
                        { { 0, 0 }, { tile_size, tile_size } }
                    );

                snapshot.restore ();
            }
    }

    private void draw_sprite (Gtk.Snapshot snapshot, int sprite_no)
    {
        var sprite = sprites[sprite_no];
        snapshot.append_texture (sprite, { { 0, 0 }, { sprite.get_width (), sprite.get_height () } });
    }

    /*\
    * * mouse user actions
    \*/

    private void init_mouse ()  // called on construct
    {
        var motion_controller = new Gtk.EventControllerMotion ();
        motion_controller.motion.connect (on_motion);
        add_controller (motion_controller);

        var click_controller = new Gtk.GestureClick ();    // only targets Gdk.BUTTON_PRIMARY
        click_controller.pressed.connect (on_click);
        click_controller.released.connect (on_release);
        add_controller (click_controller);
    }

    private static inline void on_click (Gtk.GestureClick _click_controller, int n_press, double event_x, double event_y)
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

    private static inline void on_release (Gtk.GestureClick _click_controller, int n_press, double event_x, double event_y)
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
