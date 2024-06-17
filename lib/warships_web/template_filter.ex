defmodule WarshipsWeb.TemplateFilter do


  def get_filtered({"",""}, _hover_coords, _x, _y, _len) do
    false
  end

  def get_filtered(selected_coords, hover_coords, x, y, len)   do

    case  length(Tuple.to_list(selected_coords)) do
      0-> false
      _->    abs(hd(String.to_charlist(elem(selected_coords, 0))) - hd(String.to_charlist(hover_coords["x"]))) == len
      && elem(selected_coords, 1) == hover_coords["y"]
      && to_string(y) == elem(selected_coords, 1)
      && abs(hd(String.to_charlist(hover_coords["x"])) - hd(String.to_charlist(x))) <= len

      && (hd(String.to_charlist(x)) >=  hd(String.to_charlist(hover_coords["x"]))
      && ((hd(String.to_charlist(elem(selected_coords, 0))) - hd(String.to_charlist(hover_coords["x"])) >= 0))
      || (hd(String.to_charlist(x)) <=  hd(String.to_charlist(hover_coords["x"]))
      && (hd(String.to_charlist(elem(selected_coords, 0))) - hd(String.to_charlist(hover_coords["x"])) <= 0)))

      ||

      abs(String.to_integer(elem(selected_coords, 1)) - String.to_integer(hover_coords["y"])) ==  len
      && elem(selected_coords, 0) == hover_coords["x"]
      && to_string(x) == elem(selected_coords, 0)
      && abs(String.to_integer(hover_coords["y"]) - y) <= len

      && ((y >= String.to_integer(hover_coords["y"])
      && ((String.to_integer(elem(selected_coords, 1)) - String.to_integer(hover_coords["y"])) > 0))
      || (y <= String.to_integer(hover_coords["y"])
      && ((String.to_integer(elem(selected_coords, 1)) - String.to_integer(hover_coords["y"])) < 0)))
    end
  end


end
