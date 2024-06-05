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


          WarshipsWeb.Endpoint.broadcast("room:lobby", "new_msg", msg)

          {:noreply, socket|> assign(:msg, "") }
    end

  end

  def handle_event("check_msg", %{"_target" => ["msg"], "msg" => msg}, socket) do

    {:noreply, socket |> assign(:msg, msg)}
  end

end
