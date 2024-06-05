defmodule WarshipsWeb.NotFound.NotFoundLive do
  use WarshipsWeb, :live_view

  def mount(_params, _session, socket) do
    WarshipsWeb.Endpoint.subscribe("chat")
    {:ok, socket, layout: false}
  end

  def handle_event("go_home", _unsigned_params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end
end
