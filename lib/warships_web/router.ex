defmodule WarshipsWeb.Router do
  use WarshipsWeb, :router
  alias NotFound.NotFoundLive
  alias Home.HomeLive
  alias Nickname.NicknameLive
  alias Rooms.RoomsLive
  alias Auth.AuthLive
  import Phoenix.LiveView.Router
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WarshipsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WarshipsWeb do
    pipe_through :browser

    live_session :default, on_mount: WarshipsWeb.LiveSessionPlugs.OnMountPlug do
      live "/", HomeLive
      live "/nickname", NicknameLive

      live "/rooms/:room_name", RoomsLive
      live "/auth/rooms/:room_name", AuthLive
      live "/not_found", NotFoundLive
    end

    get "/nickname/:nickname", PageController, :grab_name
    get "/auth/:room_name", PageController, :auth_room_access
  end

  # Other scopes may use custom stacks.
  # scope "/api", WarshipsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:warships, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WarshipsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
