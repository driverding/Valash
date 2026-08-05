/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

public class Valash.ProxyGroupModel : Object {
    public string proxy_group_name { get; construct; }
    public GLib.ListModel proxies  { get; construct; } /* typeof: ProxyModel */

    public ProxyGroupModel.from_json (ProxyData group_data, Gee.HashMap<string, ProxyData> all_proxies) {
        var proxy_store = new GLib.ListStore (typeof (ProxyModel));
        Object (proxy_group_name: group_data.name,
                proxies: proxy_store);
        this.sync_from_json (group_data, all_proxies);
    }

    public void sync_from_json (ProxyData group_data, Gee.HashMap<string, ProxyData> all_proxies) {
        var store = (GLib.ListStore) this.proxies;

        Gee.HashSet<string> to_append = new Gee.HashSet<string> ();
        foreach (string name in group_data.all) {
            to_append.add (name);
        }

        /* Remove Removed Proxies, Sync Existing Proxies */
        for (int i = (int) store.get_n_items () - 1; i >= 0; i -= 1) {
            ProxyModel item = (ProxyModel) store.get_item (i);
            if (!to_append.contains (item.proxy_name)) {
                store.remove (i);
            } else {
                item.sync_from_json (all_proxies[item.proxy_name]);
                to_append.remove (item.proxy_name);
            }
        }

        /* Append New Proxies */
        foreach (string name in to_append) {
            store.append (new ProxyModel.from_json (all_proxies[name]));
        }

        /* Set selected proxy */
        for (uint i = 0; i < store.get_n_items (); i++) {
            ProxyModel item = (ProxyModel) store.get_item (i);
            item.selected = item.proxy_name == group_data.now;
        }
    }
}

[GtkTemplate (ui = "/com/github/driverding/Valash/proxy-group-row.ui")]
public class Valash.ProxyGroupRow : Adw.ExpanderRow {
    [GtkChild]
    private unowned Gtk.FlowBox flow_box;

    public ProxyGroupModel model { get; construct; }

    class construct {
        install_action ("group.select_proxy", "s", (widget, action_name, parameter) => {
            var self = widget as ProxyGroupRow;
            var args = new Variant.tuple ({
                new Variant.string (self.model.proxy_group_name),
                new Variant.string (parameter.get_string ())
            });
            self.activate_action ("clash.select_proxy", "ss", args);
        });
    }

    construct {
        model.bind_property ("proxy_group_name", this, "title", BindingFlags.SYNC_CREATE);
        model.proxies.items_changed.connect ((positions, removed, added) => { refresh_subtitle (); });
        flow_box.bind_model (model.proxies, (obj) => {
            return new ProxyButtonBox ((ProxyModel) obj);
        });
    }

    public ProxyGroupRow (ProxyGroupModel model) {
        Object (model: model);
    }

    private void refresh_subtitle () {
        this.subtitle = _("%u Proxies").printf (model.proxies.get_n_items ());
    }

    [GtkCallback]
    private void on_delay_check_button_clicked (Gtk.Button source) {
        this.activate_action ("win.request-group-delay-check", "s", model.proxy_group_name);
    }
}
