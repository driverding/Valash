/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

public class Valash.ProxyProviderModel : Object {
    public string provider_name      { get; construct; }
    public string vehicle_type       { get; construct; }
    public double upload             { get; set; }
    public double download           { get; set; }
    public double total              { get; set; }
    public GLib.DateTime? expire     { get; set; }
    public GLib.DateTime? updated_at { get; set; }
    public GLib.ListModel proxies    { get; construct; } /* typeof: ProxyModel */

    public ProxyProviderModel.from_json (ProxyProviderData data) {
        var proxy_store = new GLib.ListStore (typeof (ProxyModel));

        Object (provider_name: data.name,
                vehicle_type: data.vehicle_type,
                proxies: proxy_store);

        sync_from_json (data);
    }

    public void sync_from_json (ProxyProviderData data) {
        if (data.subscription_info != null) {
            this.upload = data.subscription_info.upload;
            this.download = data.subscription_info.download;
            this.total = data.subscription_info.total;
            this.expire = data.subscription_info.expire;
        }
        this.updated_at = data.updated_at;

        /* Diff the proxies */
        diff_list_store<string, ProxyData> (
            (GLib.ListStore) this.proxies,
            data.proxies,
            (item) => ((ProxyModel) item).id,
            (json) => new ProxyModel.from_json (json),
            (item, json) => ((ProxyModel) item).sync_from_json (json)
        );
    }
}

[GtkTemplate (ui = "/com/github/driverding/Valash/proxy-provider-row.ui")]
public class Valash.ProxyProviderRow : Adw.ExpanderRow {
    [GtkChild]
    private unowned Gtk.ProgressBar usage_progress_bar;
    [GtkChild]
    private unowned Gtk.Label right_label;
    [GtkChild]
    private unowned Gtk.FlowBox flow_box;

    public ProxyProviderModel model { get; construct; }

    class construct {
        install_action ("group.select_proxy", "s", (widget, action_name, parameter) => {
            message ("provider group.select_proxy triggered");
            return; /* ProviderRow doesn't select proxy */
        });
    }

    construct {
        model.bind_property ("provider_name", this, "title", BindingFlags.SYNC_CREATE);

        model.proxies.items_changed.connect ((positions, removed, added) => { refresh (); });
        model.notify.connect (refresh); /* Using a single notify seems simpler, hope this works well */

        flow_box.bind_model (model.proxies, (obj) => {
            return new ProxyButtonBox ((ProxyModel) obj);
        });
    }

    public ProxyProviderRow (ProxyProviderModel model) {
        Object (model: model);
    }

    private void refresh () {
        /* subtitle */
        this.subtitle = _("%s - %u Proxies").printf (model.vehicle_type, model.proxies.get_n_items ());
        if (model.updated_at != null) {
            this.subtitle += model.updated_at.format (_(" - Updated on %b. %-d"));
        }

        /* right_label and usage_progress_bar */
        string to_right_label = "";

        if (model.expire != null) {
            to_right_label = model.expire.format ("Expire on %Y %b. %-d");
        }

        if (model.download != 0 && model.upload != 0 && model.total != 0) {
            double available = model.total - model.download - model.upload;
            double total = model.total;

            usage_progress_bar.visible = true;
            usage_progress_bar.fraction = available / total;

            if (to_right_label != "") {
                to_right_label += " - ";
            }
            to_right_label += format_value (available) + " / " + format_value (total);
        } else {
            usage_progress_bar.visible = false;
        }

        right_label.label = to_right_label;
    }
}
