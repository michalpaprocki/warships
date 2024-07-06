defmodule Warships.GameStore do
  alias Warships.CPUPlayer
  alias Warships.RefStore
  alias Warships.RoomStore
  alias Warships.ShipStore
  alias Warships.AppRegistry
  use GenServer

  def start_link(store_name) do

   GenServer.start_link(__MODULE__, store_name, name: AppRegistry.using_via("GameStore: "<>store_name))

  end

  def stop_link(server) do

    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:suicide})
  end

  def init(init_arg) do
    IO.puts("Starting #{"GameStore: "<> init_arg}")
    {:ok, %{:game => init_arg, :turn => "unset", :state => :awaiting_players, :winner => "", :players => %{}, :rematch =>%{:challenger=> :none, :request=> false}}}
  end

  def restart(server) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:restart})
  end
  def request_another(server, player) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:request_rematch, %{:player => player}})
  end
  def accept_rematch(server) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:accept_rematch})
  end


  @doc """
    server: string
    name: string
    #### add_player("room_name", "foo")

  """
  def add_player(server, name, is_human? \\ true) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:add_player, %{:name => name, :is_human? => is_human?}})
  end

  @doc """
    server: string
    name: string
    #### remove_player("room_name", "foo")

  """
  def remove_player(server, name) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:remove_player, %{:name => name}})
  end
  def toggle_ready(server, player) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:toggle_ready, %{:player=>player}})
  end
  def get_store(server) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:get_store})
  end

  def shoot(server, shooter, coords) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:shoot, %{:shooter => shooter, :coords => coords}})
  end
  def get_players(server) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:get_players})
  end
  def get_player_count(server) do
    GenServer.call(AppRegistry.using_via("GameStore: "<>server), {:get_player_count})
  end


  ################################## handlers ##################################


  def handle_call({:add_player, params}, _from, state) do

    cond do
      Map.has_key?(state.players, params.name) ->

        {:reply, {:rejoin}, state}

      true ->

        case length(Map.keys(state.players)) do
          2 ->

            {:reply, {:error, :room_is_full}, state}
          _ ->

          ShipStore.add_player(state.game, params.name)
          new_players_ =
            Map.put(state.players,params.name, %{
              :is_human? => params.is_human?,
              :ships_hit => %{},
              :shots_coords => [],
              :ready => player_cpu?(state.game, params.name, params.is_human?)
            })

          new_state_ = Map.put(state, :players, new_players_)

          if length(Map.keys(new_state_.players)) == 2 do
            updated_new_state_ = Map.replace(new_state_, :state, :prep)
            random = elem(Enum.random(updated_new_state_.players), 0)

            updated_with_turn_state = Map.replace(updated_new_state_, :turn, random)

            WarshipsWeb.Endpoint.broadcast("game", "game_state_update",
              updated_with_turn_state
            )

            WarshipsWeb.Endpoint.broadcast("player_changes", "player_added", %{:room=> state.game, :player_count => length(Map.to_list(updated_with_turn_state.players))})
            {:reply, :ok, updated_with_turn_state}
          else

            halt_termination_process(self())

            WarshipsWeb.Endpoint.broadcast("player_changes", "player_added", %{:room=> state.game, :player_count => length(Map.to_list(new_state_.players))})
            {:reply, :ok, new_state_}
          end
        end
    end
  end

  def handle_call({:remove_player, params}, _from, state) do
    players = Enum.map(state.players, fn x-> elem(x,0) end)

    for p <- players do

      if state.players[p].is_human? == false && Warships.AppRegistry.lookup("CPU_player: "<>state.game)  do
          CPUPlayer.stop_link(state.game)
      end
      ShipStore.remove_player(state.game, p)

      if p != params.name && state.players[p].is_human? do
        ShipStore.add_player(state.game, p)
      end
    end


    new_players_ = state.players |> Map.delete(params.name) |> Map.delete(get_non_human_player(state))


    cond do
      length(Map.to_list(new_players_)) == 0 ->
        new_state = state|> Map.replace(:players, new_players_)
        WarshipsWeb.Endpoint.broadcast("player_changes", "player_removed", %{:room=> state.game, :player_count => length(Map.to_list(new_state.players))})

        begin_termination_process(self())

        {:reply, :OK, %{new_state | :state => :awaiting_players}}
        true ->

          new_players_clean =
            Map.get(new_players_, Enum.at(Map.keys(new_players_), 0)) |> Map.replace(:ready, false) |> Map.replace(:ships_hit, %{}) |> Map.replace(:shots_coords, [])
          new_players_u = Map.replace(new_players_,Enum.at(Map.keys(new_players_), 0), new_players_clean)
          new_players = Map.put(state, :players, new_players_u)
          rematch_u =
            new_players.rematch |> Map.replace(:challenger, :noone) |> Map.replace(:request, false)
          new_state = new_players |> Map.replace(:rematch, rematch_u )|> Map.replace(:state, :awaiting_players)

          WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
          WarshipsWeb.Endpoint.broadcast("player_changes", "player_removed", %{:room=> state.game, :player_count => length(Map.to_list(new_state.players))})
          {:reply, :OK, new_state}
        end
    end
  def handle_call({:toggle_ready, params}, _from, state) do
    player = Map.get(state.players, params.player)
    new_player = Map.replace(player, :ready, !player.ready)
    players_updated = Map.replace(state.players, params.player,  new_player)
    new_state = Map.replace(state, :players, players_updated)

    cond do
      elem(Enum.at(new_state.players, 0), 1).ready && elem(Enum.at(new_state.players, 1), 1).ready ->
        new_state_updated = Map.put(new_state, :state, :game)
        WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state_updated)
        send_to_cpu_player(state, %{:turn=>state.turn})
        {:reply, :ok, new_state_updated}
        true ->
          WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
          {:reply, :ok, new_state}
      end

  end
  def handle_call({:get_store}, _from, state) do
    {:reply, state, state}
  end
  def handle_call({:get_players}, _from, state) do
    players = Enum.map(Map.to_list(state.players), fn x -> elem(x, 0) end)
    {:reply, players, state}
  end
  def handle_call({:get_player_count}, _from, state) do
    player_count = length(Map.to_list(state.players))
    {:reply, player_count, state}
  end

  def handle_call({:suicide}, _from, state) do

    {:stop, :normal, :kaput, state}
  end
  def handle_call({:shoot, params}, _from, state) do

    data = Map.get(state.players, params.shooter)
    target = elem(Enum.at(Enum.filter(state.players, fn {k,_v} -> k != params.shooter end), 0), 0)

    shot = ShipStore.check_if_ship_hit(state.game, target, params.coords)

    # # might a be good idea to check whether coords already exist in the list and keep shots fired/missed in ShipStore # #

    IO.puts("""
    state.players[params.shooter] = #{inspect(state.players[params.shooter])}
    """)
    case shot do
      {:miss, coords} ->

        if state.players[params.shooter].is_human? == false do
          IO.puts("|| sending to CPU [miss]||")
          send_to_cpu_player(state, %{:result => :miss, :coords => coords })
        end

        shots_fired_ = [coords | Map.get(data, :shots_coords)]
        new_data_ = Map.replace(data, :shots_coords, shots_fired_)
        new_players_data_ = Map.replace(state.players, params.shooter, new_data_)
        next_turn = Map.replace(state, :turn, target)
        new_state = Map.replace(next_turn, :players, new_players_data_)
        WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
        send_to_cpu_player(state, %{:turn => target})
        {:reply, :ok, new_state}

      {:hit, id, coords} ->
        if state.players[params.shooter].is_human? == false do
          IO.puts("|| sending to CPU [hit]||")
          send_to_cpu_player(state, %{:result => :hit ,:coords => coords })
        end
        case  Enum.filter(Map.to_list(data.ships_hit), fn a -> elem(a,0) == id end) do

          []->

            new_hits = Map.put(data.ships_hit, id, {:hit, [coords]})
            new_data   = Map.replace(data, :ships_hit, new_hits)
            new_players = Map.replace(state.players, params.shooter, new_data)
            next_turn = Map.replace(state, :turn, target)
            new_state = Map.replace(next_turn, :players, new_players)
            WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
            send_to_cpu_player(state, %{:turn => target})
            {:reply, :ok, new_state}

          filtered_ships_hit->

            new_coords = [coords | elem(elem(Enum.at(filtered_ships_hit,0), 1),1)]
            tuple_u  = {:hit, new_coords}
            ship_u = Map.replace(data.ships_hit, id, tuple_u)
            new_ships_hit = Map.replace(data, :ships_hit, ship_u)
            new_players = Map.replace(state.players, params.shooter, new_ships_hit)
            next_turn = Map.replace(state, :turn, target)
            new_state = Map.replace(next_turn, :players, new_players)
            WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
            send_to_cpu_player(state, %{:turn => target})
            {:reply, :ok, new_state}
        end

      {:sunk, id, coords} ->
        if state.players[params.shooter].is_human? == false do
          IO.puts("|| sending to CPU [sunk[]]||")
          send_to_cpu_player(state, %{:result => :sunk ,:coords => coords })
        end
          case Enum.filter(Map.to_list(data.ships_hit), fn a -> elem(a,0) == id end) do
            [] ->

              new_map = Map.put(data.ships_hit, id, {:sunk, [coords]})
              ships_hit_u = Map.replace(data, :ships_hit, new_map)
              new_players = Map.replace(state.players, params.shooter, ships_hit_u)
              next_turn = Map.replace(state, :turn, target)

              ships_sunken? = check_if_all_ships_sunken?(ships_hit_u.ships_hit, 10)
              case ships_sunken? do
                true ->
                  state_change =
                  next_turn |> Map.replace(:winner, params.shooter) |> Map.replace(:state, :game_over)
                  new_state = Map.replace(state_change, :players, new_players)
                  WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
                  send_to_cpu_player(state, :reset)
              {:reply, :ok, new_state}

                false ->
                  new_state = Map.replace(next_turn, :players, new_players)
                  WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
                  send_to_cpu_player(state, %{:turn => target})
              {:reply, :ok, new_state}
              end

            filtered_ships_hit ->
              new_coords = [coords | elem(elem(Enum.at(filtered_ships_hit,0), 1),1)]
              tuple_u  = {:sunk, new_coords}
              ship_u = Map.replace(data.ships_hit, id, tuple_u)
              new_ships_hit = Map.replace(data, :ships_hit, ship_u)
              new_players = Map.replace(state.players, params.shooter, new_ships_hit)
              next_turn = Map.replace(state, :turn, target)

              ships_sunken? = check_if_all_ships_sunken?(ship_u, 10)
              case ships_sunken? do
                true ->
                  state_change =
                  next_turn |> Map.replace(:winner, params.shooter) |> Map.replace(:state, :game_over)
                  new_state = Map.replace(state_change, :players, new_players)
                  WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
                  send_to_cpu_player(state, :reset)
              {:reply, :ok, new_state}

                false ->
                  new_state = Map.replace(next_turn, :players, new_players)
                  WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
                  send_to_cpu_player(state, %{:turn => target})
              {:reply, :ok, new_state}
              end


          end
    end
  end
  def handle_call({:restart}, _from, state) do

    new_state=%{:game => state.game , :turn => :unset, :state => :awaiting_players, :winner => "", :players => %{}}

    {:reply, :ok, new_state}
  end
  def handle_call({:request_rematch, params}, _from, state) do
    # if Enum.member?(Map.keys(state.players), "CPU") do
    if Enum.map(Map.to_list(state.players), fn x -> elem(x, 1).is_human? == true end) do
        new_state = reset_game(state)
        CPUPlayer.reset_CPU_player(state.game)

      {:reply, :ok, new_state}
    else
      rematch = %{:challenger=> params.player, :request => true}
      new_state = Map.replace(state, :rematch, rematch)
      WarshipsWeb.Endpoint.broadcast("game", "game_state_update", new_state)
      {:reply, :ok, new_state}
    end
  end
  def handle_call({:accept_rematch}, _from, state) do
   new_state = reset_game(state)
    {:reply, :ok, new_state}
  end



  def handle_info(:timeout, state) do
    RefStore.delete_ref(self())
    RoomStore.delete_room(state.game)
    IO.puts("""
      #{"GS_"<>state.game} and #{"SS_"<>state.game} terminating due to inactivity...
    """)
    {:noreply, state}
  end

  defp player_cpu?(game, name, is_human?) do

    if is_human? == false do
      ShipStore.randomize_ship_placement(game, name)
      CPUPlayer.start_link(game, name)

      true
    else
      false
    end
  end
  defp send_to_cpu_player(state, msg) do
        Process.send(Warships.AppRegistry.lookup("CPU_player: "<>state.game) , msg, [])

  end
  defp begin_termination_process(pid) do
    ref = Process.send_after(pid, :timeout, 10 * 60 * 1000)
    RefStore.add_ref(pid, ref)
  end

  defp halt_termination_process(pid) do
    ref = RefStore.get_ref(pid)
    case length(ref) do
      0-> :ok
      _-> Process.cancel_timer(hd(hd(ref)))
    end
  end

  defp check_if_all_ships_sunken?(map_of_hit_ships, amount_of_ships) do
    length(Enum.map(map_of_hit_ships, fn x -> x end)) == amount_of_ships  && !Enum.member?(Enum.map(map_of_hit_ships, fn x -> elem(elem(x,1),0) end), :hit)
  end

  defp reset_game(state) do
    IO.puts("reseting game")
    players = Enum.map(state.players, fn x-> elem(x,0) end)
    for p <- players do
      ShipStore.remove_player(state.game, p)
      ShipStore.add_player(state.game, p)
    end

    players_list = Enum.map(players, fn x -> Map.put(%{

    }, x, %{
    :is_human? => state.players[x].is_human?,
    :ships_hit => %{},
    :shots_coords => [],
    :ready => player_cpu?(state.game, x, state.players[x].is_human?)}) end)

    players_map = Enum.reduce(players_list, fn x, y -> Map.merge(x,y) end)

    new_state = %{:game => state.game, :turn => Enum.at(Enum.filter(players, fn x-> x != state.winner end), 0), :state => :prep, :winner => "", :players => players_map , :rematch =>%{:challenger=> :none, :request=> false}}

    WarshipsWeb.Endpoint.broadcast("game", "game_state_update",new_state)
    new_state
  end
  defp get_non_human_player(state) do
    case Enum.filter(Map.to_list(state.players), fn x -> elem(x, 1).is_human? == false end) do
      [] ->
        nil
      _->
        elem(hd(Enum.filter(Map.to_list(state.players), fn x -> elem(x, 1).is_human? == false end)), 0)
    end
  end
end
