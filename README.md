

# Warships

Batteships game for 2 players. 🚢

## Objectives

- build a web app that allows user to create and partake in a 2 player matches
- implement a simple real-time chat
- create a system that terminates empty game rooms due to inactivity
- gain basic familiarity with Elixir and some of it's modules

## Technologies

- Phoenix Framework 1.7
- TailwindCSS 

## Running app locally

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


## Possible improvements :

- [X] ~~*simple state machine that allows to play against a "CPU player"*~~
    - [X] ~~*randomized ship placement*~~
    - [X] ~~*simple state machine that tracks coords*~~
    - [ ] perfect the code that generates the coords for next move
- [ ] system that allows players to challange those currently playing against a "CPU player
    - [X] ~~*implement a mechanic, that will allow to challenge players in matches against "CPU player"*~~
    - [ ] give players a possibility to opt out of a challenge mechanic or/and ignore other player's requests
- [ ] improve UI feedback
    - [X] ~~*when placing ships, draw ship's class and position on hover*~~
    - [ ] reduce ships that can be drawn by those already placed
    - [ ] change "miss", "hit" and "sunk" responses after shooting to something more aesthetic
    - [ ] [optional] display opponent's mouse cursor on player's boards, when it's opponent's turn
- [X] ~~*develop a mechanism responsible for flash message clean up*~~
- [ ] design a system that will prevent users from opening more than 1 tab; current app implementation removes the player from game and chat when closing one of concurrent app tabs
- [X] ~~*add a favicon*~~ 

