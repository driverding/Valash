[GtkTemplate (ui = "/com/github/driverding/Valash/ui/main-window.ui")]
public class Valash.MainWindow : Adw.ApplicationWindow {
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

    // private async void send_connections_message () {
    //     Soup.Message connections_msg = new Soup.Message ("GET", TEMP_URL + "/connections");
    //     try {
    //         var response = yield session.send_and_read_async (connections_msg, Priority.DEFAULT, connections_cancellable);
    //         string data = (string) response.get_data ();
    //         Json.Object root = Json.from_string (data).get_object ();
    //         connections_received (root);
    //     } catch (Error e) {
    //         stderr.printf (e.message);
    //     }
    // }
}

