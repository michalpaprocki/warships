defmodule WarshipsWeb.Nickname.NicknameLive do
  alias Warships.ChatStore
  use WarshipsWeb, :live_view

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
      |> Ecto.Changeset.validate_length(:nickname, min: 5)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :nickname))}
  end

  def handle_event("save", %{"nickname" => params}, socket) do

    nickname = Map.get(params, "nickname")

    if String.length(nickname) < 3 do
     {:noreply, put_flash(socket, :error, "Nickname too short.")}

    else

          members_online = ChatStore.get_chat_members(:CS_lobby)
          if Enum.member?(members_online, nickname) do

            {:noreply, put_flash(socket, :error, "Nickname taken.")}
          else
            {:noreply, redirect(socket, to: ~p"/nickname/#{nickname}")}
          end


    end
  end
end
