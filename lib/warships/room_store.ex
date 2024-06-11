defmodule Warships.RoomStore do
  @moduledoc """
  An :ets store for rooms
  """
alias Warships.RoomSupervisor
  use GenServer
  @name __MODULE__

  @doc """
  Starts a generic server process that keeps track of game rooms using :ets.

    ## Examples

      iex>Warships.RoomStore.start_link()

  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def init(_) do
    IO.puts("Creating ETS #{@name}")
    :ets.new(:rooms, [:protected, :named_table, :set])
    {:ok, "ETS created"}
  end

@doc """
  Looks for a room by the `name` provided

  Returns: `{"name","password"}`

  ## Examples

      iex>Warships.RoomStore.get_room("test")
      {"test", ""}

      iex>Warships.RoomStore.get_room(:test)
      "Variable name have to be of type string"
"""
  def get_room(name) when is_binary(name) do
    GenServer.call(@name, {:get, %{:name=> name}})
  end
  def get_room(_name) do
    raise("Variable `name` has to be of type string")
  end

  @doc """
    Retrieves names of the stored rooms.

    Returns: `["name1", "name2"]'`

    ## Examples

      iex>get_all_rooms()
      []
      iex>get_all_rooms()
      ["test", "game"]

  """
  def get_all_rooms() do
    GenServer.call(@name, {:all})
  end
  @doc """
    Checks whether room is protected by a password.

    Returns: `boolean` || {:error, "Room not found"}

    ## Example
      Warships.RoomStore.room_protected?("test_room")
      false
  """
  def room_protected?(name) when is_binary(name) do
    GenServer.call(@name, {:protected, %{:name=> name}})
  end
  def room_protected?(_name) do
    raise("Variable `name` has to be of type string")
  end
  @doc """
  Inserts a room to the :rooms table. Spawns `Warships.GameStore` and `Warships.ShipStore` processes via `Warships.RoomSupervisor`, and broadcasts a message to processes subscribed to "rooms" topic.

  Returns: `:ok` || `{:error, "Could not create room, name taken"}`

  ## Examples

      iex>insert_room("name", "password")
      :ok
      iex>insert_room("existing_name", "")
      {:error, "Could not create room, name taken"}
  """
  def insert_room(name, password) when is_binary(name) and is_binary(password) or is_binary(name) and is_nil(password) do
    GenServer.call(
      @name,
      {:insert, %{:name => to_string(name), :password => to_string(password)}}
    )
  end

  def insert_room(_name, _password) do
    raise("Variables `name` and `password` have to be of type string")
  end

  @doc """
  Removes a room matching `"name"` from :rooms table. Terminates and deletes `Warships.RoomSupervisor`'s children spawned by `Warships.RoomStore.insert_room/2`, broadcasts a message to processes subscribed to "rooms" topic.

  Returns: "Room "name" deleted"

    ## Example
      iex>Warships.RoomStore.delete_room("room_name")
      "Room room_name deleted"

      iex>Warships.RoomStore.delete_room("non_existent_room_name")
      "Room non_existent_room_name deleted"
  """
  def delete_room(name) when is_binary(name) do
    GenServer.call(@name, {:delete, %{:name => name}})
  end
  def delete_room(_name) do
    raise("Variable `name` has to be of type string.")
  end
  @doc """
  Checks whether provided `name` and `password` match.

  Returns: `:not_authorized` || `:authorized`

    ## Examples
      iex>Warships.RoomStore.verify_password("name", "password")
      :authorized

      iex>Warships.RoomStore.verify_password("name", "bad_password")
      :not_authorized
  """
  def verify_password(name, password) when is_binary(name) and is_binary(password) do
    GenServer.call(
      @name,
      {:verify_password, %{:name => name, :password => password}}
    )
  end
  def verify_password(_name, _password)  do
    raise("Variables `name` and `password` have to be of type string")
  end
  ##################### handlers #####################
  def handle_call({:insert, params}, _from, state) do
    room = :ets.insert_new(:rooms, {params.name, params.password})

    case room do
      true ->
        RoomSupervisor.start_child(String.to_atom("GS_"<>params.name), Warships.GameStore, :start_link, [params.name])
        RoomSupervisor.start_child(String.to_atom("SS_"<>params.name), Warships.ShipStore, :start_link, [params.name])
        WarshipsWeb.Endpoint.broadcast("rooms", "room_created", %{:room => params.name})
        {:reply, :ok, state}

      false ->
        {:reply, {:error, "Could not create room, name taken"}, state}
    end
  end

  def handle_call({:get, params}, _from, state) do
    room = :ets.match_object(:rooms, {params.name, :"$1"})

    case length(room) do
      0 -> {:reply, {:error, "Room not found"}, state}
      _ -> {:reply, List.first(room), state}
    end
  end
  def handle_call({:protected, params}, _from, state) do
    room = :ets.match_object(:rooms, {params.name, :"$1"})

    case length(room) do
      0 -> {:reply, {:error, "Room not found"}, state}
      _ ->
        cond do
          String.length(elem(List.first(room),1 )) == 0 ->
            {:reply, false, state}
          true ->
            {:reply, true, state}

        end

    end
  end

  def handle_call({:all}, _from, state) do
    rooms = :ets.match(:rooms, {:"$1", :_})

    {:reply, List.flatten(rooms), state}
  end

  def handle_call({:delete, params}, _from, state) do
    :ets.delete(:rooms, params.name)
    RoomSupervisor.delete_child("SS_"<>params.name)
    RoomSupervisor.delete_child("GS_"<>params.name)
    WarshipsWeb.Endpoint.broadcast("rooms", "room_deleted", %{:room => params.name})
    {:reply, "Room #{params.name} deleted", state}
  end


  def handle_call({:verify_password, params}, _from, state) do
    room = :ets.match_object(:rooms, {params.name, params.password})
    case length(room) do
      0 -> {:reply, :not_authorized, state}
      _ -> {:reply, :authorized, state}
    end
  end
end
