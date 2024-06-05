defmodule WarshipsWeb.Presence do
  use Phoenix.Presence,
    otp_app: :warships,
    pubsub_server: Warships.PubSub
end
