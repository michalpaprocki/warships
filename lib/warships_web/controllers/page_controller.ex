defmodule WarshipsWeb.PageController do
  use WarshipsWeb, :controller

  def home(conn, _params) do
    conn
    |> get_nickname()
    |> render(:home)
  end

  def grab_name(conn, params) do
    nickname = params["nickname"]

    conn
    |> put_session(:nickname, nickname)
    |> redirect(to: ~p"/")
  end

  def auth_room_access(conn, _params) do
    conn
    |> get_nickname()
    |> set_authed_room()
    |> redirect(to: ~p"/rooms/#{conn.params["room_name"]}")
  end

  defp get_nickname(conn) do
    case get_session(conn, :nickname) do
      nil ->
        redirect(conn, to: ~p"/nickname")

      nickname ->
        conn
        |> assign(:nickname, nickname)
    end
  end

  defp set_authed_room(conn) do
    map = %{conn.params["room_name"] => conn.query_params["pwd"]}
    put_session(conn, :authed_rooms, map)
  end
end
