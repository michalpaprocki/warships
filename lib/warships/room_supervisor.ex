defmodule Warships.RoomSupervisor do
@moduledoc """
  A dynamic supervisor module responsible for spawning and terminating `Warships.GameStore` and `Warships.ShipStore` processes from `Warships.RoomStore` module.
"""
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__,[], name: :room_supervisor)
  end

  def init(_) do
    :ets.new(:refs, [:public, :named_table, :set])
    children = [
      {DynamicSupervisor, name: __MODULE__}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
@doc """
Adds a processes to supervision.

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
    Enum.filter(Supervisor.which_children(:room_supervisor), fn c -> elem(c,2) == :worker && elem(c,1) != :undefined end)
  end
  @doc """
  Terminates and deletes supervised processes.

  ## Examples
      RoomSupervisor.delete_child("process_id_name")

  """
  def delete_child(id) do
    Supervisor.terminate_child(:room_supervisor, id)
    Supervisor.delete_child(:room_supervisor, id)
  end

end
