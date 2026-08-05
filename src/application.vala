/*
 * Copyright (C) 2026 DriverDing
 * This software is licensed under the GNU General Public License (version 3 or later).
 */

public class Valash.Application : Adw.Application {
    public Clash    clash    { get; construct; }
    public Settings settings { get; construct; }

    public Application () {
        Object (
            application_id: "com.github.driverding.Valash",
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/com/github/driverding/Valash"
        );
    }

    construct {
        this.clash = new Clash ();
        this.settings = new Settings ("com.github.driverding.Valash");

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
        
        string url = settings.get_string ("address");
        if (url == "") launch_login_window (); else launch_main_window ();
    }
    
    private void launch_login_window () {
        var win = new Valash.LoginWindow (this, clash, settings);
        win.login_success.connect (on_login_success);
        win.present ();
    }
    
    private void launch_main_window () {
        clash.configure (settings.get_string ("address"),
                         settings.get_string ("secret"), 
                         settings.get_string ("test-url"), 
                         settings.get_int ("test-timeout"));
        var win = new Valash.MainWindow (this, clash, settings);
        win.present ();
    }

    private void on_login_success () {
        this.active_window.destroy ();
        launch_main_window ();
    }
    
    private void relogin () {
        this.active_window.destroy ();
        launch_login_window ();
    }

    private void on_preferences_action () {
        var dialog = new PreferencesDialog (settings);
        dialog.present (this.active_window);
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

