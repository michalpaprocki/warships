defmodule Warships.ChatStore do
  @moduledoc """
  An store for chat members
  """
  use GenServer

  @doc """
  Starts the generic server process.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, "lobby", name: String.to_atom("CS_" <> "lobby"))
  end

  def init(init_arg) do
    IO.puts("Creating  #{"CS_" <> init_arg}")
    chat_members = MapSet.new()

    {:ok, %{:room_name => init_arg, :chat_members => chat_members, :last_10_msgs => []}}
  end

  def ping(server) do
    GenServer.call(server, {:ping})
  end

  def test(server) do
    GenServer.call(server, {:test})
  end

  def add_chat_member(server, member) do
    GenServer.call(server, {:add, %{:member => to_string(member)}})
  end

  def remove_chat_member(server, member) do
    GenServer.call(server, {:remove, %{:member => to_string(member)}})
  end

  def get_chat_members(server) do
    GenServer.call(server, {:get_all})
  end

  def save_last_msg(server, msg) do
    GenServer.call(server, {:save_msg, msg})
  end

  def async_get_chat_members(server) do
    case Process.whereis(server) do
      nil ->
        :timer.sleep(200)
        async_get_chat_members(server)

      _ ->
        GenServer.call(server, {:async_get_all})
    end
  end

  def async_10_last_msgs(server) do
    case Process.whereis(server) do
      nil ->
        :timer.sleep(200)
        async_10_last_msgs(server)

      _ ->
        GenServer.call(server, {:async_get_10_last_msgs})
    end
  end

  ############################## handlers ##############################

  def handle_call({:ping}, _from, state) do
    WarshipsWeb.Endpoint.broadcast(state.room_name, "ping", "msg")

    {:reply, :pong, state}
  end

  def handle_call({:add, params}, _from, state) do
    new_chat_members = MapSet.put(state.chat_members, params.member)
    new_state = Map.replace(state, :chat_members, new_chat_members)

    WarshipsWeb.Endpoint.broadcast(
      "chat",
      "update_users",
      %{target: state.room_name, update: MapSet.to_list(new_chat_members)}
    )

    {:reply, new_state, new_state}
  end

  def handle_call({:remove, params}, _from, state) do
    new_chat_members = MapSet.delete(state.chat_members, params.member)
    new_state = Map.replace(state, :chat_members, new_chat_members)

    WarshipsWeb.Endpoint.broadcast(
      "chat",
      "update_users",
      %{target: state.room_name, update: MapSet.to_list(new_chat_members)}
    )

    {:reply, new_state, new_state}
  end

  def handle_call({:get_all}, _from, state) do
    {:reply, MapSet.to_list(state.chat_members), state}
  end

  def handle_call({:async_get_all}, _from, state) do
    {:reply, MapSet.to_list(state.chat_members), state}
  end

  def handle_call({:async_get_10_last_msgs}, _from, state) do
    {:reply, state.last_10_msgs, state}
  end

  def handle_call({:save_msg, params}, _from, state) do
    if length(state.last_10_msgs) < 10 do
      new_list = [params | state.last_10_msgs]

      new_state = Map.replace(state, :last_10_msgs, new_list)
      {:reply, new_list, new_state}
    else
      new_list = [params | List.delete_at(state.last_10_msgs, length(state.last_10_msgs) - 1)]
      new_state = Map.replace(state, :last_10_msgs, new_list)
      {:reply, new_list, new_state}
    end
  end

  def handle_call({:test}, _from, state) do
    {:reply, state.last_10_msgs, state}
  end
end
