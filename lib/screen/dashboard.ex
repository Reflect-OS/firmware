defmodule ReflectOS.Screen.Dashboard do
  use Scenic.Scene
  require Logger

  alias ReflectOS.Kernel.Settings.LayoutStore
  alias Scenic.Graph
  import Scenic.Primitives

  alias ReflectOS.Kernel.Layout
  alias ReflectOS.Kernel.ActiveLayout
  alias ReflectOS.Kernel.Settings.System
  alias ReflectOS.Kernel.Settings.LayoutManagerStore

  alias ReflectOS.Firmware.LayoutManagerSupervisor

  import ReflectOS.Design.Utils, only: [screen_center_group: 3]
  import ReflectOS.Kernel.Typography
  import ReflectOS.Kernel.Primitives

  @text_size 24

  defp base_graph({viewport_width, viewport_height}) do
    graph =
      Graph.build(
        font: :roboto,
        font_size: @text_size
      )

    if Nerves.Runtime.KV.get_active("nerves_fw_platform") == "host" do
      graph
      |> line({{viewport_width, 0}, {viewport_width, viewport_height}}, stroke: {1, :white})
    else
      graph
    end
  end

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _args, _opts) do
    Logger.info("Starting dashboard")

    layout_manager =
      System.layout_manager()
      |> LayoutManagerStore.get()

    System.subscribe("layout_manager")

    pid =
      case DynamicSupervisor.start_child(
             LayoutManagerSupervisor,
             {layout_manager.module, layout_manager.id}
           ) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
        error -> raise "An error happened here: #{IO.inspect(error)}"
      end

    layout = ActiveLayout.get()
    ActiveLayout.subscribe()

    System.subscribe("show_instructions")

    scene =
      scene
      |> assign(layout: layout)
      |> assign(layout_manager_pid: pid)
      |> assign(show_instructions?: System.show_instructions?())
      |> render()

    {:ok, scene}
  end

  def handle_info(
        %PropertyTable.Event{
          table: ReflectOS.ActiveLayout,
          value: layout_id
        },
        scene
      ) do
    scene =
      scene
      |> assign(layout: LayoutStore.get(layout_id))
      |> render()

    {:noreply, scene}
  end

  def handle_info(
        %PropertyTable.Event{
          property: ["system", "layout_manager"],
          value: layout_manager_id
        },
        %{assigns: %{layout_manager_pid: pid}} = scene
      ) do
    layout_manager = LayoutManagerStore.get(layout_manager_id)

    # Shutdown existing layout manager and start the new one
    DynamicSupervisor.terminate_child(
      LayoutManagerSupervisor,
      pid
    )

    new_pid =
      case DynamicSupervisor.start_child(
             LayoutManagerSupervisor,
             {layout_manager.module, layout_manager.id}
           ) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
        error -> raise "An error happened here: #{error}"
      end

    layout = ActiveLayout.get()

    scene =
      scene
      |> assign(layout: layout)
      |> assign(layout_manager_pid: new_pid)
      |> render()

    {:noreply, scene}
  end

  def handle_info(
        %PropertyTable.Event{
          property: ["system", "show_instructions"],
          value: show_instructions
        },
        scene
      ) do
    scene =
      scene
      |> assign(show_instructions?: show_instructions)
      |> render()

    {:noreply, scene}
  end

  defp render(scene) do
    Logger.info("rendering dashboard")

    graph =
      base_graph(System.viewport_size())
      |> render_layout(scene.assigns[:layout])
      |> render_instructions(scene.assigns[:show_instructions?])

    push_graph(scene, graph)
  end

  defp render_layout(
         graph,
         %Layout{
           id: layout_id,
           module: layout_module
         }
       )
       when is_binary(layout_id) do
    graph
    |> layout_module.add_to_graph(layout_id)
  end

  # Ignore requests to render invalid layouts
  defp render_layout(graph, invalid) do
    Logger.info("Ignoring invalid Layout: #{IO.inspect(invalid)}")
    graph
  end

  defp render_instructions(graph, true) do
    # TODO - fix this for hosts
    console_url =
      if Nerves.Runtime.KV.get_active("nerves_fw_platform") == "host" do
        {:ok, [{lan_ip, _, _} | _rest]} = :inet.getif()

        lan_ip =
          lan_ip
          |> Tuple.to_list()
          |> Enum.join(".")

        "http://#{lan_ip}:4000/about"
      else
        "http://#{:inet.gethostname() |> elem(1)}.local/about"
      end

    message = """
      ReflectOS allows you to change this layout,
      add sections, and much more using a web app.

      Scan the QR code below or visit
      #{console_url}
      to get started!
    """

    graph
    |> screen_center_group(
      [
        text_spec(
          "Welcome to your dashboard!",
          h5() |> bold()
        ),
        text_spec(
          message,
          [t: {0, 80}] |> h7()
        ),
        qr_code_spec(console_url, width: 250, t: {-250 / 2, 340}),
        text_spec(
          """
          All set?

          These instructions can be disabled on
          the Settings page of the web app.
          """,
          [t: {0, 644}] |> h7()
        )
      ],
      [text_align: :center, text_base: :top] |> h7()
    )
  end

  defp render_instructions(graph, _), do: graph
end
