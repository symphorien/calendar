//
//  Copyright (C) 2011-2012 Maxwell Barvian
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya.View {

/**
 * TODO :
 * OK   - Events are written rather small, to fit a lot in the box,
 * OK   - As far as width goes: rather than wrapping the text of an event, it just falls out of the box,
 *      - As far as height goes: as many events as possible are left in the box, 
 *        with an "x additional events" notice at the bottom if necessary.
 *          (impossible with VBox? Seems to automatically assign enough space)
 *      - Style fixes
 */

/**
 * Represents a single day on the grid.
 */
public class GridDay : Gtk.Viewport {

    public DateTime date { get; private set; }

    Gtk.Label label;
    Gtk.Label more_label;
    Gtk.VBox vbox;
    List<EventButton> event_buttons;

    private static const int EVENT_MARGIN = 3;

    public GridDay (DateTime date) {

        this.date = date;
        event_buttons = new List<EventButton>();

        var style_provider = Util.Css.get_css_provider ();

        vbox = new Gtk.VBox (false, 0);
        label = new Gtk.Label ("");
        more_label = new Gtk.Label ("");

        // EventBox Properties
        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        get_style_context ().add_provider (style_provider, 600);
        get_style_context ().add_class ("cell");

        label.halign = Gtk.Align.END;
        label.get_style_context ().add_provider (style_provider, 600);
        label.name = "date";
        vbox.pack_start (label, false, false, 0);

        vbox.pack_end (more_label, false, false, 0);

        add (Util.set_margins (vbox, EVENT_MARGIN, EVENT_MARGIN, EVENT_MARGIN, EVENT_MARGIN));

        // Signals and handlers
        button_press_event.connect (on_button_press);
    }

    /**
     * Updates the widgets according to the number of events that should be displayed.
     *
     * This involves showing/hiding events and the 'x more events' label.
     */
    void update_widgets () {
        int i = 0;
        int max = get_nr_of_events ();

        // Show the first 'max' widgets
        while (i < event_buttons.length () && i < max) {
            event_buttons.nth_data(i).show ();
            i++;
        }

        uint more = event_buttons.length () - i;

        // Hide the rest of the events
        while (i < event_buttons.length ()) {
            event_buttons.nth_data(i).hide ();
            i++;
        }

        // Hide / show the label indicating that there are more events
        if (more == 0)
            more_label.hide ();
        else {
            more_label.label = more.to_string () + " more...";
            more_label.show ();
        }

    }
    
    /**
     * Returns the number of events that can be displayed in a single GridDay
     * according to the current size.
     */
    int get_nr_of_events () {
        // TODO: implement this
        return 2;
    }

    public void add_event(E.CalComponent comp) {
        var button = new EventButton(comp);
        vbox.pack_start (button, false, false, 0);
        vbox.show_all();

        event_buttons.insert_sorted (button, compare_buttons);
        update_widgets ();        
    }

    /**
     * Compares the given buttons according to date.
     */
    CompareFunc<EventButton> compare_buttons = (button1, button2) => {
        var comp1 = button1.comp;
        var comp2 = button2.comp;

        var date1 = Util.ical_to_date_time (comp1.get_icalcomponent ().get_dtstart ());
        var date2 = Util.ical_to_date_time (comp2.get_icalcomponent ().get_dtstart ());

        return date1.compare(date2);
    };

    public void remove_event (E.CalComponent comp) {
        foreach(var button in event_buttons) {
            if(comp == button.comp) {
                event_buttons.remove(button);
                button.destroy();
                update_widgets ();
                break;
            }
        }
    }
    
    public void clear_events () {
        foreach(var button in event_buttons) {
            button.destroy();
            update_widgets ();
        }
    }

    public void update_date (DateTime date) {

        this.date = date;
        label.label = date.get_day_of_month ().to_string ();
    }

    private bool on_button_press (Gdk.EventButton event) {

        grab_focus ();
        return true;
    }
}

}
