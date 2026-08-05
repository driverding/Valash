/*
 * Copyright (C) 2026 DriverDing
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later).
 */

public class Valash.Graph : Gtk.DrawingArea {
    public Gee.ArrayQueue<double?>? series { get; set; }

    construct {
        set_draw_func (draw_graph);
    }

    public void refresh () {
        this.queue_draw ();
    }

    private void draw_graph (Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
        if (series == null) {
            warning ("series is NULL");
            return;
        } else if (series.size <= 1) {
            message ("series is too short to plot");
            return;
        }

        var style_manager = Adw.StyleManager.get_default ();
        Gdk.RGBA stroke_color = style_manager.get_accent_color_rgba ();
        Gdk.RGBA fill_color = stroke_color.copy ();
        fill_color.alpha = 0.4f;

        uint length = series.size;

        double step = (double) width / (double) (length - 1); /* I don't think length will = 1 */
        double max = series.max ((a, b) => { return (int) (a - b); });
        double scale = (double) height / (double) (max > 102400 ? max : 102400); /* Use 100kbps as default max value */
        double x = 0;

        Gdk.cairo_set_source_rgba (cr, stroke_color);
        cr.set_line_width (2.0);
        cr.move_to (x, height - series.peek () * scale);
        foreach (double point in series) {
            cr.line_to (x, height - point * scale);
            x += step;
        }
        cr.stroke ();

        x = 0;

        Gdk.cairo_set_source_rgba (cr, fill_color);
        cr.move_to (width, height);
        cr.line_to (0, height);
        foreach (double point in series) {
            cr.line_to (x, height - point * scale);
            x += step;
        }
        cr.line_to (width, height);
        cr.fill ();
    }
}
