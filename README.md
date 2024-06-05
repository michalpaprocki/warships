# Warships

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Possible improvements :

- Liveview assign for chat component (users list) is created/updated in channel file on user join and on terminate. Closing a browser tab while running more than 1, will lead to username deletion in socket assings.
