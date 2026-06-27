[GtkTemplate (ui = "/com/github/driverding/Valash/proxy-group-row.ui")]
class Valash.ProxyGroupRow : Adw.ExpanderRow {
    [GtkChild]
    private unowned Gtk.FlowBox flow_box;
    
    public string proxy_group_name { get; construct; }
    private Clash clash;
    private Gee.HashMap<string, ProxyButtonBox> proxy_buttons = new Gee.HashMap<string, ProxyButtonBox> ();
    private string selected;

    public ProxyGroupRow.from_data (string name, Gee.HashMap<string, ProxyData> data, Clash clash) {
        Object (proxy_group_name: name);
        this.clash = clash;
        refresh (data);
    }

    public void refresh (Gee.HashMap<string, ProxyData> data) {
        this.title = proxy_group_name;
        this.subtitle = _("%d Proxies").printf (data[proxy_group_name].all.length);

        // Proxies - Diff
        var seen = new Gee.HashSet<string> ();

        foreach (string child_name in data[proxy_group_name].all) {
            seen.add (child_name);
            if (proxy_buttons.has_key (child_name)) {
                proxy_buttons[child_name].refresh (data[child_name]);
                proxy_buttons[child_name].selected = false;
            } else {
                var new_button = new ProxyButtonBox.from_data (data[child_name],
                                                               this.selecting_handler,
                                                               this.delay_checking_handler);
                flow_box.append (new_button);
                proxy_buttons.set (child_name, new_button);
            }
        }

        foreach (string child_name in proxy_buttons.keys) {
            if (!seen.contains (child_name)) {
                var button_to_remove = proxy_buttons[child_name];
                flow_box.remove (button_to_remove);
                proxy_buttons.unset (child_name);
            }
        }

        // Highlight Selected
        this.selected = data[proxy_group_name].now;
        proxy_buttons[this.selected].selected = true;
    }

    public void selecting_handler (string proxy_name) {
        this.select_proxy.begin (proxy_name);
    }

    private async void select_proxy (string proxy_name) {
        bool result = yield clash.set_proxy (proxy_group_name, proxy_name, null);
        if (result) {
            this.proxy_buttons[this.selected].selected = false;
            this.selected = proxy_name;
            this.proxy_buttons[proxy_name].selected = true;
        } else {
            GLib.warning ("Select Proxy Failure");
        }
    }

    public void delay_checking_handler (string proxy_name) {
        this.update_proxy.begin (proxy_name);
    }

    private async void update_proxy (string proxy_name) {
        int delay = yield clash.request_proxy_delay (proxy_name, null);
        this.proxy_buttons[proxy_name].delay = delay;
        message ("proxy delay checked: %d", delay);
    }

    [GtkCallback]
    private void on_delay_check_button_clicked (Gtk.Button source) {}
}
