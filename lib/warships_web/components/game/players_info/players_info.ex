defmodule WarshipsWeb.Game.PlayersInfo.PlayersInfo do
  use Phoenix.LiveComponent

  def update(assigns, socket) do
    map_of_ships = %{"m1"=> 0, "m2"=>0, "m3"=>0, "m4"=>0}
    hits = Enum.map(assigns.game.players, fn x ->{elem(x,0), Enum.map(elem(x, 1).ships_hit, fn y -> {elem(y, 0), elem(elem(y, 1), 0)} end)} end)
    sunken = Enum.map(hits, fn x->{elem(x,0), Enum.filter(elem(x,1), fn y -> elem(y, 1) == :sunk end)} end)
    new_map = Enum.map(sunken, fn x -> {elem(x,0), Enum.frequencies(Enum.map(elem(x,1), fn y -> String.slice(elem(y, 0), 0..1)end))} end)
    p_info = Enum.map(new_map, fn x -> {elem(x,0), Map.merge(map_of_ships, elem(x,1))} end)

    {:ok, socket |> assign(assigns) |> assign(:players_info, p_info)}
  end
end
