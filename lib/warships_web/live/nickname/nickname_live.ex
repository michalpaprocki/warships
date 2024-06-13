defmodule WarshipsWeb.Nickname.NicknameLive do
  use WarshipsWeb, :live_view
  alias Warships.ChatStore
  alias Warships.RefStore

  def mount(_params, session, socket) do


    if session["nickname"] == nil do
      {:ok, assign(socket, form: to_form(%{}, as: :nickname)), layout: false}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  def handle_event("validate", %{"nickname" => params}, socket) do
    types = %{nickname: :string}

    changeset =
      {%{}, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))
      |> Ecto.Changeset.validate_required(:nickname)
      |> Ecto.Changeset.validate_length(:nickname, min: 3)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :nickname))}
  end

  def handle_event("save", %{"nickname" => params}, socket) do

    nickname = Map.get(params, "nickname")

    if String.length(nickname) < 3 do
      clean_flash()
     {:noreply, put_flash(socket, :error, "Nickname too short.")}

    else
      members_online = ChatStore.get_chat_members(:CS_lobby)
      if Enum.member?(members_online, nickname) do

        clean_flash()
        {:noreply, put_flash(socket, :error, "Nickname taken.")}
      else
        {:noreply, redirect(socket, to: ~p"/nickname/#{nickname}")}
      end


    end
  end


def handle_info(:clear_flash, socket) do
    RefStore.delete_ref(self())
  {:noreply, socket |> clear_flash()}
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
