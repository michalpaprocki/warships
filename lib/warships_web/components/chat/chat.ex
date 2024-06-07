defmodule WarshipsWeb.Chat.Chat do
  use Phoenix.LiveComponent

  def update(assigns, socket) do

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rooms, [:lobby])
     |> assign_new(:chat_open, fn -> false end)
     |> assign(:selected_room, :lobby)
    }
  end

  def handle_event("open_chat_window", _params, socket) do
    {:noreply, assign(socket, :chat_open, true)}
  end

  def handle_event("close_chat_window", _params, socket) do
    {:noreply, assign(socket, :chat_open, false)}
  end

  def handle_event("activate_", %{"room" => var}, socket) do
    {:noreply, socket |> assign(:selected_room, String.to_atom(var))}
  end
end
