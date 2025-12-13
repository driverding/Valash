[GtkTemplate (ui = "/com/github/driverding/Valash/ui/proxies-page.ui")]
class Valash.ProxiesPage : Gtk.Box {
    [GtkChild]
    private unowned Adw.PreferencesGroup proxies_group;
    [GtkChild]
    private unowned Adw.PreferencesGroup proxy_providers_group;

    private Clash instance;



    private Gee.HashMap<string, ProxyData> proxies;
    private Gee.HashMap<string, ProxyProviderData> providers;

    public ProxiesPage () {
        Object ();
    }

    construct {
        this.instance = Clash.get_instance ();
    }


    /* Database */

    public async void healthcheck (string provider) {
        yield instance.request_proxy_providers_healthcheck (provider, null);
        update.begin ();
    }

    // This function does not update ui. The caller (the proxy widget) should update the ui.
    public async double update_delay_individual (string proxy) {
        double delay = yield instance.request_proxy_delay (proxy, null);
        HealthHistory history = new HealthHistory () { delay = delay, time = new GLib.DateTime.now_local () };
        proxies.get (proxy).history.add (history);
        return delay;
    }

    public async void update_group_delay (string group) {

        // Use a better way of handling instead of reconstruct UI
    }

    public async void update () { // having "all" means selectable
        proxies = yield instance.request_proxies (null);
        providers = yield instance.request_proxy_providers (null);
        update_ui ();
    }


    /* Graphics */

    public void update_ui () {
        update_proxies_group ();
        update_proxy_providers_group ();
    }

    private void update_proxies_group () { // Rewrite it in database
        while (proxies_group.get_row (0) != null) {
            proxies_group.remove (proxies_group.get_row (0));
        }

    }

    private void update_proxy_providers_group () {  // Rewrite it in database
        while (proxy_providers_group.get_row (0) != null) {
            proxy_providers_group.remove (proxy_providers_group.get_row (0));
        }

        foreach (var provider in providers.values) {
            switch (provider.vehicle_type) {
                case "Compatible":
                    break;
                case "HTTP":
                    proxy_providers_group.add (new ProxyProviderRow.from_data (provider));
                    break;
            }
        }
    }
}
