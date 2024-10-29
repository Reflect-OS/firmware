defmodule ReflectOS.Screen.NetworkSetup do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort
  import Scenic.Primitives

  import ReflectOS.Design.Utils, only: [screen_center_group: 3]
  import ReflectOS.Kernel.Typography
  import ReflectOS.Kernel.Primitives

  @success_duration 10

  @default_config_message "To get started, use your device to connect\nto the wifi network shown below:"

  @graph Graph.build()
         |> text(
           "",
           [id: :title, t: {540, 300}, text_align: :center, text_base: :middle] |> h1() |> bold()
         )
         |> text(
           "",
           [id: :subtitle, t: {540, 375}, text_align: :center, text_base: :middle]
           |> h5()
           |> light()
         )

  defp graph(), do: @graph

  def init(%Scene{} = scene, args, _opts) do
    Logger.info("[NetworkSetup] - Starting VintageNetWizard")

    args = if args != nil, do: args, else: %{}

    # Grab whether there's been any configuration before we start the wizard
    # The wizard's AP-mode network will cause wifi_configured?/1 to always return true
    configured? =
      if function_exported?(VintageNetWizard, :wifi_configured?, 1) do
        VintageNetWizard.wifi_configured?("wlan0")
      else
        true
      end

    Logger.debug(
      "[NetworkSetup] - Network config: #{inspect(VintageNet.get(["interface", "wlan0", "config"]))}"
    )

    graph =
      case run_wizard() do
        :ok ->
          Logger.info("[NetworkSetup] - Started VintageNetWizard")

          user_initiated_setup? = Map.get(args, :setup, false)

          if configured? do
            if user_initiated_setup? do
              render_reconfigure()
            else
              render_connection_error()
            end
          else
            render_welcome()
          end

        {:error, error} ->
          Logger.error(error)

          Graph.build()
          |> text("An error occured: #{inspect(error)}",
            translate: {20, 20},
            font_size: 44
          )
      end

    {:ok, push_graph(scene, graph)}
  end

  def render_welcome() do
    graph()
    |> Graph.modify(:title, &text(&1, "Welcome"))
    |> Graph.modify(:subtitle, &text(&1, "It's good to see you!"))
    |> screen_center_group(
      network_config_specs(),
      [text_align: :center, text_base: :top] |> h7()
    )
  end

  def render_reconfigure() do
    graph()
    |> Graph.modify(:title, &text(&1, "Network Setup"))
    |> Graph.modify(:subtitle, &text(&1, "Let's make a connection!"))
    |> screen_center_group(
      network_config_specs(),
      [text_align: :center, text_base: :top] |> h7()
    )
  end

  def render_connection_error() do
    graph()
    |> Graph.modify(:title, &text(&1, "Network Error"))
    |> Graph.modify(:subtitle, &text(&1, "Couldn't connect to any configured network"))
    |> screen_center_group(
      network_config_specs(
        "Please try to setup wifi again by connecting\nto the wifi network shown below:"
      ),
      [text_align: :center, text_base: :top] |> h7()
    )
  end

  def render_success(countdown) do
    graph()
    |> Graph.modify(:title, &text(&1, "Success"))
    |> Graph.modify(:subtitle, &text(&1, "We have a real connection!"))
    |> screen_center_group(
      [
        text_spec(
          "Network connection has been verified!\n\nShowing dashboard in #{countdown} seconds.",
          id: :success_body
        )
      ],
      [text_align: :center, text_base: :top] |> h7()
    )
  end

  defp network_config_specs(message \\ @default_config_message) do
    wifi_config_url = "http://reflectos-wifi.config:90"

    ssid =
      if function_exported?(VintageNetWizard.APMode, :ssid, 0) do
        VintageNetWizard.APMode.ssid()
      else
        "reflectos-ssid"
      end

    [
      text_spec(
        message,
        h7()
      ),
      text_spec(
        ssid,
        [t: {0, 80}] |> h6() |> bold()
      ),
      text_spec(
        "Then, scan the QR code or enter\n#{wifi_config_url}\ninto your browser to configure wifi for your new ReflectOS system.",
        [t: {0, 160}] |> h7()
      ),
      qr_code_spec(wifi_config_url, width: 250, t: {-250 / 2, 330})
    ]
  end

  ###
  # :tick_success
  ###

  def handle_info(
        :tick_success,
        %Scene{viewport: viewport, assigns: %{success_countdown: 0}}
      ) do
    # Countdown complete, go dashboard
    Logger.info("[NetworkConfig] Success countdown complete, going to dashboard")
    ViewPort.set_root(viewport, ReflectOS.Screen.Dashboard)
  end

  def handle_info(
        :tick_success,
        %Scene{viewport: viewport, assigns: %{success_coundown: 0}}
      ) do
    # Countdown complete, go dashboard
    Logger.info("[NetworkConfig] Success countdown complete, going to dashboard")
    ViewPort.set_root(viewport, ReflectOS.Screen.Dashboard)
  end

  def handle_info(
        :tick_success,
        %Scene{} = scene
      ) do
    countdown = Scene.get(scene, :success_countdown, @success_duration)
    Logger.info("[NetworkConfig] Ticking success screen, count: #{countdown}")

    graph = render_success(countdown)

    scene =
      scene
      |> assign(:success_countdown, countdown - 1)

    Process.send_after(self(), :tick_success, 1_000)

    {:noreply, push_graph(scene, graph)}
  end

  def handle_info(
        :reinit,
        %Scene{} = scene
      ) do
    {:ok, scene} = init(scene, nil, [])
    {:noreply, scene}
  end

  def handle_info(
        {:check_status, count},
        %Scene{} = scene
      ) do
    connection_state = VintageNet.get(["interface", "wlan0", "connection"])

    if connection_state == :internet do
      Process.send(self(), :tick_success, [])
    else
      if count < 5 do
        Process.send_after(self(), {:check_status, count + 1}, 1_000)
      else
        Process.send(self(), :reinit, [])
      end
    end

    {:noreply, scene}
  end

  defp run_wizard() do
    if function_exported?(VintageNetWizard, :run_wizard, 1) do
      VintageNetWizard.run_wizard(
        ui: [title: "ReflectOS - Wifi Setup"],
        on_exit: {__MODULE__, :handle_net_wizard_exit, [self()]}
      )
    else
      :ok
    end
  end

  def handle_net_wizard_exit(self_pid) do
    connection_state = VintageNet.get(["interface", "wlan0", "connection"])

    Logger.info(
      "[NetworkConfig] Exiting vintage net wizard set up with wifi connection: #{connection_state}"
    )

    if connection_state == :internet do
      Process.send(self_pid, :tick_success, [])
    else
      Process.send_after(self_pid, {:check_status, 0}, 1_000)
    end
  end
end
