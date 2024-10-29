defmodule ReflectOS.Screen.Boot do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort
  import Scenic.Primitives

  import ReflectOS.Kernel.Typography

  import ReflectOS.Design.Utils, only: [screen_center_group: 3]

  @graph Graph.build()
         |> text(
           "Welcome Back",
           [id: :title, t: {540, 300}, text_align: :center, text_base: :middle] |> h1() |> bold()
         )
         |> text(
           "It's good to see you again!",
           [id: :subtitle, t: {540, 375}, text_align: :center, text_base: :middle]
           |> h5()
           |> light()
         )

  defp graph(), do: @graph

  @impl true
  def init(%Scene{} = scene, _args, _opts) do
    wifi_configured? = VintageNetWizard.wifi_configured?("wlan0")
    internet_connected? = VintageNet.get(["interface", "wlan0", "connection"]) == :internet

    cond do
      internet_connected? ->
        # Handle case where scenic is restarting and we're already connected
        # Go right to dashboard
        {:ok, scene, {:continue, {:set_root_screen, ReflectOS.Screen.Dashboard}}}

      wifi_configured? and !internet_connected? ->
        # Pending internet connnection (likely during boot up)
        # Show the loading screen

        counter = 1

        graph =
          graph()
          |> screen_center_group(
            [
              text_spec(connection_message(counter))
            ],
            [text_align: :center, text_base: :top] |> h7()
          )

        tick_counter(counter)

        {:ok, push_graph(scene, graph)}

      !wifi_configured? ->
        # Since there's not configuration, jump right to the NetworkSetup screen
        {:ok, scene, {:continue, {:set_root_screen, ReflectOS.Screen.NetworkSetup}}}
    end
  end

  defp connection_message(counter) do
    "Working on connecting to your network\n\n#{String.duplicate(".", counter)}"
  end

  @impl true
  def handle_continue({:set_root_screen, screen}, %Scene{viewport: viewport} = scene) do
    ViewPort.set_root(viewport, screen)
    {:noreply, scene}
  end

  @impl true
  def handle_info(
        {:tick_counter, counter},
        %Scene{viewport: viewport} = scene
      ) do
    {dns_result, _} = response = :inet_res.gethostbyname(~c"0.pool.ntp.org")
    connection_state = VintageNet.get(["interface", "wlan0", "connection"])

    Logger.info(
      "Counter: #{counter}, DNS: #{inspect(response)}, Conn: #{inspect(connection_state)}"
    )

    graph =
      cond do
        dns_result == :ok and counter >= 7 ->
          # If we're showing the loading screen, show for at least 7 seconds
          # This avoids a quick flash if the internet happens to connect
          # shortly after we show the loading screen
          Logger.info("Connection made and coundown complete, loading dashboard")
          ViewPort.set_root(viewport, ReflectOS.Screen.Dashboard)
          Graph.build()

        counter >= 30 ->
          ViewPort.set_root(viewport, ReflectOS.Screen.NetworkSetup)
          Graph.build()

        true ->
          # Tick the display to indicate we're still waiting to connect
          tick_counter(counter)

          graph()
          |> screen_center_group(
            [
              text_spec(connection_message(counter))
            ],
            [text_align: :center, text_base: :top] |> h7()
          )
      end

    {:noreply, push_graph(scene, graph)}
  end

  def handle_info(_ignore, %Scene{} = scene) do
    {:noreply, scene}
  end

  defp tick_counter(counter) do
    Process.send_after(self(), {:tick_counter, counter + 1}, 1_000)
  end
end
