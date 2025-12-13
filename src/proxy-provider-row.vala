[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxy-provider-row.ui")]
class Valash.ProxyProviderRow : Adw.ExpanderRow {
    [GtkChild]
    private unowned Gtk.ProgressBar usage_progress_bar;
    [GtkChild]
    private unowned Gtk.Label right_label;
    [GtkChild]
    private unowned Gtk.GridView grid_view;

    public ProxyProviderRow () {
        Object ();
    }

    construct {
    }

    public ProxyProviderRow.from_data (ProxyProviderData data) {
        this.title = data.name;
        this.subtitle =
            data.vehicle_type + " - " +
            _("%d Proxies").printf (data.proxies.size) + " - " +
            data.updated_at.format (_("Updated on %b. %-d"));

        string to_right_label = "";
        if (data.subscription_info != null) {
            if (data.subscription_info.expire != null) {
                to_right_label = data.subscription_info.expire.format ("Expire on %Y %b. %-d");
            }

            if (
                data.subscription_info.download != 0 &&
                data.subscription_info.upload != 0 &&
                data.subscription_info.total != 0
            ) {
                double available = data.subscription_info.total - data.subscription_info.download - data.subscription_info.upload;
                double total = data.subscription_info.total;

                usage_progress_bar.visible = true;
                usage_progress_bar.fraction = available / total;

                if (to_right_label != "")
                    to_right_label += " - ";
                to_right_label += format_value (available) + " / " + format_value (total);

            } else {
                usage_progress_bar.visible = false;
            }
            right_label.label = to_right_label;
        }

        foreach (ProxyData proxy in data.proxies) {
            // Update ListStore
        }
    }

    // [GtkCallback]
    // private void on_update_button_clicked (Gtk.Button source) {

    // }
    [GtkCallback]
    private void on_health_check_button_clicked (Gtk.Button source) {

    }

}
