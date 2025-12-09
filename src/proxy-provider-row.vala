[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxy-provider-row.ui")]
class Valash.ProxyProviderRow : Adw.PreferencesRow {
    [GtkChild]
    private Gtk.Label title_label;
    [GtkChild]
    private Gtk.ProgressBar usage_progress_bar;
    [GtkChild]
    private Gtk.Label left_subtitle_label;
    [GtkChild]
    private Gtk.Label right_subtitle_label;


    public ProxyProviderRow () {
        Object ();
    }

    public ProxyProviderRow.from_data (ProxyProviderData data) {
        title_label.label = data.name;
        left_subtitle_label.label =
            data.vehicle_type + " - " +
            _("%d Proxies").printf (data.proxies.size) + " - " +
            data.updated_at.format (_("Updated on %b. %-d"));

        string to_right_subtitle = "";
        if (data.subscription_info != null) {
            if (data.subscription_info.expire != null) {
                to_right_subtitle = data.subscription_info.expire.format ("Expire on %Y %b. %-d");
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

                if (to_right_subtitle != "")
                    to_right_subtitle += " - ";
                to_right_subtitle += format_value (available) + " / " + format_value (total);

            } else {
                usage_progress_bar.visible = false;
            }
            right_subtitle_label.label = to_right_subtitle;
        }
    }
}
