namespace Valash {
    delegate void SelectingProxyHandler (string proxy_name);
    delegate void DelayCheckingHandler  (string proxy_name);
}

[GtkTemplate (ui = "/com/github/driverding/Valash/proxy-button-box.ui")]
class Valash.ProxyButtonBox : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Label name_label;
    [GtkChild]
    private unowned Gtk.Label proxy_type_label;
    [GtkChild]
    private unowned Gtk.Label delay_label;
    [GtkChild]
    private unowned Gtk.Button select_button;
    [GtkChild]
    private unowned Gtk.Button refresh_button;

    private string proxy_name;
    private SelectingProxyHandler selecting_handler;
    private DelayCheckingHandler  delay_checking_handler;

    private bool _selected;
    public bool selected {
        get { return this._selected; }
        set {
            if (this._selected == value)
                return;
            this._selected = value;

            if (value) {
                select_button.add_css_class ("suggested-action");
                refresh_button.add_css_class ("suggested-action");
            } else {
                select_button.remove_css_class ("suggested-action");
                refresh_button.remove_css_class ("suggested-action");
            }
        }
    }

    public int delay {
        set {
            delay_label.label = value == 0 ? "-" : "%dms".printf (value);
        }
    }


    construct {

    }

    public ProxyButtonBox.from_data (ProxyData data,
                                     SelectingProxyHandler selecting_handler,
                                     DelayCheckingHandler delay_checking_handler) {
        refresh (data);
        this.selecting_handler = selecting_handler;
        this.delay_checking_handler = delay_checking_handler;
    }

    public void refresh (ProxyData data) {
        this.proxy_name = data.name;
        name_label.label = data.name;
        proxy_type_label.label = data.proxy_type;
        this.delay = get_latest_delay (data.history);
    }

    private int get_latest_delay (Gee.ArrayList<HealthHistory> histories) {
        if (histories.is_empty)
            return 0;

        int index = 0;
        GLib.DateTime latest = histories[0].time;

        for (int i = 1; i < histories.size; i += 1) {
            if (latest.compare (histories[i].time) < 0) {
                index = i;
                latest = histories[i].time;
            }
        }
        return histories[index].delay;
    }

    [GtkCallback]
    private void on_select_button_clicked (Gtk.Button source) {
        selecting_handler (this.proxy_name);
    }

    [GtkCallback]
    private void on_refresh_button_clicked (Gtk.Button source) {
        delay_checking_handler (this.proxy_name);
    }
}
