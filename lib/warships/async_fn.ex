defmodule Warships.AsyncFn do
  def get_var_back(var) do
    :timer.sleep(1000)
    var
  end
end
