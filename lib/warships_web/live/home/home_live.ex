defmodule WarshipsWeb.Home.HomeLive do
  use WarshipsWeb, :live_view
  alias Warships.LiveMonitor
  alias Warships.RefStore
  alias Warships.GameStore
  alias Warships.RoomSupervisor
  alias Warships.ChatStore
  alias Ecto.Changeset
  alias Warships.RoomStore
  alias WarshipsWeb.Auth.Auth


  # handle challenge redirection



  def mount(_params, _session, socket) do
    user_token = socket.assigns[:user_token]

    WarshipsWeb.Endpoint.subscribe("chat")
    WarshipsWeb.Endpoint.subscribe("rooms")
    WarshipsWeb.Endpoint.subscribe("player_changes")
    case user_token do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/nickname")}

      _ ->
        rooms_data = get_rooms_data()


        {:ok, nickname} = Auth.decrypt_token(socket, user_token)

        last_msgs = ChatStore.async_get_last_msgs(:CS_lobby)
        lobby_map = Map.get(socket.assigns.joined_rooms, :lobby)
        new_lobby_ = Map.replace(lobby_map, :messages, last_msgs)
        new_joined_rooms = Map.replace(socket.assigns.joined_rooms, :lobby, new_lobby_)

        LiveMonitor.monitor(self(), __MODULE__, "home", socket.assigns.nickname)
        if Map.has_key?(socket.assigns.flash, "error") || Map.has_key?(socket.assigns.flash, "info") do
          clean_flash()


        end
        {:ok,
         socket
         |> assign(:joined_rooms, new_joined_rooms)
         |> assign(:rooms_data, rooms_data)
         |> assign(:sort, :asc)
         |> assign(:modal_state, false)
         |> assign(:require_password, false)
         |> assign(:user_token, user_token)
         |> assign(:nickname, nickname)
         |> assign(:page_title, "Home")
         |> assign(:show_full, true)
         |> assign(:show_protected, true)
         |> assign(:room_form, to_form(%{}, as: :room_form))}
    end
  end

  def handle_event("open_modal", _unsigned_params, socket) do
    {:noreply, assign(socket, :modal_state, true)}
  end

  def handle_event("close_modal", _unsigned_params, socket) do
    {:noreply, assign(socket, :modal_state, false)}
  end

  def handle_event("req_pwd", params, socket) do
    if params["value"] == "true" do
      {:noreply, assign(socket, :require_password, true)}
    else
      {:noreply, assign(socket, :require_password, false)}
    end
  end
  def handle_event("toggle_header_menu", _unsigned_params, socket) do
    {:noreply, socket|> assign(:header_menu, !socket.assigns.header_menu)}
  end
  def handle_event("close_header_menu", _unsigned_params, socket) do
    {:noreply, socket|> assign(:header_menu, false)}
  end
  def handle_event("logout", _unsigned_params, socket) do
    ChatStore.remove_chat_member(:CS_lobby, socket.assigns.nickname)
    {:noreply, socket |> assign(:nickname, nil) |>redirect(to: ~p"/logout")}
  end
  def handle_event("validate", %{"room_form" => params}, socket) do
    types = %{room_name: :string, room_password: :string}

    case params["with_password"] do
      "false" ->
        changeset =
          {%{}, types}
          |> Changeset.cast(params, Map.keys(types))
          |> Changeset.validate_required(:room_name)
          |> Changeset.validate_length(:room_name, min: 3)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, room_form: to_form(changeset, as: :room_form))}

      _ ->
        changeset =
          {%{}, types}
          |> Changeset.cast(params, Map.keys(types))
          |> Changeset.validate_required([:room_name, :room_password])
          |> Changeset.validate_length(:room_name, min: 3)
          |> Changeset.validate_length(:room_password, min: 4)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, room_form: to_form(changeset, as: :room_form))}
    end
  end

  def handle_event("save", %{"room_form" => params}, socket) do
    if String.length(params["room_name"]) < 3 do
      clean_flash()
      {:noreply, put_flash(socket, :error, "Name too short.")}
    else
      resp = RoomStore.insert_room(params["room_name"], params["room_password"])

      case resp do
        :ok ->
          {:noreply, push_navigate(socket, to: ~p"/rooms/#{params["room_name"]}")}

        {:error, msg} ->
          clean_flash()
          {:noreply, put_flash(socket, :error, msg)}
      end
    end
  end
  def handle_event("toggle_show_full", _unsigned_params, socket) do
    {:noreply, socket |> assign(:show_full, !socket.assigns.show_full)}
  end
  def handle_event("toggle_show_protected", _unsigned_params, socket) do
    {:noreply, socket |> assign(:show_protected, !socket.assigns.show_protected)}
  end

  def handle_event("sort", %{"sort"=> order, "value" => ""}, socket) do
    {:noreply, socket |> assign(:sort, String.to_atom(order))|> assign(:rooms_data, Enum.sort(socket.assigns.rooms_data, String.to_atom(order)))}
  end

  def handle_event("click_event", _, socket) do
    users = ChatStore.get_chat_members(:CS_lobby)
    {:noreply, socket |> assign(:users, users)}
  end


  def handle_info(:clear_flash, socket) do
    RefStore.delete_ref(self())
  {:noreply, socket |> clear_flash()}
  end

  def handle_info(msg, socket) do
    case msg.event do
      "update_users" ->

        target_map_ = Map.get(socket.assigns.joined_rooms, String.to_atom(msg.payload.target))

        new_users_ =
          Map.put(
            target_map_,
            :chat_members,
            ChatStore.async_get_chat_members(String.to_atom("CS_" <> msg.payload.target))
          )

        new_joined_rooms =
          Map.replace(socket.assigns.joined_rooms, String.to_atom(msg.payload.target), new_users_)

        {:noreply, socket |> assign(:joined_rooms, new_joined_rooms)}

      "new_msg" ->
        target_map_ = Map.get(socket.assigns.joined_rooms, String.to_atom(msg.payload.target))

        new_msg = %{
          :user => msg.payload.user,
          :body => msg.payload.body,
          :sent_at => msg.payload.sent_at
        }

        messages = [new_msg | target_map_.messages]
        new_map_ = Map.put(target_map_, :messages, messages)

        new_joined_rooms =
          Map.replace(socket.assigns.joined_rooms, String.to_atom(msg.payload.target), new_map_)
          ChatStore.save_last_msg(:CS_lobby, new_msg)
        {:noreply, socket |> assign(:joined_rooms, new_joined_rooms)}

      "room_created" ->

        rooms_data = get_rooms_data()
        {:noreply, socket |> assign(:rooms_data, rooms_data)}

      "room_deleted" ->
        rooms_data = get_rooms_data()
        {:noreply, socket |> assign(:rooms_data, rooms_data)}

      "player_added" ->

        rooms_data = socket.assigns.rooms_data
        target_room = Enum.filter(rooms_data, fn x ->x.room == msg.payload.room  end)
        case target_room do
          [] ->
            {:noreply, socket}
          _->

            target_room_u = Enum.at(target_room, 0) |> Map.replace(:players, msg.payload.player_count) |> Map.replace(:has_cpu?, GameStore.has_player_cpu?(msg.payload.room))

            rooms_data_u = Enum.map(rooms_data, fn x -> if x.room != msg.payload.room, do: x, else: target_room_u end)

            {:noreply, socket |> assign(:rooms_data, rooms_data_u)}
        end

        "player_removed" ->
          rooms_data = socket.assigns.rooms_data
          target_room = Enum.filter(rooms_data, fn x ->x.room == msg.payload.room  end)
          case target_room do
            [] ->
              {:noreply, socket}
            _->
              target_room_u = Enum.at(target_room, 0) |> Map.replace(:players, msg.payload.player_count) |> Map.replace(:has_cpu?, GameStore.has_player_cpu?(msg.payload.room))
            rooms_data_u = Enum.map(rooms_data, fn x -> if x.room != msg.payload.room, do: x, else: target_room_u end)

            {:noreply, socket |> assign(:rooms_data, rooms_data_u)}
          end
          "redirect_after_challenge_accepted" ->
            {room_name, player} = msg.payload


            if player == socket.assigns.nickname do
              {:noreply, socket|> put_flash(:info, "Challenge accepted") |> push_navigate(to: ~p"/rooms/#{room_name}")}

            else
              {:noreply, socket}
            end

        _ ->

          {:noreply, socket}
    end
  end

  defp get_rooms_data() do
    running_rooms_ = RoomSupervisor.get_running_games()

    rooms = Enum.map(Enum.filter(running_rooms_, fn x-> hd(elem(x, 3)) == Warships.GameStore end), fn y -> elem(y, 0) end )
    Enum.sort(Enum.map(rooms, fn x -> %{:room=> extract_name(x), :players => GameStore.get_player_count(extract_name(x)), :protected? => RoomStore.room_protected?(extract_name(x)), :has_cpu? => GameStore.has_player_cpu?(extract_name(x))} end))

  end
  defp extract_name(name) do
    String.slice(elem(elem(name,2),1), 22, String.length(elem(elem(name,2),1))-1)
  end
  defp clean_flash() do
    retrieved_ref = RefStore.get_ref(self())
    case length(retrieved_ref) do
      0->
        ref = Process.send_after(self(), :clear_flash, 5000)
        RefStore.add_ref(self(), ref)

      _->
        RefStore.delete_ref(self())
        Process.cancel_timer(hd(hd(retrieved_ref)))
        ref = Process.send_after(self(), :clear_flash, 5000)
        RefStore.add_ref(self(), ref)
    end
  end
end
