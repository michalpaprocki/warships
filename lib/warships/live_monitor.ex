defmodule Warships.LiveMonitor do
  alias Warships.ChatStore
  alias Warships.GameStore
  use GenServer

  @name __MODULE__

@doc """
Module responsible for monitoring WarshipsWeb.Rooms.RoomsLive socket shutdowns and deleting player from Warships.GameStore
"""
  def start_link(_) do
    GenServer.start_link(@name,[], name: @name)
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end
  def get_monitored() do
    GenServer.call(@name, {:get_monitored})
  end
  def get_monitored_from_process() do
    GenServer.call(@name, {:get_monitored_from_process})
  end
  def get_monitored_pids_from_process() do
    GenServer.call(@name, {:get_monitored_pids_from_process})
  end
  def monitor(pid, view_module, room_name, nickname) do
    GenServer.call(@name, {:monitor, pid, view_module, room_name, nickname})
  end
  def get_monitored_by_room_name_and_nickname(room_name, nickname) do
    GenServer.call(@name, {:get_by_room_and_nickname, room_name, nickname})
  end
  def clean_up_after_rejoin() do
    GenServer.call(@name, {:clean_up_after_rejoin})
  end
 # # # # # # # # # # # # # # # # # # handlers # # # # # # # # # # # # # # # # # #
  def handle_call({:monitor, pid, view_module, room_name, nickname}, _from, state) do
    Process.monitor(pid)
    {:reply, :ok, %{state| views: Map.put(state.views, pid, {view_module, room_name, nickname})}}
  end

  def handle_call({:get_monitored}, _from, state) do

    {:reply, state.views, state}
  end
  def handle_call({:get_monitored_from_process}, _from, state) do

    {:reply, Enum.filter(Enum.map(Map.to_list(state.views), fn x -> {elem(x, 0), Process.info(elem(x, 0))} end), fn y-> elem(y, 1) != nil end), state}
  end


  def handle_call({:get_monitored_pids_from_process}, _from, state) do
    filtered = Enum.filter(Enum.map(Map.to_list(state.views), fn x -> {elem(x, 0), Process.info(elem(x, 0))} end), fn y-> elem(y, 1) != nil end)
    {:reply, Enum.map(filtered, fn x -> elem(x,0) end), state}
  end


  def handle_call({:get_by_room_and_nickname, room_name, nickname}, _from, state) do
    pid_list = Enum.filter(Map.to_list(state.views), fn x -> elem(elem(x,1),1) == room_name && elem(elem(x,1),2) ==nickname end)
    monitored_processes = Enum.filter(Enum.map(pid_list, fn x -> {elem(x, 0), Process.info(elem(x, 0))} end), fn y-> elem(y, 1) != nil end)
    {:reply, monitored_processes, state}
  end

  def handle_call({:clean_up_after_rejoin}, _from, state) do

    new_views = clean_up(state)

    {:reply, :ok, %{state | views: new_views}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
IO.inspect(reason)

    case reason do
      {:shutdown, :left} ->
        server = elem(Map.get(state.views, pid), 1)
        nickname = elem(Map.get(state.views, pid), 2)
        if server == "home" do

          new_state = Map.delete(state.views, pid)
          {:noreply, %{state | views: new_state}}
        else
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
          GameStore.remove_player(server, nickname)
          new_state = Map.delete(state.views, pid)
          ChatStore.remove_chat_member(:CS_lobby, nickname)
          {:noreply, %{state | views: new_state}}
        end


      _->
        new_views = clean_up(state)

        {:noreply, %{state|views: new_views}}
    end

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
