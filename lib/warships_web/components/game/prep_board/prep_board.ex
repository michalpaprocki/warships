defmodule WarshipsWeb.Game.PrepBoard.PrepBoard do
  alias Warships.GameStore
  alias Warships.ShipStore
  alias Warships.Helpers
  use Phoenix.LiveComponent
  def update(assigns, socket) do

    case assigns do
      %{:update => state, :id=> _} ->

        adjacent = Helpers.gen_adjacent_from_ship_map(state.map_of_ships)
        {:ok, socket|> assign(:ships_on_board, state.map_of_ships)|> assign(:adjacent, adjacent )}
      _->

        player_ships = ShipStore.get_player_ships(assigns.game.game, assigns.nickname)

        adjacent = Helpers.gen_adjacent_from_ship_map(player_ships)

        {:ok, socket|> assign(:hover_coords, %{"x"=>"", "y"=> ""}) |> assign(:phase, :first)|> assign(:adjacent, adjacent) |> assign(:ships_on_board, player_ships)|> assign(:selected_coords, {"", ""}) |> assign(assigns)|> assign_new(:x_range, fn  -> Helpers.generate_x_board() end)|> assign_new(:y_range,fn  -> Helpers.generate_y_board()end )}
    end

  end

  def handle_event("select_start", %{"x" => x , "y" => y}, socket) do


    {:noreply, socket |> assign(:phase, :second)|> assign(:selected_coords, {x,y})}
  end
  def handle_event("select_end", %{"x" => x , "y" => y}, socket) do
    cond do

      socket.assigns.selected_coords == {x, y} ->

            resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m1", [{x,y}])

            case resp do

              :class_full->
                send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

              _ ->

                  {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}
            end



      elem(socket.assigns.selected_coords, 0) == x ->
            case abs(String.to_integer(elem(socket.assigns.selected_coords, 1)) - String.to_integer(y)) do

              1 ->
              ship_coords =  Helpers.gen_horizontal_ship_cords_(y, elem(socket.assigns.selected_coords, 1), x)
              resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m2", ship_coords)


              case resp do

                :class_full->
                  send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                  {:noreply, socket |> assign(:phase, :first) |> assign(:selected_coords, {"", ""})}
                  _ ->

                    {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}
              end

              2 ->
              ship_coords =  Helpers.gen_horizontal_ship_cords_(y, elem(socket.assigns.selected_coords, 1), x)
              resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m3", ship_coords)

              case resp do

                :class_full->

                  send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                  {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

                  _ ->

                    {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

              end
              3 ->
              ship_coords =  Helpers.gen_horizontal_ship_cords_(y, elem(socket.assigns.selected_coords,1), x)
              resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m4", ship_coords)

              case resp do

                :class_full->
                  send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                  {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

                  _ ->

                    {:noreply, socket  |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}
              end




              _->
                send(self(), {:update_flash, {:error,  "Too long, you can spawn 4 unit long ships max."}})
              {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

            end

      elem(socket.assigns.selected_coords, 1) == y ->


            index_of_x = Enum.find_index(socket.assigns.x_range, fn xr -> xr == elem(socket.assigns.selected_coords, 0) end)
            index_of_coords_x = Enum.find_index(socket.assigns.x_range, fn xr -> xr == x end)

            case abs(index_of_x -( index_of_coords_x))  do
              1 ->
                  ship_coords = Helpers.gen_vertical_ship_cords_(x, elem(socket.assigns.selected_coords, 0), y)

                  resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m2", ship_coords)

                  case resp do

                    :class_full->
                      send(self(), {:update_flash, {:error,  "Can't place more ships of this type."}})
                      {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

                     _ ->
                        {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}
                  end

              2 ->
                  ship_coords = Helpers.gen_vertical_ship_cords_(x, elem(socket.assigns.selected_coords, 0), y)

                  resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m3", ship_coords)
                  case resp do

                    :class_full->
                      send(self(), {:update_flash, {:error, "Can't place more ships of this type."}})
                      {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

                     _ ->
                        {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}
                  end

              3 ->
                  ship_coords = Helpers.gen_vertical_ship_cords_(x, elem(socket.assigns.selected_coords, 0), y)

                  resp =  ShipStore.add_ship(socket.assigns.game.game, socket.assigns.nickname, "m4", ship_coords)

                  case resp do

                    :class_full->
                      send(self(), {:update_flash, {:error, "Can't place more ships of this type."}})
                      {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}

                     _ ->
                        {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}
                  end


              _->
                send(self(), {:update_flash, {:error, "Too long, you can spawn 4 unit long ships max."}})
              {:noreply, socket |> assign(:phase, :first)|> assign(:selected_coords, {"", ""})}
              end
     true ->
          send(self(), {:update_flash, {:error, "Invalid ship placement"}})
          {:noreply, socket  |>assign(:phase, :first)}
        end
  end
  def handle_event("randomize_coords", _unsigned_params, socket) do
    ShipStore.randomize_ship_placement(socket.assigns.game.game, socket.assigns.nickname)

    {:noreply, socket }
  end
  def handle_event("cancel_placement", %{"x" => x , "y" => y, "class" => class}, socket) do
    player_data = Map.get(socket.assigns.game.players, socket.assigns.nickname)

    case player_data.ready do

      true ->
        send(self(), {:update_flash, {:error, "Can't remove ships while flagged as 'READY'"}})
        {:noreply, socket}
      false ->
          case class do
          "m1" ->

              sid = Helpers.get_sid(socket.assigns.ships_on_board.m1, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, sid)
            {:noreply, socket}
          "m2" ->

              sid = Helpers.get_sid(socket.assigns.ships_on_board.m2, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, sid)
            {:noreply, socket}
          "m3" ->

              sid = Helpers.get_sid(socket.assigns.ships_on_board.m3, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, sid)
            {:noreply, socket}
          "m4" ->
              sid = Helpers.get_sid(socket.assigns.ships_on_board.m4, {x,y})
              ShipStore.remove_ship(socket.assigns.game.game, socket.assigns.nickname, class, sid)
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
  def handle_event("prep_board_hover", params, socket) do

    {:noreply, socket|> assign(:hover_coords, params)}
  end

end
