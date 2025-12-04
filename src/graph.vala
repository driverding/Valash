public class Valash.Graph : Gtk.DrawingArea {

    public uint     data_length      { get; construct; default = 50; }
    // public Gdk.RGBA stroke_color     { get; construct set; }
    // public Gdk.RGBA fill_color       { get; construct set; }
    // public Gdk.RGBA background_color { get; construct set; }

    private Gee.ArrayQueue<double?> data;

    public Graph () {
        Object ();
    }

    construct {
        data = new Gee.ArrayQueue<double?> ();
        for (int i = 0; i < data_length; i += 1) {
            data.offer (0);
        }

        set_draw_func (draw_graph);
    }

    public void push_data_point (double point) {
        this.data.poll ();
        this.data.offer (point);
        this.queue_draw ();
    }

    public double get_max_value () {
        double max = 0;
        foreach (double point in data) {
            max = point > max ? point : max;
        }
        return max;
    }

    private void draw_graph (Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
        var style_manager = Adw.StyleManager.get_default ();
        Gdk.RGBA stroke_color = style_manager.get_accent_color_rgba ();
        Gdk.RGBA fill_color = stroke_color.copy ();
        fill_color.alpha = 0.4f;

        // Gdk.cairo_set_source_rgba (cr, background_color);
        // cr.paint ();

        double step = (double) width / (double) (data_length - 1);
        // Use 100kbps as default max value
        double max = get_max_value ();
        double scale = (double) height / (double) (max > 102400 ? max : 102400);
        double x = 0;

        Gdk.cairo_set_source_rgba (cr, stroke_color);
        cr.set_line_width (2.0);
        cr.move_to (x, height - data.peek () * scale);
        foreach (double point in data) {
            cr.line_to (x, height - point * scale);
            x += step;
        }
        cr.stroke ();

        x = 0;

        Gdk.cairo_set_source_rgba (cr, fill_color);
        cr.move_to (width, height);
        cr.line_to (0, height);
        foreach (double point in data) {
            cr.line_to (x, height - point * scale);
            x += step;
        }
        cr.line_to (width, height);
        cr.fill ();
    }
}
