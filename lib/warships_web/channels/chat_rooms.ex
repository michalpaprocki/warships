defmodule WarshipsWeb.ChatRooms do
  use Phoenix.Channel

  alias Warships.ChatStore

  def join("room:lobby", _payload, socket) do

    send(self(), :after_join)

    {:ok, socket}
  end

  def join("room:" <> _priv_room_id, _payload, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
    ChatStore.add_chat_member(:CS_lobby, socket.assigns.user)
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    now = :os.system_time()
    IO.inspect(body)
    ChatStore.save_last_msg(:CS_lobby, %{
      user: socket.assigns.user,
      body: body,
      sent_at: now
    })

    WarshipsWeb.Endpoint.broadcast("chat", "new_msg", %{
      target: "lobby",
      user: socket.assigns.user,
      body: body,
      sent_at: now
    })

    {:noreply, socket}
  end


  def terminate(reason, arg1) do
    case reason do
      {:shutdown,:left} ->
       nil
        _->
          ChatStore.remove_chat_member(:CS_lobby, arg1.assigns.user)
    end
  end
end

# # ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ # #
# #                                                                                     # #
# #  fixed:When joining and then leaving from another tab socket assigns are removed    # #
# #                                                                                     # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
