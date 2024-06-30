defmodule Warships.Helpers do


  def generate_x_board() do
    Enum.map(?a..?j, fn x -> <<x :: utf8>>  end)
  end
  def generate_y_board() do
    Enum.to_list(0..9)
  end
  def gen_vertical_ship_cords_(first_coord, last_coord, y) do

    code_first = first_coord |> String.to_charlist|> hd
    code_last = last_coord |> String.to_charlist|> hd
    range =  Enum.map(code_first..code_last , fn x -> <<x :: utf8>>  end)
    range_sorted = Enum.sort(range)
    Enum.map(range_sorted, fn x -> {x, y}end)
  end


def gen_horizontal_ship_cords_(first_coord, last_coord, x) do
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

def gen_adjacent_from_ship_map(ship_map) do

adjacent = %{:m1=> %{},:m2=> %{},:m3=> %{},:m4=> %{}}


adj_m1 = Map.new(Enum.map(ship_map.m1.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))
adj_m2 = Map.new(Enum.map(ship_map.m2.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))
adj_m3 = Map.new(Enum.map(ship_map.m3.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))
adj_m4 = Map.new(Enum.map(ship_map.m4.ships, fn {k,v} -> {k, gen_adjecent_tiles_list(v)} end))

adjacent |> Map.replace(:m1, adj_m1) |> Map.replace(:m2, adj_m2) |>Map.replace(:m3, adj_m3) |> Map.replace(:m4, adj_m4)

end

def get_sid(map_of_class_ships ,coords) do

  elem(Enum.at(Enum.filter(map_of_class_ships.ships, fn x -> Enum.member?(elem(x, 1).coords, coords) end ), 0), 0)

end
end
