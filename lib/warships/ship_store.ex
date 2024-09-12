defmodule Warships.ShipStore do
  alias Warships.CoordsGenStore
  alias Warships.Helpers
  alias Warships.AppRegistry

  @moduledoc """
  A store for ships coords.
  """

  def start_link(store_name) do
    GenServer.start_link(__MODULE__, store_name,
      name: AppRegistry.using_via("ShipStore: " <> store_name)
    )
  end

  def stop_link(store_name) do
    GenServer.call(AppRegistry.using_via("ShipStore: " <> store_name), {:suicide})
  end

  def init(init_arg) do
    IO.puts("Starting #{"ShipStore: " <> init_arg}")

    {:ok, %{:game => init_arg, :players => %{}}}
  end

  def add_player(server, name) do
    GenServer.call(
      AppRegistry.using_via("ShipStore: " <> server),
      {:add_player, %{:name => name}}
    )
  end

  def remove_player(server, name) do
    GenServer.call(
      AppRegistry.using_via("ShipStore: " <> server),
      {:remove_player, %{:name => name}}
    )
  end

  def get_player_ships(server, player) do
    GenServer.call(
      AppRegistry.using_via("ShipStore: " <> server),
      {:get_player_ships, %{:player => player}}
    )
  end

  def get_store(server) do
    GenServer.call(AppRegistry.using_via("ShipStore: " <> server), {:get_store})
  end

  def randomize_ship_placement(server, player) do
    GenServer.call(
      AppRegistry.using_via("ShipStore: " <> server),
      {:randomize, %{:player => player}}
    )
  end

  def ping(server) do
    GenServer.call(AppRegistry.using_via("ShipStore: " <> server), {:ping})
  end

  @doc """
  ## add_ship("server", "player", "class", [{"x", "y"}])
  """
  def add_ship(server, player, class, ship) do
    GenServer.call(
      AppRegistry.using_via("ShipStore: " <> server),
      {:add_ship, %{:player => player, :class => class, :ship => ship}}
    )
  end

  @doc """
  ## add_ship("server", "player", "class", "sid")
  """
  def remove_ship(server, player, class, sid) do
    GenServer.call(
      AppRegistry.using_via("ShipStore: " <> server),
      {:remove_ship, %{:player => player, :class => class, :sid => sid}}
    )
  end

  @doc """
  ## check_if_ship_hit("server", "target_player", {"x", "y"})
  """
  def check_if_ship_hit(server, target_player, coords) do
    GenServer.call(
      AppRegistry.using_via("ShipStore: " <> server),
      {:check_if_ship_hit, %{:target_player => target_player, :coords => coords}}
    )
  end

  ################################## handlers ##################################
  def handle_call({:add_player, params}, _from, state) do
    cond do
      length(Enum.to_list(state.players)) < 2 ->
        players =
          Map.put(state.players, params.name, %{
            :map_of_ships => %{
              :m1 => %{:ships => %{}, :max => 4, :max_hits => 1},
              :m2 => %{:ships => %{}, :max => 3, :max_hits => 2},
              :m3 => %{:ships => %{}, :max => 2, :max_hits => 3},
              :m4 => %{:ships => %{}, :max => 1, :max_hits => 4}
            }
          })

        new_state = Map.replace(state, :players, players)

        {:reply, "#{params.name} added as player", new_state}

      true ->
        {:reply, {:error, "Players already at full"}, state}
    end
  end

  def handle_call({:remove_player, params}, _from, state) do
    players = Map.delete(state.players, params.name)
    new_state = Map.replace(state, :players, players)

    {:reply, "#{params.name} removed as player", new_state}
  end

  def handle_call({:add_ship, params}, _from, state) do
    case check_if_class_in_range?(params.class) do
      false ->
        {:reply, "Class not viable", state}

      true ->
        player_data = Map.get(state.players, params.player)

        ship_class_map = Map.get(player_data.map_of_ships, String.to_atom(params.class))
        sid = assign_sid_on_class_len(ship_class_map.ships, params.class)

        case sid do
          {:error, msg} ->
            {:reply, msg, state}

          _ ->
            new_ship = Map.put(ship_class_map.ships, sid, %{:coords => params.ship, :hits => 0})
            ship_class_updated = Map.put(ship_class_map, :ships, new_ship)

            ship_class_map_updated =
              Map.put(player_data.map_of_ships, String.to_atom(params.class), ship_class_updated)

            player_data_updated = Map.replace(player_data, :map_of_ships, ship_class_map_updated)
            new_players_data = Map.replace(state.players, params.player, player_data_updated)
            new_state = Map.replace(state, :players, new_players_data)

            WarshipsWeb.Endpoint.broadcast("game", "ship_added", %{
              :player => params.player,
              :state => Map.get(new_state.players, params.player, [])
            })

            #### decide how to save coords || {[x,y], }
            {:reply, {sid, params.ship}, new_state}
        end
    end
  end

  def handle_call({:remove_ship, params}, _from, state) do
    case check_if_class_in_range?(params.class) do
      false ->
        {:reply, "Class not viable", state}

      true ->
        player_data = Map.get(state.players, params.player)
        ship_class_map = Map.get(player_data.map_of_ships, String.to_existing_atom(params.class))
        new_ship_map = Map.delete(ship_class_map.ships, params.sid)
        m1shipsupdated = Map.replace(ship_class_map, :ships, new_ship_map)

        new_class_map =
          Map.replace(
            player_data.map_of_ships,
            String.to_existing_atom(params.class),
            m1shipsupdated
          )

        new_player_data = Map.replace(player_data, :map_of_ships, new_class_map)
        players_updated = Map.replace(state.players, params.player, new_player_data)
        new_state = Map.replace(state, :players, players_updated)

        WarshipsWeb.Endpoint.broadcast("game", "ship_removed", %{
          :player => params.player,
          :state => Map.get(new_state.players, params.player, [])
        })

        {:reply, {String.to_existing_atom(params.class), params.sid}, new_state}
    end
  end

  def handle_call({:get_player_ships, params}, _from, state) do
    player_ships = Map.get(state.players, params.player)
    {:reply, player_ships.map_of_ships, state}
  end

  def handle_call({:get_store}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:check_if_ship_hit, params}, _from, state) do
    player_data = Map.get(state.players, params.target_player)

    resp =
      List.flatten(
        Enum.map(player_data.map_of_ships, fn {_k, v} ->
          Enum.filter(v.ships, fn x -> Enum.member?(elem(x, 1).coords, params.coords) end)
        end)
      )

    case length(resp) do
      0 ->
        {:reply, {:miss, params.coords}, state}

      _ ->
        id = elem(Enum.at(resp, 0), 0)
        class = String.slice(id, 0, 2)
        class_map = Map.get(player_data.map_of_ships, String.to_atom(class))
        ship = Map.get(class_map.ships, id)

        cond do
          ship.hits + 1 >= class_map.max_hits ->
            {:reply, {:sunk, id, params.coords}, state}

          true ->
            hits_u = Map.replace(ship, :hits, ship.hits + 1)

            ship_u = Map.put(class_map.ships, id, hits_u)
            class_map_u = Map.replace(class_map, :ships, ship_u)

            player_data_u =
              Map.replace(player_data.map_of_ships, String.to_atom(class), class_map_u)

            players_u =
              Map.replace(state.players, params.target_player, %{:map_of_ships => player_data_u})

            new_state = Map.replace(state, :players, players_u)
            {:reply, {:hit, id, params.coords}, new_state}
        end
    end
  end

  def handle_call({:randomize, params}, _from, state) do
    map_of_ships = gen_ship_coords(state.game, state.players[params.player].map_of_ships)
    map = push_ships(map_of_ships, %{})
    new_map_of_ships = Map.replace(state.players[params.player], :map_of_ships, map)
    new_player = Map.replace(state.players, params.player, new_map_of_ships)
    new_state = Map.replace(state, :players, new_player)

    WarshipsWeb.Endpoint.broadcast("game", "ship_added", %{
      :player => params.player,
      :state => Map.get(new_state.players, params.player, [])
    })

    {:reply, :random, new_state}
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
      0 ->
        ship_class <> "_" <> Integer.to_string(:os.system_time())

      1 ->
        if ship_class == "m4" do
          {:error, :class_full}
        else
          ship_class <> "_" <> Integer.to_string(:os.system_time())
        end

      2 ->
        if ship_class == "m3" || ship_class == "m4" do
          {:error, :class_full}
        else
          ship_class <> "_" <> Integer.to_string(:os.system_time())
        end

      3 ->
        if ship_class == "m2" || ship_class == "m3" || ship_class == "m4" do
          {:error, :class_full}
        else
          ship_class <> "_" <> Integer.to_string(:os.system_time())
        end

      4 ->
        {:error, :class_full}
    end
  end

  defp check_if_class_in_range?(ship_class),
    do: String.match?(Enum.at(String.graphemes(ship_class), 1), ~r/[1-4]/)

  defp gen_ship_coords(game, map_of_ships) do
    CoordsGenStore.start(game)

    map_of_ships =
      Enum.map(Enum.reverse(Map.to_list(map_of_ships)), fn {k, v} ->
        gen_class(game, k, v.max)
      end)

    CoordsGenStore.stop(game)
    map_of_ships
  end

  defp gen_class(game, class, amount) do
    map = %{
      class => %{
        :max => amount,
        :max_hits => String.to_integer(String.slice(Atom.to_string(class), 1, 2)),
        :ships => %{}
      }
    }

    list_of_tuples =
      for _n <- Range.to_list(1..amount) do
        {Atom.to_string(class) <> "_" <> Integer.to_string(:os.system_time()),
         %{:coords => gen_ships(game, class), :hits => 0}}
      end

    new_ships = put_in_map(map[class].ships, list_of_tuples)

    list_of_maps = Map.replace(map[class], :ships, new_ships)

    Map.replace(map, class, list_of_maps)
  end

  defp put_in_map(map, list) do
    case length(list) do
      1 ->
        Map.put(map, elem(hd(list), 0), elem(hd(list), 1))

      _x ->
        new_map = Map.put(map, elem(hd(list), 0), elem(hd(list), 1))
        put_in_map(new_map, List.delete_at(list, 0))
    end
  end

  defp push_ships(list_of_ship_maps, map) do
    case length(list_of_ship_maps) do
      1 ->
        Map.put(
          map,
          elem(hd(Map.to_list(hd(list_of_ship_maps))), 0),
          elem(hd(Map.to_list(hd(list_of_ship_maps))), 1)
        )

      _x ->
        new_map =
          Map.put(
            map,
            elem(hd(Map.to_list(hd(list_of_ship_maps))), 0),
            elem(hd(Map.to_list(hd(list_of_ship_maps))), 1)
          )

        push_ships(List.delete_at(list_of_ship_maps, 0), new_map)
    end
  end

  defp gen_ships(game, class) do
    case class do
      :m4 ->
        gen_coords(game, 4, [])

      :m3 ->
        gen_coords(game, 3, [])

      :m2 ->
        gen_coords(game, 2, [])

      _ ->
        gen_coords(game, 1, [])
    end
  end

  def gen_coords(game, length, init_value) do
    case length do
      1 ->
        new_coords = [Enum.random(CoordsGenStore.get_coords(game)) | init_value]

        CoordsGenStore.reduce(
          game,
          Enum.map(new_coords, fn x -> Helpers.gen_adjacent_tiles(x) end)
        )

        #  prep sid
        new_coords

      x ->
        coords = CoordsGenStore.get_coords(game)
        random_coord = Enum.random(coords)
        CoordsGenStore.save_len(game, x - 1)
        new_coords = grow_coords(game, [random_coord], Enum.random(0..3), x - 1, init_value)
        CoordsGenStore.reduce(game, Helpers.gen_adjacent_tiles_list(new_coords))
        new_coords
    end
  end

  defp grow_coords(game, coords, dir, len, _init) do
    case dir do
      0 ->
        new_coords =
          List.flatten(
            List.insert_at(
              [coords],
              0,
              {elem(hd(coords), 0), Integer.to_string(String.to_integer(elem(hd(coords), 1)) + 1)}
            )
          )

        case len do
          1 ->
            if Enum.member?(
                 Enum.map(new_coords, fn x ->
                   !Enum.member?(CoordsGenStore.get_coords(game), x)
                 end),
                 true
               ) do
              grow_coords(
                game,
                [Enum.random(CoordsGenStore.get_coords(game))],
                dir,
                CoordsGenStore.get_len(game),
                []
              )
            else
              new_coords
            end

          x ->
            grow_coords(game, new_coords, dir, x - 1, new_coords)
        end

      1 ->
        new_coords =
          List.flatten(
            List.insert_at(
              [coords],
              0,
              {<<hd(String.to_charlist(elem(hd(coords), 0))) + 1::utf8>>, elem(hd(coords), 1)}
            )
          )

        case len do
          1 ->
            if Enum.member?(
                 Enum.map(new_coords, fn x ->
                   !Enum.member?(CoordsGenStore.get_coords(game), x)
                 end),
                 true
               ) do
              grow_coords(
                game,
                [Enum.random(CoordsGenStore.get_coords(game))],
                dir,
                CoordsGenStore.get_len(game),
                []
              )
            else
              new_coords
            end

          x ->
            grow_coords(game, new_coords, dir, x - 1, new_coords)
        end

      2 ->
        new_coords =
          List.flatten(
            List.insert_at(
              [coords],
              0,
              {elem(hd(coords), 0), Integer.to_string(String.to_integer(elem(hd(coords), 1)) - 1)}
            )
          )

        case len do
          1 ->
            if Enum.member?(
                 Enum.map(new_coords, fn x ->
                   !Enum.member?(CoordsGenStore.get_coords(game), x)
                 end),
                 true
               ) do
              grow_coords(
                game,
                [Enum.random(CoordsGenStore.get_coords(game))],
                dir,
                CoordsGenStore.get_len(game),
                []
              )
            else
              new_coords
            end

          x ->
            grow_coords(game, new_coords, dir, x - 1, new_coords)
        end

      3 ->
        new_coords =
          List.flatten(
            List.insert_at(
              [coords],
              0,
              {<<hd(String.to_charlist(elem(hd(coords), 0))) - 1::utf8>>, elem(hd(coords), 1)}
            )
          )

        case len do
          1 ->
            if Enum.member?(
                 Enum.map(new_coords, fn x ->
                   !Enum.member?(CoordsGenStore.get_coords(game), x)
                 end),
                 true
               ) do
              grow_coords(
                game,
                [Enum.random(CoordsGenStore.get_coords(game))],
                dir,
                CoordsGenStore.get_len(game),
                []
              )
            else
              new_coords
            end

          x ->
            grow_coords(game, new_coords, dir, x - 1, new_coords)
        end
    end
  end
end
