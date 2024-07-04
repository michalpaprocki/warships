defmodule Warships.CoordsGenStore do
  use GenServer
alias Warships.AppRegistry
alias Warships.Helpers


  def start(name) do

    GenServer.start(__MODULE__, name, name: AppRegistry.using_via("gen_store: "<>name))
  end
  def stop(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:suicide})
  end
  def init(name) do
    IO.puts("Starting gen_store: "<>name)
    x_axis = Helpers.generate_x_board()
    y_axis = Helpers.generate_y_board()

    coords =
    for x <- x_axis do
      for y <- y_axis do
        {x, Integer.to_string(y)}
      end
    end

    {:ok, %{:coords => List.flatten(coords), :current_len => 0,:tested_dir => [], :hits => %{:init_coord=> nil, :coords => [], dir: nil}}}
  end
  def test(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:test})
  end
  def reduce(name, list) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:reduce, list})
  end
  def get_coords(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:get_coords})
  end
  def get_len(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:get_len})
  end
  def save_len(name, len) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:save_len, len})
  end
  def save_hit(name, coords) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:save_hit, coords})
  end
  def get_hits(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:get_hits})
  end
  def get_init_hit(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:get_init_hit})
  end
  def reset_hits(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:reset_hits})
  end
  def save_dir(name, dir) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:save_dir, dir})
  end

  def get_dir(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:get_dir})
  end
  def save_tested_dir(name, dir) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:save_tested_dir, dir})
  end
  def get_tested_dir(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:get_tested_dir,})
  end
  def reset_tested_dir(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:reset_tested_dir,})
  end
  def coord_is_valid?(name, coords) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:coord_is_valid?, coords})
  end
  def get_store(name) do
    GenServer.call(AppRegistry.using_via("gen_store: "<>name), {:get_store})
  end
  # # # # # # # # # # handlers # # # # # # # # # #
  def handle_call({:suicide}, _from, state) do
    {:stop, :shutdown, :ok, state}
  end
  def handle_call({:get_coords}, _from, state) do

    {:reply, state.coords, state}
  end
  def handle_call({:reduce, list}, _from, state) do


    new_coords = Enum.filter(state.coords, fn x-> !Enum.member?(List.flatten(list), x) end)
    new_state  = Map.replace(state, :coords, new_coords)

    {:reply, :ok, new_state }
  end
  def handle_call({:save_len, len}, _from, state) do
     new_state = Map.replace(state, :current_len, len)
    {:reply, :ok, new_state}
  end

  def handle_call({:get_len}, _from, state) do

    {:reply, state.current_len, state}
  end
  def handle_call({:test}, _from, state) do

    {:reply, state, state}
  end
   def handle_call({:save_hit, coords}, _from, state) do
     new_coords = [coords | state.hits.coords]
     case state.hits.init_coord do
       nil ->
        new_hit_coords = %{state.hits | :coords => new_coords, :init_coord => coords}

       new_state = %{state | :hits => new_hit_coords}

      {:reply, :ok,  new_state}
      _->
        new_hit_coords = %{state.hits | :coords => new_coords}

        new_state = %{state | :hits => new_hit_coords}

       {:reply, :ok,  new_state}
     end

  end
  def handle_call({:get_init_hit}, _from, state) do

    {:reply, state.hits.init_coord, state}
  end
  def handle_call({:get_hits}, _from, state) do

    {:reply, state.hits, state}
  end
  def handle_call({:reset_hits}, _from, state) do

    {:reply, :ok, %{state | :hits => %{:init_coord => nil, :coords => [], dir: nil}}}
  end
  def handle_call({:save_dir, dir}, _from, state) do
      new_state = %{state | :hits => %{state.hits | :dir => dir}}
    {:reply, :ok, new_state }
  end
  def handle_call({:get_dir}, _from, state) do

    {:reply, state.hits.dir, state}
  end
  def handle_call({:save_tested_dir, dir}, _from, state) do
    new_state = %{state | :hits => %{state.hits | :dir => nil}}

    {:reply, :ok, %{new_state | :tested_dir => [dir | new_state.tested_dir]}}
  end
  def handle_call({:get_tested_dir}, _from, state) do

    {:reply, state.tested_dir, state}
  end
  def handle_call({:reset_tested_dir}, _from, state) do

    {:reply, :ok, %{state | :tested_dir => []}}
  end
  def handle_call({:coord_is_valid?, coords}, _from, state) do

      case Enum.member?(state.coords, coords) do
        true ->
          {:reply, true, state}
        false ->
          {:reply, false, state}
      end

  end
  def handle_call({:get_store}, _from, state) do
    {:reply, state, state}
  end
end
