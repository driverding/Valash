/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

public class Valash.ProxyModel : Object {
    public string id         { get; construct; }
    public string proxy_name { get; construct; }
    public string proxy_type { get; construct; }
    public double delay      { get; set; }
    public bool selected     { get; set; }

    public ProxyModel.from_json (ProxyData data) {
        Object (id: data.id,
                proxy_name: data.name,
                proxy_type: data.proxy_type);
        sync_from_json (data);
    }

    public void sync_from_json (ProxyData data) {
        var max_entry = data.history.max ((a, b) => {
            if (a.delay < b.delay) return -1;
            if (a.delay > b.delay) return 1;
            return 0;
        });
        this.delay = max_entry != null ? max_entry.delay : 0;
    }
}

[GtkTemplate (ui = "/com/github/driverding/Valash/proxy-button-box.ui")]
public class Valash.ProxyButtonBox : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Button select_button;
    [GtkChild]
    private unowned Gtk.Button delay_check_button;
    [GtkChild]
    private unowned Gtk.Label name_label;
    [GtkChild]
    private unowned Gtk.Label type_label;
    [GtkChild]
    private unowned Gtk.Label delay_label;

    public ProxyModel model { get; construct; }

    construct {
        model.bind_property ("proxy_name", name_label, "label", BindingFlags.SYNC_CREATE);
        model.bind_property ("proxy_type", type_label, "label", BindingFlags.SYNC_CREATE);
        model.bind_property ("delay", delay_label, "label", BindingFlags.SYNC_CREATE, format_delay_transform);
        model.notify["selected"].connect (refresh_selected_style); /* Change to Adw.bind_property_to_css_class later for libadwaita 1.11 */
    }

    public ProxyButtonBox (ProxyModel model) {
        Object (model: model);

        refresh_selected_style ();
    }

    private void refresh_selected_style () {
        if (model.selected) {
            select_button.add_css_class ("suggested-action");
            delay_check_button.add_css_class ("suggested-action");
        } else {
            select_button.remove_css_class ("suggested-action");
            delay_check_button.remove_css_class ("suggested-action");
        }
    }

    [GtkCallback]
    private void on_select_button_clicked (Gtk.Button source) {
        this.activate_action ("group.select-proxy", "s", model.proxy_name);
    }

    [GtkCallback]
    private void on_delay_check_button_clicked (Gtk.Button source) {
        this.activate_action ("clash.request-delay-check", "s", model.proxy_name);
    }
}
