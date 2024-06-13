defmodule WarshipsWeb.Rooms.RoomsLive do
  alias Warships.RefStore
  alias Warships.LiveMonitor
  alias WarshipsWeb.Game.PrepBoard.PrepBoard
  alias Warships.GameStore
  alias Warships.ChatStore
  alias Warships.RoomStore
  use WarshipsWeb, :live_view

  def mount(params, session, socket) do

    if !Enum.member?(Enum.map(Map.to_list(session), fn x -> elem(x,0) end ), "nickname") do

      {:ok, socket |> push_navigate(to: ~p"/")}

    else


    room = RoomStore.get_room(params["room_name"])

    WarshipsWeb.Endpoint.subscribe("chat")
    WarshipsWeb.Endpoint.subscribe("game")
    case room do
      {:error, _msg} ->
        {:ok, socket |> push_navigate(to: ~p"/not_found")}

        room ->

          cond do
          check_if_room_authed(session["authed_rooms"], room) ->

            resp = GameStore.add_player(extract_room_name(room), socket.assigns.nickname)

              case resp do
                {:error, :room_is_full} ->

                  {:ok, socket|> put_flash(:error, "Room is full.")|> push_navigate(to: ~p"/")}

                {:rejoin} ->


                  LiveMonitor.monitor(self(), __MODULE__, extract_room_name(room), socket.assigns.nickname)
                  last_msgs = ChatStore.async_get_last_msgs(:CS_lobby)
                  lobby_map = Map.get(socket.assigns.joined_rooms, :lobby)
                  new_lobby_ = Map.replace(lobby_map, :messages, last_msgs)
                  new_joined_rooms = Map.replace(socket.assigns.joined_rooms, :lobby, new_lobby_)
                  game = GameStore.get_store(extract_room_name(room))

                  {:ok,
                  socket
                  |> assign(%{
                    :room_name => extract_room_name(room),
                    :page_title => extract_room_name(room),
                    :nickname => socket.assigns.nickname,
                    :joined_rooms => new_joined_rooms,
                    :game => game
                  })}
                _ ->
                  LiveMonitor.monitor(self(), __MODULE__, extract_room_name(room), socket.assigns.nickname)
                  last_msgs = ChatStore.async_get_last_msgs(:CS_lobby)
                  lobby_map = Map.get(socket.assigns.joined_rooms, :lobby)
                  new_lobby_ = Map.replace(lobby_map, :messages, last_msgs)
                  new_joined_rooms = Map.replace(socket.assigns.joined_rooms, :lobby, new_lobby_)
                  game = GameStore.get_store(extract_room_name(room))

                  {:ok,
                  socket
                  |> assign(%{
                    :room_name => extract_room_name(room),
                    :nickname => socket.assigns.nickname,
                    :joined_rooms => new_joined_rooms,
                    :game => game
                  })}
              end

          check_if_room_protected(room) ->

            {:ok, push_navigate(socket, to: ~p"/auth/rooms/#{extract_room_name(room)}")}

          true ->
            resp = GameStore.add_player(extract_room_name(room), socket.assigns.nickname)

            case resp do
              {:error, :room_is_full} ->

                {:ok, socket|> put_flash(:error, "Room is full.")|> push_navigate(to: ~p"/")}

              {:rejoin} ->

                LiveMonitor.monitor(self(), __MODULE__, extract_room_name(room), socket.assigns.nickname)
                last_msgs = ChatStore.async_get_last_msgs(:CS_lobby)
                lobby_map = Map.get(socket.assigns.joined_rooms, :lobby)
                new_lobby_ = Map.replace(lobby_map, :messages, last_msgs)
                new_joined_rooms = Map.replace(socket.assigns.joined_rooms, :lobby, new_lobby_)
                game = GameStore.get_store(extract_room_name(room))

                {:ok,
                socket
                |> assign(%{
                  :room_name => extract_room_name(room),
                  :page_title => extract_room_name(room),
                  :nickname => socket.assigns.nickname,
                  :joined_rooms => new_joined_rooms,
                  :game => game
                })}
              _ ->
                LiveMonitor.monitor(self(), __MODULE__, extract_room_name(room), socket.assigns.nickname)
                last_msgs = ChatStore.async_get_last_msgs(:CS_lobby)
                lobby_map = Map.get(socket.assigns.joined_rooms, :lobby)
                new_lobby_ = Map.replace(lobby_map, :messages, last_msgs)
                new_joined_rooms = Map.replace(socket.assigns.joined_rooms, :lobby, new_lobby_)
                game = GameStore.get_store(extract_room_name(room))

                {:ok,
                 socket
                 |> assign(%{
                   :room_name => extract_room_name(room),
                   :page_title => extract_room_name(room),
                   :nickname => socket.assigns.nickname,
                   :joined_rooms => new_joined_rooms,
                   :game => game
                 })}
            end
          end
        end
      end
      end

  def handle_event("request_another", _unsigned_params, socket) do

    Warships.GameStore.request_another(socket.assigns.game.game, socket.assigns.nickname)
    {:noreply, socket}
  end
  def handle_event("leave", _unsigned_params, socket) do

    Warships.GameStore.remove_player(socket.assigns.game.game, socket.assigns.nickname)
    {:noreply, socket |> push_navigate(to: ~p"/")}
  end
  def handle_event("accept_rematch", _unsigned_params, socket) do


    Warships.GameStore.accept_rematch(socket.assigns.game.game)



    {:noreply, socket }
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
  def handle_info({:update_flash, {flash_type, msg}}, socket) do

      retrived_ref = RefStore.get_ref(self())
      case length(retrived_ref) do
        0->
          ref = Process.send_after(self(), :clear_flash, 5000)
          RefStore.add_ref(self(), ref)
          {:noreply, socket |> put_flash(flash_type, msg)}

        _->
          RefStore.delete_ref(self())
          Process.cancel_timer(hd(hd(retrived_ref)))
          ref = Process.send_after(self(), :clear_flash, 5000)
          RefStore.add_ref(self(), ref)
          {:noreply, socket |> put_flash(flash_type, msg)}
      end
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


      "game_state_update" ->

        {:noreply, socket |> assign(:game, msg.payload)}

      "ship_added" ->
        if msg.payload.player == socket.assigns.nickname do

              send_update(PrepBoard, id: "prep_board", update: msg.payload.state)
          {:noreply, socket}
        else
          {:noreply, socket}
        end

        "ship_removed" ->
          if msg.payload.player == socket.assigns.nickname do

                send_update(PrepBoard, id: "prep_board", update: msg.payload.state)
            {:noreply, socket}
          else
            {:noreply, socket}
          end

      _ ->

        {:noreply, socket}
    end
  end





  ############## priv ##############
  defp extract_room_name(room_tuple),
    do: elem(room_tuple, 0)

  defp extract_room_password(room_tuple),
    do: elem(room_tuple, 1)

  defp check_if_room_authed(nil, _room), do: false

  defp check_if_room_authed(authed_rooms, room) do
    if Map.has_key?(authed_rooms, extract_room_name(room)) do
      hashed_password = Map.get(authed_rooms, extract_room_name(room))

      Bcrypt.verify_pass(extract_room_password(room), hashed_password)
    end
  end

  defp check_if_room_protected(room_tuple) do
    if String.length(elem(room_tuple, 1)) > 0 do
      true
    else
      false
    end
  end
end
