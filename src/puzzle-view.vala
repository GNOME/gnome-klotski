public class PuzzleView : Gtk.DrawingArea
{
    private const int SPACE_OFFSET = 4;
    private const int SPACE_PADDING = 5;
    private const int THEME_OVERLAY_SIZE = 8;
    private const int THEME_TILE_SEGMENTS = 27;
    private const int THEME_TILE_CENTER = 14;
    private const int THEME_TILE_SIZE = 34;

    private int render_size = 0;

    private Gdk.Pixbuf tiles_pixbuf = null;
    private Gdk.Pixbuf tiles_image = null;

    private int piece_x = 0;
    private int piece_y = 0;

    private char piece_id = '\0';
    private char last_piece_id = '\0';

    private double kx = 0;
    private double ky = 0;

    private Puzzle? _puzzle = null;
    public Puzzle? puzzle
    {
        get { return _puzzle; }
        set
        {
            if (_puzzle != null)
                SignalHandler.disconnect_by_func (_puzzle, null, this);
            _puzzle = value;
            _puzzle.changed.connect (puzzle_changed_cb);
            piece_x = 0;
            piece_y = 0;
            piece_id = '\0';
            queue_draw ();
        }
    }

    private int tile_size
    {
        get
        {
            var s = int.min ((get_allocated_width () - SPACE_PADDING) / puzzle.width, (get_allocated_height () - SPACE_PADDING) / puzzle.height);
            /* SVG theme renders best when tile size is multiple of 2 */
            if (s % 2 != 0)
                s--;
            return s;
        }
    }

    public PuzzleView ()
    {
        set_events (Gdk.EventMask.EXPOSURE_MASK | Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
        load_image ();
    }

    private void load_image ()
    {
        var path = Path.build_filename (DATA_DIRECTORY, "gnome-klotski.svg", null);

        try
        {
            tiles_image = Rsvg.pixbuf_from_file (path);
        }
        catch (Error e)
        {
            /*var dialog = new Gtk.MessageDialog (window,
                                                Gtk.DialogFlags.MODAL,
                                                Gtk.MessageType.ERROR,
                                                Gtk.ButtonsType.OK,
                                                _("Could not find the image:\n%s\n\nPlease check that Klotski is installed correctly."),
                                                e.message);
            dialog.run ();*/
            stderr.printf ("%s %s\n", "Error in puzzle-view.vala load image:", e.message);
            stderr.printf ( "%s %s\n", "image path:", path);
            Posix.exit (Posix.EXIT_FAILURE);
        }
    }

    protected override bool draw (Cairo.Context cr)
    {

        if (tile_size != render_size)
        {
            render_size = tile_size;

            tiles_pixbuf = null;

            if (tiles_image != null)
                tiles_pixbuf = tiles_image.scale_simple(tile_size * THEME_TILE_SEGMENTS, tile_size * 2, Gdk.InterpType.BILINEAR);
        }

        var style = get_style_context ();
        var fg = style.get_color (Gtk.StateFlags.NORMAL);
        var bg = style.get_background_color (Gtk.StateFlags.NORMAL);

        Gdk.cairo_set_source_rgba (cr, bg);
        cr.paint ();

        int width = this.get_allocated_width ();
        int height = this.get_allocated_height ();

        Gdk.cairo_set_source_rgba (cr, fg);
        cr.set_line_width (1.0);

        double kwidth = puzzle.width * tile_size + SPACE_PADDING - 2.0;
        double kheight = puzzle.height * tile_size + SPACE_PADDING - 2.0;
        kx = (width - kwidth) / 2.0;
        ky = (height - kheight) / 2.0;

        cr.rectangle (kx, ky, kwidth, kheight);
        cr.stroke ();

        for (var y = 0; y < puzzle.height; y++)
            for (var x = 0; x < puzzle.width; x++)
                draw_square (cr, x, y, kx, ky);

        return false;
    }

    private void draw_square (Cairo.Context cr, int x, int y, double kx, double ky)
    {
        var rect = Gdk.Rectangle ();
        rect.x = x * tile_size + SPACE_OFFSET + (int)kx - 1;
        rect.y = y * tile_size + SPACE_OFFSET + (int)ky - 1;
        rect.width = tile_size;
        rect.height = tile_size;

        var style = get_style_context ();
        var bg = style.get_background_color (Gtk.StateFlags.NORMAL);

        Gdk.cairo_rectangle (cr, rect);
        Gdk.cairo_set_source_rgba (cr, bg);

        cr.fill ();

        if (puzzle.get_piece_id (puzzle.map, x, y) != ' ')
        {
            Gdk.cairo_rectangle (cr, rect);
            Gdk.cairo_set_source_pixbuf (cr, tiles_pixbuf, rect.x - puzzle.get_piece_nr (x, y) * tile_size, rect.y - tile_size / 2);
            cr.fill ();
        }

        if (puzzle.get_piece_id (puzzle.map, x, y) == '*')
        {
            var value = 22;
            if (puzzle.get_piece_id (puzzle.orig_map, x, y) == '.')
                value = 20;

            var overlay_size = THEME_OVERLAY_SIZE * tile_size / THEME_TILE_SIZE;
            var overlay_offset = THEME_TILE_CENTER * tile_size / THEME_TILE_SIZE - overlay_size / 2;

            cr.rectangle (rect.x + overlay_offset, rect.y + overlay_offset,
                          overlay_size, overlay_size);

            Gdk.cairo_set_source_pixbuf (cr, tiles_pixbuf, rect.x - value * tile_size, rect.y - tile_size / 2);
            cr.fill ();
        }
    }

    protected override bool button_press_event (Gdk.EventButton event)
    {
        if (event.button == 1)
        {
            if (puzzle.game_over ())
                return false;
            piece_x = (int) (event.x - kx) / tile_size;
            piece_y = (int) (event.y - ky) / tile_size;
            piece_id = puzzle.get_piece_id (puzzle.map, piece_x, piece_y);
            puzzle.move_map = puzzle.map;
        }

        return false;
    }

    protected override bool button_release_event (Gdk.EventButton event)
    {
        if (event.button == 1 && piece_id != '\0')
        {
            if (puzzle.movable (piece_id) && puzzle.mapcmp (puzzle.move_map, puzzle.map))
            {
                if (last_piece_id == '\0' || last_piece_id != piece_id)
                {
                    puzzle.undomove_map = puzzle.lastmove_map;
                    if (puzzle.moves < 999)
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

        return false;
    }

    protected override bool motion_notify_event (Gdk.EventMotion event)
    {
        int new_piece_x, new_piece_y;

        if (piece_id != '\0')
        {
            new_piece_x = (int) (event.x - kx) / tile_size;
            new_piece_y = (int) (event.y - ky) / tile_size;
            if (new_piece_x >= puzzle.width || event.x < 0 || new_piece_y >= puzzle.height || event.y < 0)
                return false;
            if (puzzle.move_piece (piece_id, piece_x, piece_y, new_piece_x, new_piece_y))
            {
                piece_x = new_piece_x;
                piece_y = new_piece_y;
            }
            return true;
        }

        return false;
    }

    private void puzzle_changed_cb ()
    {
        queue_draw ();
    }
}
