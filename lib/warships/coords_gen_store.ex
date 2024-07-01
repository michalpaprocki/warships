defmodule Warships.CoordsGenStore do
  use GenServer

alias Warships.Helpers

  def start() do

    GenServer.start(__MODULE__, [], name: :coords_gen_store)
  end

  def stop() do
    GenServer.call(:coords_gen_store, {:suicide})
  end

  def init(_init_arg) do
    x_axis = Helpers.generate_x_board()
    y_axis = Helpers.generate_y_board()

    coords =
    for x <- x_axis do
      for y <- y_axis do
        {x,Integer.to_string(y)}
      end
    end
    {:ok, %{:coords => List.flatten(coords), :current_len => 0}}
  end
  def reduce(list) do
    GenServer.call(:coords_gen_store, {:reduce, list})
  end
  def get_coords() do
    GenServer.call(:coords_gen_store, {:get_coords})
  end
  def get_len() do
    GenServer.call(:coords_gen_store, {:get_len})
  end
  def save_len(len) do
    GenServer.call(:coords_gen_store, {:save_len, len})
  end
  # # # # # # # # # # handlers # # # # # # # # # #
  def handle_call({:suicide}, _from, state) do
    {:stop, :shutdown, :ok, state}
  end
  def handle_call({:get_coords}, _from, state) do
    {:reply, state.coords, state}
  end
  def handle_call({:reduce, list}, _from, state) do
    # IO.puts("""
    # list of coords to reduce:
    # #{inspect(list)}

    # """)
    new_coords = Enum.filter(state.coords, fn x-> !Enum.member?(List.flatten(list), x) end)
    new_state  = Map.replace(state, :coords, new_coords)
    # IO.puts("""
    # list of coords reduced:
    # #{inspect(length(new_coords))}

    # """)
    {:reply, new_state, new_state }
  end
  def handle_call({:save_len, len}, _from, state) do
   new_state = Map.replace(state, :current_len, len)
    {:reply, :ok, new_state}
  end
  def handle_call({:get_len}, _from, state) do

     {:reply, state.current_len, state}
   end
end
