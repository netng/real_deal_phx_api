defmodule RealDealApiWeb.Router do
  alias RealDealApiWeb.Auth.ErrorResponse
  alias Plug.Parsers.ParseError
  alias Phoenix.Logger
  use RealDealApiWeb, :router
  use Plug.ErrorHandler

  defp handle_errors(conn, %{reason: %Phoenix.Router.NoRouteError{message: message}}) do
    conn
      |> json(%{errors: message})
      |> halt()
  end

  defp handle_errors(conn, _) do
    conn
    |> json(%{errors: "Bad request or non matching json format."})
    |> halt()
  end

  defp handle_errors(conn, %{reason: %{message: message}}) do
    IO.inspect("ERROR JSON PARSER")
    conn
      |> json(%{errors: message})
      |> halt()
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :auth do
    plug :introspect
    plug RealDealApiWeb.Auth.Pipeline
    plug RealDealApiWeb.Auth.SetAccount
  end

  defp introspect(conn, _opts) do
    IO.puts """
      Verb: #{inspect(conn.method)}
      Host: #{inspect(conn.host)}
      Headers: #{inspect(conn.req_headers)}
    """
    conn
  end

  # Unprotected endpoint
  scope "/api", RealDealApiWeb do
    pipe_through :api

    get "/", DefaultController, :index
    post "/accounts/create", AccountController, :create
    post "/accounts/sign-in", AccountController, :sign_in
  end

  # Protected endpoint
  scope "/api", RealDealApiWeb do
    pipe_through [:api, :auth]

    get "/accounts/by_id/:id", AccountController, :show
    get "/accounts", AccountController, :index
    post "/accounts/update", AccountController, :update
    delete "/accounts", AccountController, :delete
    post "/accounts/sign-out", AccountController, :sign_out
    get "/accounts/refresh-session", AccountController, :refresh_session
    put "/users/update", UserController, :update
  end
end
