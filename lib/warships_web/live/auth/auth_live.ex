defmodule WarshipsWeb.Auth.AuthLive do

  alias Warships.ChatStore
  alias Warships.RoomStore
  alias RoomStore
  use WarshipsWeb, :live_view

  def mount(params, _session, socket) do
    room = RoomStore.get_room(params["room_name"])

    case room do
      {:error, _msg} ->
        {:ok, redirect(socket, to: ~p"/not_found")}

      _ ->
        {:ok,
         assign(socket, %{
           :room_name => params["room_name"],
           password_form: to_form(%{}, as: :password)
         })}
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
  def handle_event("save", %{"password" => params}, socket) do
    auth_state = RoomStore.verify_password(socket.assigns.room_name, params["password"])

    case auth_state do
      :not_authorized ->
        {:noreply, put_flash(socket, :error, "Wrong password")}

      :authorized ->
        hash = Bcrypt.hash_pwd_salt(params["password"])
        {:noreply, push_navigate(socket, to: ~p"/auth/#{socket.assigns.room_name}?pwd=#{hash}")}
    end
  end
end
