import Config

# Default System Settings

config :reflect_os_kernel, :system,
  time_format: "%-I:%M %p",
  viewport_size: {1080, 1920},
  timezone: "US/Eastern",
  show_instructions: true

# Default Sections, Layouts, and Layout Manager
config :reflect_os_kernel, :seed,
  sections: %{
    "default_date_time" => %{
      name: "Local Time and Date",
      module: ReflectOS.Core.Sections.DateTime,
      config: %{}
    },
    "default_calendar" => %{
      name: "US Holiday Calendar",
      module: ReflectOS.Core.Sections.Calendar,
      config: %{
        ical_url_1:
          "https://calendar.google.com/calendar/ical/en.usa.official%23holiday%40group.v.calendar.google.com/public/basic.ics"
      }
    }
  },
  layouts: %{
    "default" => %{
      name: "System Default",
      module: ReflectOS.Core.Layouts.FourCorners,
      config: %{},
      sections: %{
        top_left: [
          "default_date_time"
        ]
      }
    }
  },
  layout_managers: %{
    "default" => %{
      name: "Default Layout",
      module: ReflectOS.Core.LayoutManagers.Static,
      config: %{
        layout: "default"
      }
    }
  },
  layout_manager: "default"

host = "#{:inet.gethostname() |> elem(1)}.local"

config :reflect_os_console, ReflectOS.ConsoleWeb.Endpoint,
  url: [host: host, port: 80, scheme: "http"]
