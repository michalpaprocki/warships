defmodule WarshipsWeb.Game.Board.Board do
  alias Warships.ShipStore
  alias Warships.GameStore
  use Phoenix.LiveComponent

  def update(assigns, socket) do
    my_ships = ShipStore.get_player_ships(assigns.game.game, assigns.nickname)

    IO.inspect(my_ships.m1)
    # IO.inspect(Enum.map(my_ships.m1, fn x -> x end))
    IO.inspect(Enum.sort(my_ships.m1))

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:x_range, fn -> generate_x_board() end)
     |> assign_new(:y_range, fn -> generate_y_board() end)
     |> assign(:my_ships, my_ships)
     |> assign_new(:panel, fn -> "both" end)}
  end

  def handle_event("shoot", %{"x" => x, "y" => y}, socket) do
    cond do
      socket.assigns.nickname == socket.assigns.game.turn ->
        GameStore.shoot(socket.assigns.game.game, socket.assigns.nickname, {x, y})

        {:noreply, socket}

      true ->
        send(self(), {:update_flash, {:error, "Opponent's turn, please wait..."}})
        {:noreply, socket}
    end
  end

  def handle_event("shoot", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("set_board_panel", %{"panel" => panel, "value" => ""}, socket) do
    {:noreply, socket |> assign(:panel, panel)}
  end

  ####  ↓↓ possibly, a better place for board generation would be GameStore.init/1  ↓↓ ####
  defp generate_x_board() do
    Enum.map(?a..?j, fn x -> <<x::utf8>> end)
  end

  defp generate_y_board() do
    Enum.to_list(0..9)
  end

  ####  ↑↑ #######################################################################  ↑↑ ####
end
