defmodule Warships.ShipStore do


  use GenServer
@doc """
store_name: "name"
"""

  def start_link(store_name) do
    GenServer.start_link(__MODULE__, store_name, name: String.to_atom("SS_" <> store_name))
  end

  def stop_link(name) do
    GenServer.call(String.to_atom("SS_" <>name), {:suicide})
  end

  def init(init_arg) do
    IO.puts("Starting  #{"SS_" <> init_arg}")

    {:ok, %{:game => init_arg, :players => %{

       }
      }
    }
  end
  def add_player(server, name) do
    GenServer.call(String.to_atom("SS_"<>server), {:add_player, %{:name =>name}})
  end
  def remove_player(server, name) do
    GenServer.call(String.to_atom("SS_"<>server), {:remove_player, %{:name =>name}})
  end
  def get_player_ships(server, player) do
    GenServer.call(String.to_atom("SS_"<>server ), {:get_player_ships, %{:player => player}})
  end
  def get_store(server) do
    GenServer.call(String.to_atom("SS_"<>server ), {:get_store})
  end
  def ping() do
    GenServer.call(String.to_atom("SS_test_room" ), {:ping})
  end
  def test() do
    GenServer.call(String.to_atom("SS_test_room" ), {:test, %{:player => "player", :ship_coords => "ship_coords"}})
  end
  @doc """
  ## add_ship("server", "player", "class", [{"x", "y"}])
  """
  def add_ship(server, player, class, ship) do
    GenServer.call(String.to_atom("SS_" <> server), {:add_ship, %{:player => player, :class => class, :ship => ship}})
  end
   @doc """
  ## add_ship("server", "player", "class", "sid")
  """
  def remove_ship(server, player, class, sid) do
    GenServer.call(String.to_atom("SS_" <> server), {:remove_ship, %{:player => player, :class => class, :sid => sid}})
  end
  @doc """
  ## check_if_ship_hit("server", "target_player", {"x", "y"})
  """
  def check_if_ship_hit(server, target_player, coords) do
    GenServer.call(String.to_atom("SS_" <> server),{:check_if_ship_hit, %{:target_player=> target_player, :coords => coords}})
  end
################################## handlers ##################################
  def handle_call({:add_player, params}, _from, state) do

    cond do
      length(Enum.to_list(state.players)) < 2 ->
        players = Map.put(state.players, String.to_atom(params.name) ,%{:map_of_ships=>%{:m1=>%{:ships=>%{},:max=>4, :max_hits => 1},:m2=>%{:ships=>%{},:max=>3, :max_hits => 2},:m3=>%{:ships=>%{},:max=>2, :max_hits => 3},:m4=>%{:ships=>%{},:max=>1, :max_hits => 4}}})
        new_state = Map.replace(state,:players,  players)

        {:reply, "#{params.name} added as player" , new_state}

      true ->
        {:reply,{:error, "Players already at full"}, state}
    end
  end

  def handle_call({:remove_player, params}, _from, state) do
      players = Map.delete(state.players, String.to_atom(params.name))
      new_state = Map.replace(state, :players, players)

      {:reply, "#{params.name} removed as player" , new_state}
  end

  def handle_call({:add_ship, params}, _from, state) do

    case check_if_class_in_range?(params.class) do
      false-> {:reply, "Class not viable" , state}
      true ->
        player_data = Map.get(state.players, String.to_atom(params.player))

        ship_class_map = Map.get(player_data.map_of_ships, String.to_atom(params.class))
        sid = assign_sid_on_class_len(ship_class_map.ships, params.class)

        case sid do
          {:error, msg } ->
            {:reply, msg , state}
            _->

              new_ship = Map.put(ship_class_map.ships ,sid, %{:coords => params.ship, :hits => 0})
              ship_class_updated = Map.put(ship_class_map, :ships, new_ship)
              ship_class_map_updated = Map.put(player_data.map_of_ships, String.to_atom(params.class), ship_class_updated)

              player_data_updated = Map.replace(player_data, :map_of_ships, ship_class_map_updated)
              new_players_data = Map.replace(state.players, String.to_atom(params.player), player_data_updated)
              new_state = Map.replace(state, :players, new_players_data)
              WarshipsWeb.Endpoint.broadcast("game", "ship_added",  %{:player => params.player , :state =>Map.get(new_state.players, String.to_atom(params.player), [])})
            #### decide how to save coords || {[x,y], }
            {:reply, {sid, params.ship}, new_state}
        end
      end

  end
  def handle_call({:remove_ship, params}, _from, state) do

    case check_if_class_in_range?(params.class) do
      false-> {:reply, "Class not viable" , state}
      true ->
        player_data = Map.get(state.players, String.to_atom(params.player))
        ship_class_map = Map.get(player_data.map_of_ships, String.to_atom(params.class))
        new_ship_map = Map.delete(ship_class_map.ships, String.to_atom(params.sid))
        m1shipsupdated = Map.replace(ship_class_map, :ships, new_ship_map)
        new_class_map = Map.replace(player_data.map_of_ships, String.to_atom(params.class), m1shipsupdated)
        new_player_data = Map.replace(player_data, :map_of_ships, new_class_map)
        players_updated = Map.replace(state.players, String.to_atom(params.player), new_player_data)
        new_state = Map.replace(state, :players, players_updated)
        WarshipsWeb.Endpoint.broadcast("game", "ship_removed",  %{:player => params.player , :state =>Map.get(new_state.players, String.to_atom(params.player), [])})
        {:reply, {String.to_atom(params.class),String.to_atom(params.sid)}, new_state}
    end
  end
  def handle_call({:get_player_ships, params}, _from, state) do


    player_ships = Map.get(state.players, String.to_atom(params.player))

    {:reply, player_ships.map_of_ships, state}

  end
  def handle_call({:get_store}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:check_if_ship_hit, params}, _from, state) do

     player_data = Map.get(state.players, String.to_atom(params.target_player))
    resp = List.flatten(Enum.map(player_data.map_of_ships, fn {_k,v} -> Enum.filter(v.ships, fn x ->Enum.member?( elem(x, 1).coords, params.coords) end) end))


    case length(resp) do
      0->
        {:reply, {:miss, params.coords}, state}
      _->

        id= elem(Enum.at(resp, 0), 0)
        class = String.slice(Atom.to_string(id), 0,2)
        class_map = Map.get(player_data.map_of_ships, String.to_atom(class))
        ship = Map.get(class_map.ships, id)



          cond do
            ship.hits + 1 >= class_map.max_hits ->

            {:reply, {:sunk, id, params.coords}, state}

          true ->
            hits_u = Map.replace(ship, :hits, ship.hits + 1)

            ship_u = Map.put(class_map.ships, id, hits_u)
            class_map_u = Map.replace(class_map, :ships, ship_u)

            player_data_u = Map.replace(player_data.map_of_ships, String.to_atom(class), class_map_u)
            players_u = Map.replace(state.players, String.to_atom(params.target_player), %{:map_of_ships=> player_data_u})
            new_state = Map.replace(state, :players, players_u)
            {:reply, {:hit, id, params.coords}, new_state}
        end
      end
  end

  def handle_call({:test, _params}, _from, state) do

    {:reply, :normal, state}
  end
  def handle_call({:ping}, _from, state) do
    {:reply, :pong, state}
  end

  def handle_call({:suicide}, _from, state) do
    {:stop, :normal, state}
  end


################################## private ##################################

  defp assign_sid_on_class_len(map, ship_class) do

    case Enum.count(map) do
      0 ->   String.to_atom(ship_class<>"_"<> Integer.to_string(:os.system_time()))
      1 ->
        if ship_class == "m4" do
          {:error, :class_full}
          else
             String.to_atom(ship_class<>"_"<> Integer.to_string(:os.system_time()))
          end
      2 ->
        if ship_class == "m3" || ship_class == "m4"  do
        {:error, :class_full}
        else
           String.to_atom(ship_class<>"_"<> Integer.to_string(:os.system_time()))
        end
      3 ->
        if ship_class =="m2" || ship_class == "m3" || ship_class == "m4" do
          {:error, :class_full}
        else
           String.to_atom(ship_class<>"_"<> Integer.to_string(:os.system_time()))
        end

      4 -> {:error, :class_full}

    end
  end
  defp check_if_class_in_range?(ship_class), do: String.match?(Enum.at(String.graphemes(ship_class), 1), ~r/[1-4]/)
end
