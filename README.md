

# Warships

My spin on the Battleships game. 🚢

## Objectives

- build a web app that allows user to create and partake in a 2 player matches
- implement a simple real-time chat
- create a system that terminates empty game rooms due to inactivity
- gain basic familiarity with Elixir and some of it's modules

## Technologies

- Phoenix Framework ver 1.7
- TailwindCSS

## Running app locally

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


### Possible improvements :

- improve UI feedback
- develop a mechanism responsible for flash message clean up
- design a system that will prevent users from opening more than 1 tab; current app implementation removes the player from game and chat when closing one of concurrent app tabs
- add favicon

