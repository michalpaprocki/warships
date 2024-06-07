defmodule Warships.RoomStore do
  @moduledoc """
  An ETS store for rooms
  """
alias Warships.GameStore

  use GenServer

  @name __MODULE__

  @doc """
  Starts the generic server process.
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def init(_) do
    IO.puts("Creating ETS #{@name}")
    :ets.new(:rooms, [:protected, :named_table, :set])
    {:ok, "ETS created"}
  end

  def delete_table(name) do
    case is_atom(name) do
      true ->
        resp = GenServer.call(@name, {:delete_table, %{:name => name}})
        {:ok, resp}

      false ->
        raise("Variable name have to be of type :atom")
    end
  end

  def get_room(name) do
    GenServer.call(@name, {:get, %{:name=> name}})
  end
  def get_name() do
    {:ok, @name}
  end
  @doc """
  # Retrieves all rooms.
  ## Exampes
    iex>get_all_rooms()
    {:ok, []}
  """
  def get_all_rooms() do
    GenServer.call(@name, {:all})
  end

  @doc """
   Inserts a room to ETS :rooms table.

   ## Example

    iex>insert_room("name","password")
  """
  def insert_room(name) do
    name_string = to_string(name)
    GenServer.call(@name, {:insert, %{:name => name_string}})
  end

  def insert_room(name, password) do
    GenServer.call(
      @name,
      {:insert, %{:name => to_string(name), :password => to_string(password)}}
    )
  end



  def check() do
    GenServer.call(@name, {:check})
  end

  def delete_room(name) do
    name_string = to_string(name)
    GenServer.call(@name, {:delete, %{:name => name_string}})
  end

  def verify_password(name, password) do
    name_string = to_string(name)
    password_string = to_string(password)

    GenServer.call(
      @name,
      {:verify_password, %{:name => name_string, :password => password_string}}
    )
  end

  ##################### handlers #####################
  def handle_call({:insert, params}, _from, state) do
    room = :ets.insert_new(:rooms, {params.name, params.password})

    case room do
      true ->
        resp = Warships.GameStore.start_link(params.name)

        WarshipsWeb.Endpoint.broadcast("rooms", "room_created", %{:room => params.name})
        {:reply, {:ok}, state}

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

  def handle_call({:all}, _from, state) do
    rooms = :ets.match(:rooms, {:"$1", :_})

    {:reply, List.flatten(rooms), state}
  end

  def handle_call({:delete_table, params}, _from, state) do
    :ets.delete(String.to_atom(params.name))
    GameStore.stop_link(params.name)
    {:reply, "Table #{params.name} deleted", state}
  end

  def handle_call({:delete, params}, _from, state) do
    :ets.delete(:rooms, params.name)

    WarshipsWeb.Endpoint.broadcast("rooms", "room_deleted", %{:room => params.name})
    {:reply, "Room #{params.name} deleted", state}
  end

  def handle_call({:check}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:verify_password, params}, _from, state) do
    room = :ets.match_object(:rooms, {params.name, params.password})

    case length(room) do
      0 -> {:reply, :not_authorized, state}
      _ -> {:reply, :authorized, state}
    end
  end
end
