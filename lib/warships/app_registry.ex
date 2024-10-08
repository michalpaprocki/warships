defmodule Warships.AppRegistry do

  def start_link() do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end
  def using_via(key) do
    {:via, Registry, {__MODULE__, key}}
  end
  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
  def lookup(name) do
    # maybe raise an exception here
   case Registry.lookup(__MODULE__, name) do
      [] ->
        false
      pid ->
        elem(hd(pid), 0)
   end
  end
end
