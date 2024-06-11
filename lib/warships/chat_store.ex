defmodule Warships.ChatStore do
  ## todo: rework to dynamic supervisor

  @moduledoc """
  A store respinsible for monitoring chat rooms and connected users.
  """
  use GenServer

  @doc """
  Starts a generic server process. Hardcoded to run only one "lobby" server.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, "lobby", name: String.to_atom("CS_" <> "lobby"))
  end

  def init(init_arg) do
    IO.puts("Creating  #{"CS_" <> init_arg}")
    chat_members = MapSet.new()

    {:ok, %{:room_name => init_arg, :chat_members => chat_members, :last_msgs => []}}
  end


  @doc """
  Adds a user to a chat store. Broadcasts a message for subscribers of "chat" topic.

  Returns: `:ok`

  ## Examples

      iex>Warships.ChatStore.add_chat_member(:server, "member_name")
      :ok
      iex>Warships.ChatStore.add_chat_member(:server, "non-existent_member_name")
      :ok
  """
  def add_chat_member(server, member) when is_atom(server) and is_binary(member) do
    GenServer.call(server, {:add, %{:member => member}})
  end
  def add_chat_member(_server, _member) do
    raise("Variables: `server` must be of type :atom, `member` must be of type string")
  end

  @doc """
  Removes a user from a chat store.

  Returns: `:ok`

  ## Examples

      iex>Warships.ChatStore.remove_chat_member(:server, "member_name")
      :ok
      iex>Warships.ChatStore.remove_chat_member(:server, "non-existent_member_name")
      :ok
  """
  def remove_chat_member(server, member) when is_atom(server) and is_binary(member) do
    GenServer.call(server, {:remove, %{:member => member}})
  end
  def remove_chat_member(_server, _member) do
    raise("Variables: `server` must be of type :atom, `member` must be of type string")
  end
  @doc """
  Retrieves all chat members of a chat store matching `server`.
  """
  def get_chat_members(server) when is_atom(server) do
    GenServer.call(server, {:get_all})
  end
  def get_chat_members(_server) do
    raise("Variable `server` must be of type :atom")
  end
  @doc """
  Saves a message from chat in a store matching `server`.

  Returns: `:ok`

    ## Examples

      iex>Warships.ChatStore.save_last_msg(:server, %{:user=>"user_name", :body=>"body of a message", sent_at: 1718100990558343847})
      :ok
      iex>Warships.ChatStore.save_last_msg(:server, %{:user=>"non_existent _user_name", :body=>"body of a message", sent_at: 1718100990558343847})
      :ok
  """
  def save_last_msg(server, msg = %{:user=>user, :body=> body, :sent_at=> sent_at}) when is_atom(server) and is_map(msg) and is_binary(user) and is_binary(body) and is_number(sent_at) do
    GenServer.call(server, {:save_msg, msg})
  end
  def save_last_msg(_server, _msg) do
    raise("Variables: `server` must be of type :atom, `msg` must be of type map:%{:user=>`string`, :body=>`string`, sent_at=>`number`}, where number is a timestamp: `:os.system_time()`")
  end

  @doc """
    Recursively retrieves chat members from a matching `server`
  """
  def async_get_chat_members(server) when is_atom(server) do
    case Process.whereis(server) do
      nil ->
        :timer.sleep(200)
        async_get_chat_members(server)

      _ ->
        GenServer.call(server, {:async_get_all})
    end
  end
  def async_get_chat_members(_server) do
    raise("Variable `server` must be of type :atom")
  end

  @doc """
    Recusively retrieves last saved chat messges from a mathing `server`
  """
  def async_get_last_msgs(server) when  is_atom(server) do
    case Process.whereis(server) do
      nil ->
        :timer.sleep(200)
        async_get_last_msgs(server)

      _ ->
        GenServer.call(server, {:async_get_last_msgs})
    end
  end
  def async_get_last_msgs(_server) do
    raise("Variable `server` must be of type :atom")
  end
  ############################## handlers ##############################


  def handle_call({:add, params}, _from, state) do

    new_chat_members = MapSet.put(state.chat_members, params.member)
    new_state = Map.replace(state, :chat_members, new_chat_members)

    WarshipsWeb.Endpoint.broadcast(
      "chat",
      "update_users",
      %{target: state.room_name, update: MapSet.to_list(new_chat_members)}
    )

    {:reply, :ok, new_state}
  end

  def handle_call({:remove, params}, _from, state) do
    new_chat_members = MapSet.delete(state.chat_members, params.member)
    new_state = Map.replace(state, :chat_members, new_chat_members)

    WarshipsWeb.Endpoint.broadcast(
      "chat",
      "update_users",
      %{target: state.room_name, update: MapSet.to_list(new_chat_members)}
    )

    {:reply, :ok, new_state}
  end

  def handle_call({:get_all}, _from, state) do
    {:reply, MapSet.to_list(state.chat_members), state}
  end

  def handle_call({:async_get_all}, _from, state) do
    {:reply, Enum.sort(MapSet.to_list(state.chat_members), :desc), state}
  end

  def handle_call({:async_get_last_msgs}, _from, state) do
    {:reply, state.last_msgs, state}
  end

  def handle_call({:save_msg, params}, _from, state) do
    if length(state.last_msgs) < 10 do
      new_list = [params | state.last_msgs]

      new_state = Map.replace(state, :last_msgs, new_list)
      {:reply, :ok, new_state}
    else
      new_list = [params | List.delete_at(state.last_msgs, length(state.last_msgs) - 1)]
      new_state = Map.replace(state, :last_msgs, new_list)
      {:reply, :ok, new_state}
    end
  end

  def handle_call({:test}, _from, state) do
    {:reply, state.last_msgs, state}
  end
end
