defmodule WarshipsWeb.Game.PrepBoard.PrepBoard do
  alias Warships.GameStore
  alias Warships.ShipStore
  use Phoenix.LiveComponent
  def update(assigns, socket) do

    case assigns do
      %{:update => state, :id=> _} ->

        adjacent = gen_adjacent_from_ship_map(state.map_of_ships)
        {:ok, socket|> assign(:ships_on_board, state.map_of_ships)|> assign(:adjacent, adjacent )}
      _->

        player_ships = ShipStore.get_player_ships(assigns.game.game, assigns.nickname)

        adjacent = gen_adjacent_from_ship_map(player_ships)

        {:ok, socket |> assign(:phase, :first)|> assign(:adjacent, adjacent) |> assign(:ships_on_board, player_ships)|> assign(:selected_coords, []) |> assign(assigns)|> assign_new(:x_range, fn  -> generate_x_board() end)|> assign_new(:y_range,fn  -> generate_y_board() end )}
    end

  end

  def handle_event("select_start", %{"x" => x , "y" => y}, socket) do


    {:noreply, socket |> assign(:phase, :second)|> assign(:selected_coords, [{x,y}])}
  end
  def handle_event("select_end", %{"x" => x , "y" => y}, socket) do
    cond do

      Enum.at(socket.assigns.selected_coords, 0) == {x, y} ->

            resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m1", [{x,y}])

            case resp do

              :class_full->
                send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

              _ ->

                  {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}
            end



      elem(Enum.at(socket.assigns.selected_coords, 0), 0) == x ->
            case abs(String.to_integer(elem(Enum.at(socket.assigns.selected_coords, 0), 1)) - String.to_integer(y)) do

              1 ->
              ship_coords =  gen_horizontal_ship_cords_(y, elem(Enum.at(socket.assigns.selected_coords, 0),1), x)
              resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m2", ship_coords)


              case resp do

                :class_full->
                  send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                  {:noreply, socket |> assign(:phase, :first) |> assign(:selected_coords, [])}
                  _ ->

                    {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}
              end

              2 ->
              ship_coords =  gen_horizontal_ship_cords_(y, elem(Enum.at(socket.assigns.selected_coords, 0),1), x)
              resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m3", ship_coords)

              case resp do

                :class_full->

                  send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                  {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

                  _ ->

                    {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

              end
              3 ->
              ship_coords =  gen_horizontal_ship_cords_(y, elem(Enum.at(socket.assigns.selected_coords, 0),1), x)
              resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m4", ship_coords)

              case resp do

                :class_full->
                  send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                  {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

                  _ ->

                    {:noreply, socket  |> assign(:phase, :first)|> assign(:selected_coords, [])}
              end




              _->
                send(self(), {:update_flash, {:error,  "Too long, you can spawn 4 unit long ships max."}})
              {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

            end

      elem(Enum.at(socket.assigns.selected_coords, 0), 1) == y ->


            index_of_x = Enum.find_index(socket.assigns.x_range, fn xr -> xr == elem(Enum.at(socket.assigns.selected_coords, 0), 0) end)
            index_of_coords_x = Enum.find_index(socket.assigns.x_range, fn xr -> xr == x end)

            case abs(index_of_x -( index_of_coords_x))  do
              1 ->
                  ship_coords = gen_vertical_ship_cords_(x, elem(Enum.at(socket.assigns.selected_coords, 0), 0), y)

                  resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m2", ship_coords)

                  case resp do

                    :class_full->
                      send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                      {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

                     _ ->
                        {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}
                  end

              2 ->
                  ship_coords = gen_vertical_ship_cords_(x, elem(Enum.at(socket.assigns.selected_coords, 0), 0), y)

                  resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m3", ship_coords)
                  case resp do

                    :class_full->
                      send(self(), {:update_flash, {:error, "Can't place more ships of this type."}})
                      {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

                     _ ->
                        {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}
                  end

              3 ->
                  ship_coords = gen_vertical_ship_cords_(x, elem(Enum.at(socket.assigns.selected_coords, 0), 0), y)

                  resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m4", ship_coords)

                  case resp do

                    :class_full->
                      send(self(), {:update_flash, {:error, "Can't place more ships of this type."}})
                      {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}

                     _ ->
                        {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}
                  end


              _->
                send(self(), {:update_flash, {:error, "Too long, you can spawn 4 unit long ships max."}})
              {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, [])}
              end
     true ->
          send(self(), {:update_flash, {:error, "Invalid ship placement"}})
          {:noreply, socket  |>assign(:phase, :first)}
        end
  end

  def handle_event("cancel_placement", %{"x" => x , "y" => y, "class" => class}, socket) do
    player_data = Map.get(socket.assigns.game.players, String.to_atom(socket.assigns.nickname))

    case player_data.ready do

      true ->
        send(self(), {:update_flash, {:error, "Can't remove ships while flagged as 'READY'"}})
        {:noreply, socket}
      false ->
          case class do
          "m1" ->

              sid = get_sid(socket.assigns.ships_on_board.m1, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, Atom.to_string(sid))
            {:noreply, socket}
          "m2" ->

              sid = get_sid(socket.assigns.ships_on_board.m2, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, Atom.to_string(sid))
            {:noreply, socket}
          "m3" ->

              sid = get_sid(socket.assigns.ships_on_board.m3, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, Atom.to_string(sid))
            {:noreply, socket}
          "m4" ->
              sid = get_sid(socket.assigns.ships_on_board.m4, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, Atom.to_string(sid))
            {:noreply, socket}
              _->
                {:noreply, socket}
          end
      end
  end
  def handle_event("toggle_ready", _unsigned_params, socket) do

  GameStore.toggle_ready(socket.assigns.game.game, socket.assigns.nickname)

    {:noreply, socket}
  end

####  ↓↓ possibly, a better place for board generation would be GameStore.init/1  ↓↓ ####
defp generate_x_board() do
  Enum.map(?a..?j, fn x -> <<x :: utf8>>  end)
end
  defp generate_y_board() do
    Enum.to_list(0..9)
  end

####  ↑↑ #######################################################################  ↑↑ ####

defp gen_vertical_ship_cords_(first_coord, last_coord, y) do

  code_first = first_coord |> String.to_charlist|> hd
  code_last = last_coord |> String.to_charlist|> hd
  range =  Enum.map(code_first..code_last , fn x -> <<x :: utf8>>  end)
  range_sorted = Enum.sort(range)
  Enum.map(range_sorted, fn x -> {x, y}end)
end

defp gen_horizontal_ship_cords_(first_coord, last_coord, x) do
  range = Enum.to_list(String.to_integer(first_coord)..String.to_integer(last_coord))
  Enum.sort(Enum.map(range, fn vx -> {x, Integer.to_string(vx)}end))
end

defp gen_adjecent_tiles_list(list_of_coords) do

      list_unfiltered = List.flatten(Enum.map(list_of_coords.coords, fn x -> gen_adjacent_tiles(x) end))
      Enum.uniq(Enum.filter(list_unfiltered, fn x -> !Enum.member?(list_of_coords.coords, x) end))

end

defp gen_adjacent_tiles(tuple) do

  x = elem(tuple, 0)
  y = String.to_integer(elem(tuple, 1))
  x_code_point = hd(String.to_charlist(x))
    x_range_unfiltered = Enum.map(x_code_point-1..x_code_point+1 , fn x -> <<x :: utf8>> end)
    x_range = Enum.filter(x_range_unfiltered, fn x -> String.match?(x, ~r/[a-z]/) end)
    y_range = Enum.filter(Enum.to_list(y-1..y+1), fn x -> Enum.member?(Enum.to_list(0..9), x)end)
    Enum.map(x_range, fn x-> Enum.map(y_range, fn y -> {x, to_string(y)}end) end)

end

defp gen_adjacent_from_ship_map(ship_map) do

  adjacent = %{:m1=> %{},:m2=> %{},:m3=> %{},:m4=> %{}}


  adj_m1 = Map.new(Enum.map(ship_map.m1.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))
  adj_m2 = Map.new(Enum.map(ship_map.m2.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))
  adj_m3 = Map.new(Enum.map(ship_map.m3.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))
  adj_m4 = Map.new(Enum.map(ship_map.m4.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))

  adjacent |> Map.replace(:m1, adj_m1) |> Map.replace(:m2, adj_m2) |>Map.replace(:m3, adj_m3) |> Map.replace(:m4, adj_m4)

end

defp get_sid(map_of_class_ships ,coords) do

  elem(Enum.at(Enum.filter(map_of_class_ships.ships, fn x -> Enum.member?(elem(x, 1).coords, coords) end ), 0), 0)

end


# obsolete since moved to broadcasts #

# defp remove_ships(socket, map_of_class_ships ,coords, class) do
#   ships = Enum.map(map_of_class_ships.ships, fn x -> x end )
#   sid = elem(Enum.at(Enum.filter(ships, fn {_k,v} -> Enum.member?(v, coords) end ),0), 0)
#   ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, Atom.to_string(sid))
#   new_m = Map.delete(map_of_class_ships.ships, sid)
#   new_ships_map = Map.replace(map_of_class_ships, :ships, new_m)
#   {sid, Map.replace(socket.assigns.ships_on_board, String.to_atom(class), new_ships_map)}
# end

# defp remove_adjacent_tiles(socket, class, sid) do
#   adj_class_map = Map.get(socket.assigns.adjacent, String.to_atom(class))
#   new_adj_class_map = Map.delete(adj_class_map, sid)
#   Map.replace(socket.assigns.adjacent, String.to_atom(class), new_adj_class_map)
# end
end
