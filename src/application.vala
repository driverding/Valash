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
            { "about",       this.on_about_action },
            { "preferences", this.on_preferences_action },
            { "relogin",     this.relogin },
            { "quit",        this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", {"<primary>q"});
    }

    public override void activate () {
        base.activate ();
        
        Settings settings = new Settings ("com.github.driverding.Valash");
        string url = settings.get_string ("url");
        if (url == "") launch_login_window (); else launch_main_window ();
    }
    
    private void launch_login_window () {
        var win = new Valash.LoginWindow (this);
        win.login_success.connect (on_login_success);
        win.present ();
    }
    
    private void launch_main_window () {
        Settings settings = new Settings ("com.github.driverding.Valash");
        Clash.get_instance ().configure (
            settings.get_string ("url"), 
            settings.get_string ("secret"), 
            settings.get_string ("test-url"), 
            settings.get_int ("test-timeout")
        );
        var win = new Valash.MainWindow (this);
        win.present ();
    }

    private void on_login_success () {
        message ("login_success signal received");
        this.active_window.destroy ();
        launch_main_window ();
    }
    
    private void relogin () {
        message ("app.relogin action activated");
        this.active_window.destroy ();
        launch_login_window ();
    }

    private void on_preferences_action () {
        message ("app.preferences action activated");
    }
    
    private void on_about_action () {
        string[] developers = { "Driver Ding" };
        var about = new Adw.AboutDialog () {
            application_name = "Valash",
            application_icon = "com.github.driverding.Valash",
            developer_name = "DriverDing",
            translator_credits = _("translator-credits"),
            version = Config.VERSION,
            developers = developers,
            copyright = "© 2026 DriverDing",
        };
        about.present (this.active_window);
    }
}

