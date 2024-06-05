defmodule Warships.UserStore do
  @moduledoc """
  An ETS store for users
  """

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
    :ets.new(:users, [:protected, :named_table, :set])
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

  def get_name() do
    {:ok, @name}
  end

  @doc """
  # Retrieves all users.
  ## Exampes
    iex>get_all_users()
    {:ok, []}
  """
  def get_all_users() do
    GenServer.call(@name, {:all})
  end

  @doc """
   Inserts a user to ETS :users table.

   ## Example

    iex>insert_user("name","password")
  """
  def insert_user(name) do
    name_string = to_string(name)
    GenServer.call(@name, {:insert, %{:name => name_string}})
  end

  def get_user(name) do
    name_string = to_string(name)
    GenServer.call(@name, {:get, %{:name => name_string}})
  end

  def check() do
    GenServer.call(@name, {:check})
  end

  def delete_user(name) do
    name_string = to_string(name)
    GenServer.call(@name, {:delete, %{:name => name_string}})
  end

  def handle_call({:insert, params}, _from, state) do
    user = :ets.insert_new(:users, {params.name})

    case user do
      true ->
        {:reply, {:ok}, state}

      false ->
        {:reply, {:error, "Could not create user, name taken"}, state}
    end
  end

  def handle_call({:get, params}, _from, state) do
    user = :ets.match_object(:users, {params.name, :"$1"})

    case length(user) do
      0 -> {:reply, {:error, "User not found"}, state}
      _ -> {:reply, user, state}
    end
  end

  def handle_call({:all}, _from, state) do
    users = :ets.match(:users, {:"$1"})

    {:reply, users, state}
  end

  def handle_call({:delete_table, params}, _from, state) do
    :ets.delete(String.to_atom(params.name))

    {:reply, "Table #{params.name} deleted", state}
  end

  def handle_call({:delete, params}, _from, state) do
    :ets.delete(:users, params.name)

    {:reply, "User #{params.name} deleted", state}
  end

  def handle_call({:check}, _from, state) do
    {:reply, :ok, state}
  end
end
