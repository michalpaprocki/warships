defmodule WarshipsWeb.Auth.Auth do
  def encrypt_token(socket, data) do
    token = Phoenix.Token.encrypt(socket, "some_secret_string", data)
    {:ok, token}
    token
  end

  def decrypt_token(socket, token) do
    data = Phoenix.Token.decrypt(socket, "some_secret_string", token)
    {:ok, data}
    data
  end
end
