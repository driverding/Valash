[GtkTemplate (ui = "/com/github/driverding/Valash/ui/main-window.ui")]
public class Valash.MainWindow : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.ViewStack stack;
    [GtkChild]
    private unowned Valash.OverviewPage overview_page;
    [GtkChild]
    private unowned Valash.ProxiesPage proxies_page;
    [GtkChild]
    private unowned Valash.ConnectionPage connection_page;

    private Clash instance;
    private GLib.Cancellable connections_cancellable;

    public signal void connections_received (ConnectionsData data);

    public MainWindow (Adw.Application app) {
        typeof (Valash.Graph).ensure();
        typeof (Valash.OverviewPage).ensure();
        typeof (Valash.ProxiesPage).ensure();
        typeof (Valash.ConnectionPage).ensure();

        Object (application: app);
    }

    construct {
        this.instance = Clash.get_instance ();
        this.connections_cancellable = new GLib.Cancellable ();

        connections_received.connect (overview_page.on_connections_received);
        connections_received.connect (connection_page.on_connections_received);
        GLib.Timeout.add (1000, () => {
            request_connections.begin ();
            return true;
        });
    }

    private async void request_connections () {
        ConnectionsData response = yield instance.request_connections (connections_cancellable);
        connections_received (response);
    }

    [GtkCallback]
    private void on_stack_notify_visible_child (GLib.Object sender, GLib.ParamSpec pspec) {
        if (stack.visible_child == proxies_page) {
            stderr.printf ("Matched");
            proxies_page.update.begin ();
        }
    }
}

