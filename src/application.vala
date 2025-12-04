const string TEMP_URL = "http://127.0.0.1:9090";

public class Valash.Application : Adw.Application {

    public Application () {
        Object (
            application_id: "com.github.driverding.Valash",
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/com/github/driverding/Valash"
        );
    }

    construct {
        ActionEntry[] action_entries = {
            { "about", this.on_about_action },
            { "preferences", this.on_preferences_action },
            { "quit", this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", {"<primary>q"});
    }

    public override void activate () {
        Clash.reinit_instance (TEMP_URL);

        base.activate ();
        var win = this.active_window ?? new Valash.MainWindow (this);
        win.present ();
    }

    private void on_about_action () {
        string[] developers = { "Driver Ding" };
        var about = new Adw.AboutDialog () {
            application_name = "Valash",
            application_icon = "com.github.driverding.Valash",
            developer_name = "Driver Ding",
            translator_credits = _("translator-credits"),
            version = "0.1.0",
            developers = developers,
            copyright = "© 2025 DriverDing",
        };

        about.present (this.active_window);
    }

    private void on_preferences_action () {
        message ("app.preferences action activated");
    }
}
