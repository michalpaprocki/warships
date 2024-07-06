defmodule Warships.LiveMonitor do
  alias Warships.ChatStore
  alias Warships.GameStore
  use GenServer

  @name __MODULE__

@moduledoc """
Module responsible for monitoring `LiveView` socket shutdowns and deleting player from `Warships.GameStore` and `Warships.ChatStore`

"""
  def start_link(_) do
    GenServer.start_link(@name,[], name: @name)
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end
  @doc """
  Adds a module to Process.monitor/1 and stores args for later retrieval.

  ## Examples

      iex>Warships.LiveMonitor.monitor(self(), Warships.GameStore, "generic_name", "my_man")
      :ok

      iex>Warships.LiveMonitor.monitor(self(), Warships.GameStore, :generic_name, :my_man)
      ** (RuntimeError) Invalid arguments.

      iex>Warships.LiveMonitor.monitor(self(), Warships.NonExistentModule, "generic_name", "my_man")
      ** (RuntimeError) Module does not exist.

  """

  def monitor(pid, view_module, room_name, nickname) when is_pid(pid) and is_binary(room_name) and is_binary(nickname) do
    case function_exported?(view_module, :__info__, 1) do
      true ->
        GenServer.call(@name, {:monitor, pid, view_module, room_name, nickname})
       _-> raise("Module does not exist.")
    end
  end
  def monitor(_pid, _view_module, _room_name, _nickname) do
   raise("Invalid arguments.")
  end
 # # # # # # # # # # # # # # # # # # handlers # # # # # # # # # # # # # # # # # #
  def handle_call({:monitor, pid, view_module, room_name, nickname}, _from, state) do
    Process.monitor(pid)
    {:reply, :ok, %{state| views: Map.put(state.views, pid, {view_module, room_name, nickname})}}
  end

@doc """
Handles socket disconnections from `LiveView` modules.
"""
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do

    case reason do
      {:shutdown, :left} ->
        server = elem(Map.get(state.views, pid), 1)
        nickname = elem(Map.get(state.views, pid), 2)
        if server == "home" do

          new_state = Map.delete(state.views, pid)
          {:noreply, %{state | views: new_state}}
        else
          # GameStore.remove_player(server, "CPU")
          GameStore.remove_player(server, nickname)
          new_state = Map.delete(state.views, pid)
          {:noreply, %{state | views: new_state}}
        end


      {:shutdown, :closed} ->
        server = elem(Map.get(state.views, pid), 1)
        nickname = elem(Map.get(state.views, pid), 2)
        if server == "home" do

          new_state = Map.delete(state.views, pid)
          ChatStore.remove_chat_member(:CS_lobby, nickname)
          {:noreply, %{state | views: new_state}}
        else
          # GameStore.remove_player(server, "CPU")
          GameStore.remove_player(server, nickname)
          new_state = Map.delete(state.views, pid)
          ChatStore.remove_chat_member(:CS_lobby, nickname)
          {:noreply, %{state | views: new_state}}
        end
      {:shutdown, {:redirect, %{to: "/logout"}}} ->
        server = elem(Map.get(state.views, pid), 1)
        nickname = elem(Map.get(state.views, pid), 2)
        if server == "home" do

          new_state = Map.delete(state.views, pid)
          ChatStore.remove_chat_member(:CS_lobby, nickname)
          {:noreply, %{state | views: new_state}}
        else
          # GameStore.remove_player(server, "CPU")
          GameStore.remove_player(server, nickname)
          new_state = Map.delete(state.views, pid)
          ChatStore.remove_chat_member(:CS_lobby, nickname)
          {:noreply, %{state | views: new_state}}
        end
      _->
        new_views = clean_up(state)

        {:noreply, %{state|views: new_views}}
    end
      {:noreply, state}
  end

defp clean_up(state) do
  monitored_processes = Enum.filter(Enum.map(state.views, fn x -> {elem(x, 0), Process.info(elem(x, 0))} end), fn y-> elem(y, 1) != nil end)
  clean_state = Enum.filter(Map.to_list(state.views), fn x -> Enum.member?(Enum.map(monitored_processes, fn y -> elem(y, 0) end), elem(x, 0)) end)

  clean_state_map =  Enum.map(clean_state, fn {k,v} -> Map.put(%{},k, v) end)
  Enum.reduce(clean_state_map, %{}, fn x, acc ->
    Map.merge(acc, x)
  end)
end
end
