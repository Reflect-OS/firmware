defmodule ReflectOS.Design.Utils do
  alias Scenic.Graph
  import Scenic.Primitives, only: [add_specs_to_graph: 2, add_specs_to_graph: 3]

  @viewport_width Application.compile_env(:reflect_os_firmware, [:viewport, :size]) |> elem(0)
  @viewport_height Application.compile_env(:reflect_os_firmware, [:viewport, :size]) |> elem(1)

  @center_x @viewport_width / 2
  @center_y @viewport_height / 2

  def screen_center_group(%Graph{} = graph, specs, opts \\ [])
      when is_list(specs) and length(specs) > 0 do
    temp_graph = Graph.build() |> add_specs_to_graph(specs)

    {_, top, _, bottom} = Graph.bounds(temp_graph)

    x = @center_x
    y = @center_y - (bottom - top) / 2

    graph
    |> Graph.delete(:content)
    |> add_specs_to_graph(specs, [t: {x, y}, id: :content] ++ opts)
  end
end
