defmodule Warships.CPUPlayer do
  alias Warships.GameStore
  alias Warships.AppRegistry
  alias Warships.CoordsGenStore
  alias Warships.Helpers
  use GenServer




  def start_link(game_name, cpu_name) do
    GenServer.start_link(__MODULE__, %{:game_name => game_name, :cpu_name => cpu_name}, name: AppRegistry.using_via("CPU_player: "<>game_name))
   end

  def stop_link(game_name) do
    CoordsGenStore.stop(game_name<>" CPU_coords")
    GenServer.call(AppRegistry.using_via("CPU_player: "<>game_name), {:suicide})
  end

  def init(init_arg) do
    CoordsGenStore.start(init_arg.game_name<>" CPU_coords")
    IO.puts("Starting #{"CPU_player: "<> init_arg.game_name}")

    {:ok, %{:cpu_name => init_arg.cpu_name, :game => init_arg.game_name, :shots_coords => []}}
  end
  def reset_CPU_player(game_name) do
    GenServer.call(AppRegistry.using_via("CPU_player: "<>game_name), {:reset})
  end
  def reset_CPU_player(game_name, cpu_name) do
    GenServer.call(AppRegistry.using_via("CPU_player: "<>game_name), {:reset, cpu_name})
  end
  def is_CPU_player?(game_name, cpu_name) do
    GenServer.call(AppRegistry.using_via("CPU_player: "<>game_name), {:is_cpu, cpu_name})
  end

  def handle_info(%{:result => result, :coords => coords}, state) do

      case result do
        :miss ->
          check_for_dir(state.game)

          CoordsGenStore.reduce(state.game<>" CPU_coords", [coords])
          {:noreply, state}

        :hit ->
          CoordsGenStore.save_hit(state.game<>" CPU_coords", coords)
          {:noreply, state}

        :sunk ->
          hits = CoordsGenStore.get_hits(state.game<>" CPU_coords")
          updated_hits = [coords | hits.coords]
          sunk_and_adjacent = Helpers.gen_adjacent_tiles_list(updated_hits)

          CoordsGenStore.reduce(state.game<>" CPU_coords", sunk_and_adjacent)
          CoordsGenStore.reset_hits(state.game<>" CPU_coords")
          CoordsGenStore.reset_tested_dir(state.game<>" CPU_coords")
          {:noreply, state}
      end

  end


  def handle_info(%{:turn => turn}, state) do

    if turn == state.cpu_name do
      case check_for_hits(state.game) do
        nil ->

          init_hit = CoordsGenStore.get_init_hit(state.game<>" CPU_coords")
          case init_hit do
            nil -> Process.sleep(1000)
              random_coord = Enum.random(CoordsGenStore.get_coords(state.game<>" CPU_coords"))

              GameStore.shoot(state.game, state.cpu_name, random_coord)

              {:noreply, state}
            init_hit ->
              Process.sleep(1000)


            shoot(state, init_hit, hd(CoordsGenStore.get_dir(state.game<>" CPU_coords")), false)
              {:noreply, state}
          end

        {_coords, nil} ->

          shoot(state, [CoordsGenStore.get_init_hit(state.game<>" CPU_coords")], get_last_tested_dir_and_swap(state.game), false)
           {:noreply, state}
        {coords, dir} ->

          shoot(state, coords, dir, true)
          {:noreply, state}
      end
  else
    {:noreply, state}
    end
  end


  def handle_info(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
  end
  def handle_call({:is_cpu, cpu_name}, _from, state) do

      if cpu_name == state.cpu_name do
        {:reply, true, state}
      else
        {:reply, false, state}
      end

  end
  def handle_call({:suicide}, _from, state) do

    {:stop, :normal, :kaput, state}
  end
  def handle_call({:reset}, _from, state) do
      CoordsGenStore.stop(state.game<>" CPU_coords")
      CoordsGenStore.start(state.game<>" CPU_coords")
    {:reply, :ok, %{:cpu_name => state.cpu_name, :game => state.game, :shots_coords => []}}
  end
  def handle_call({:reset, cpu_name}, _from, state) do
      CoordsGenStore.stop(state.game<>" CPU_coords")
      CoordsGenStore.start(state.game<>" CPU_coords")
    {:reply, :ok, %{:cpu_name => cpu_name, :game => state.game, :shots_coords => []}}
  end
  defp check_for_dir(game) do
    case CoordsGenStore.get_dir(game<>" CPU_coords") do
      nil -> nil
      dir -> CoordsGenStore.save_tested_dir(game<>" CPU_coords", dir)
    end
  end
  defp check_for_hits(game) do
      hits = CoordsGenStore.get_hits(game<>" CPU_coords")
      case hits do
        %{:dir => nil, :coords => []} ->

          nil
        %{:coords => coords, :dir=> dir} ->
        {coords, dir}
      end
  end
  defp randomize_dir(tested_dirs_list) do

    Enum.random(Enum.filter(0..3, fn x -> !Enum.member?(tested_dirs_list, x) end))

  end
  defp get_tested_dirs(game) do

    tested_dirs =  Enum.uniq(CoordsGenStore.get_tested_dir(game<>" CPU_coords"))
    case length(tested_dirs) do
      1 ->

        if hd(tested_dirs) == 1 do

          [3]
        else
          dir = [abs(hd(tested_dirs) -2)]

          dir
        end

      _->

        tested_dirs

    end
  end
  defp get_last_tested_dir_and_swap(game) do
    tested_dir =  Enum.uniq(CoordsGenStore.get_tested_dir(game<>" CPU_coords"))

    case tested_dir do
      []->
      Enum.random(0..3)
      list ->
        if hd(list) == 1 do

          3
        else
          dir = abs(hd(list) - 2)

          dir
        end
    end
  end


  defp shoot(state, coords, dir, from_head?) do

  case dir do
    0 ->
    # {x - 1, y}

      new_coord = {<<hd(String.to_charlist(elem(get_from_list(coords, from_head?), 0)))  -1 :: utf8>>, elem(get_from_list(coords, from_head?), 1)}

      if CoordsGenStore.coord_is_valid?(state.game<>" CPU_coords", new_coord) do
        CoordsGenStore.save_dir(state.game<>" CPU_coords", 0)

        Process.sleep(1000)
        GameStore.shoot(state.game, state.cpu_name, new_coord)
        {:noreply, state}
      else
        CoordsGenStore.save_tested_dir(state.game<>" CPU_coords", 0)
        shoot(state, coords, randomize_dir(get_tested_dirs(state.game)), false)
      end
    1 ->
    # {x, y + 1}
      new_coord = {<<hd(String.to_charlist(elem(get_from_list(coords, from_head?), 0))) :: utf8>>, Integer.to_string(String.to_integer(elem(get_from_list(coords, from_head?), 1)) +1)}
      if CoordsGenStore.coord_is_valid?(state.game<>" CPU_coords", new_coord)  do
          CoordsGenStore.save_dir(state.game<>" CPU_coords", 1)
          Process.sleep(1000)
          GameStore.shoot(state.game, state.cpu_name, new_coord)
          {:noreply, state}

      else
        CoordsGenStore.save_tested_dir(state.game<>" CPU_coords", 1)
        shoot(state, coords, randomize_dir(get_tested_dirs(state.game)), false)
      end
    2 ->
    # {x + 1, y}
      new_coord = {<<hd(String.to_charlist(elem(get_from_list(coords, from_head?), 0)))  +1 :: utf8>>, elem(get_from_list(coords, from_head?), 1)}
      if CoordsGenStore.coord_is_valid?(state.game<>" CPU_coords", new_coord) do
          CoordsGenStore.save_dir(state.game<>" CPU_coords", 2)
          Process.sleep(1000)
          GameStore.shoot(state.game, state.cpu_name, new_coord)
          {:noreply, state}

      else
        CoordsGenStore.save_tested_dir(state.game<>" CPU_coords", 2)
        shoot(state, coords, randomize_dir(get_tested_dirs(state.game)), false)
      end
    3 ->
    # {x, y - 1}
      new_coord = {<<hd(String.to_charlist(elem(get_from_list(coords, from_head?), 0))) :: utf8>>, Integer.to_string(String.to_integer(elem(get_from_list(coords, from_head?), 1)) -1)}
      if CoordsGenStore.coord_is_valid?(state.game<>" CPU_coords", new_coord)  do
          CoordsGenStore.save_dir(state.game<>" CPU_coords", 3)
          Process.sleep(1000)
          GameStore.shoot(state.game, state.cpu_name, new_coord)
          {:noreply, state}

      else
        CoordsGenStore.save_tested_dir(state.game<>" CPU_coords", 3)
        shoot(state, coords, randomize_dir(get_tested_dirs(state.game)), false)
      end
  end
  end
  defp get_from_list(list, from_head?) do
    if from_head? do
      hd(list)
    else
      Enum.at(list, -1)
    end
  end
end
