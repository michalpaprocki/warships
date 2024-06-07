defmodule WarshipsWeb.Chat.ChatRoom.ChatRoom do
  use Phoenix.LiveComponent

  def update(assigns, socket) do

    {:ok, socket |> assign(assigns) |> assign(:msg, "")}
  end
  def handle_event("send", %{"msg" => msg}, socket) do

    case String.length(msg) do
      0->
        {:noreply, socket}
        _->

          WarshipsWeb.Endpoint.broadcast("chat", "new_msg", %{
            target: "lobby",
            user: socket.assigns.nickname,
            body: msg,
            sent_at: :os.system_time()
          })

          {:noreply, socket|> assign(:msg, "") }
    end

  end

  def handle_event("check_msg", %{"_target" => ["msg"], "msg" => msg}, socket) do

    {:noreply, socket |> assign(:msg, msg)}
  end

end
