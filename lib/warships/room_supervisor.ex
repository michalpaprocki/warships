defmodule Warships.RoomSupervisor do

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__,[], name: :room_supervisor)
  end

  def init(_) do

    children = [
      {DynamicSupervisor, name: __MODULE__}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
@doc """
 RoomSupervisor.start_child(:id, Warships.ShipStore, :start_link, ["test_room"])
"""
  def start_child(id, module, fun, args) do
    Supervisor.start_child(:room_supervisor, %{:id=> id, :start=>{module, fun, args}})
  end
  def count_children() do
    Supervisor.count_children(:room_supervisor)
  end
  def which_children() do
    Supervisor.which_children(:room_supervisor)
  end
  def get_running_games() do
    Enum.filter(Supervisor.which_children(:room_supervisor), fn c -> elem(c,2) == :worker end)
  end
  @doc """
  id: :atom
  """
  def delete_child(id) do
    Supervisor.terminate_child(:room_supervisor, String.to_atom(id))
    Supervisor.delete_child(:room_supervisor,  String.to_atom(id))
  end

end
