/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

public class Valash.ProxyGroupModel : Object {
    public string proxy_group_name { get; construct; }
    public GLib.ListModel proxies  { get; construct; } /* typeof: ProxyModel */
    public string title            { get; set; default = ""; }

    public ProxyGroupModel.from_json (ProxyData group_data, Gee.HashMap<string, ProxyData> all_proxies) {
        var proxy_store = new GLib.ListStore (typeof (ProxyModel));
        Object (proxy_group_name: group_data.name,
                proxies: proxy_store);
        this.sync_from_json (group_data, all_proxies);
    }

    public void sync_from_json (ProxyData group_data, Gee.HashMap<string, ProxyData> all_proxies) {
        var store = (GLib.ListStore) this.proxies;

        /* Build the map of proxies this group wants */
        var group_proxies = new Gee.HashMap<string, ProxyData> ();
        foreach (string name in group_data.all) {
            group_proxies[name] = all_proxies[name];
        }

        /* Diff the proxies */
        diff_list_store<string, ProxyData> (
            store,
            group_proxies,
            (item) => ((ProxyModel) item).id,
            (json) => new ProxyModel.from_json (json),
            (item, json) => ((ProxyModel) item).sync_from_json (json)
        );

        /* Set selected proxy */
        for (uint i = 0; i < store.get_n_items (); i++) {
            ProxyModel item = (ProxyModel) store.get_item (i);
            item.selected = item.proxy_name == group_data.now;
        }

        /* Update title with selected proxy name */
        string selected_proxy = "";
        for (uint i = 0; i < store.get_n_items (); i++) {
            ProxyModel item = (ProxyModel) store.get_item (i);
            if (item.selected) {
                selected_proxy = item.proxy_name;
                break;
            }
        }
        this.title = selected_proxy != "" ? @"$(proxy_group_name) - $selected_proxy" : proxy_group_name;
    }
}

[GtkTemplate (ui = "/com/github/driverding/Valash/proxy-group-row.ui")]
public class Valash.ProxyGroupRow : Adw.ExpanderRow {
    [GtkChild]
    private unowned Gtk.FlowBox flow_box;

    public ProxyGroupModel model { get; construct; }

    class construct {
        install_action ("group.select-proxy", "s", (widget, action_name, parameter) => {
            var self = widget as ProxyGroupRow;
            self.activate_action ("win.select-proxy", "(ss)", self.model.proxy_group_name, parameter.get_string ());
        });
    }

    construct {
        model.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE);
        model.proxies.items_changed.connect ((positions, removed, added) => { refresh_subtitle (); });
        flow_box.bind_model (model.proxies, (obj) => {
            return new ProxyButtonBox ((ProxyModel) obj);
        });
    }

    public ProxyGroupRow (ProxyGroupModel model) {
        Object (model: model);
        refresh_subtitle ();
    }

    private void refresh_subtitle () {
        this.subtitle = _("%u Proxies").printf (model.proxies.get_n_items ());
    }

    [GtkCallback]
    private void on_delay_check_button_clicked (Gtk.Button source) {
        this.activate_action ("win.request-group-delay-check", "s", model.proxy_group_name);
    }
}
