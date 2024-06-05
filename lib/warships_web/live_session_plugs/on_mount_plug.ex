defmodule WarshipsWeb.LiveSessionPlugs.OnMountPlug do
  import Phoenix.LiveView.Utils
  alias WarshipsWeb.Auth.Auth

  def on_mount(:default, _params, session, socket) do
    nickname = session["nickname"]

    if(nickname != nil) do
      token = Auth.encrypt_token(socket, nickname)

      {:cont,
       socket
       |> assign_new(:joined_rooms, fn -> %{  :lobby => %{
             :chat_members => Warships.ChatStore.async_get_chat_members(:CS_lobby),
             :messages => []
             }} end)
       |> assign_new(:nickname, fn -> nickname end)
       |> assign_new(:user_token, fn -> token end)}
    else
      {:cont, socket}
    end
  end
end
