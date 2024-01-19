defmodule RealDealApiWeb.AccountController do
  use RealDealApiWeb, :controller
  import RealDealApiWeb.Auth.AuthorizedPlug

  require Logger
  alias RealDealApiWeb.Auth.{Guardian, ErrorResponse}
  alias RealDealApi.{Accounts, Accounts.Account, Users, Users.User}

  plug :is_authorized when action in [:update, :delete]

  action_fallback RealDealApiWeb.FallbackController


  def index(conn, _params) do
    IO.inspect(System.get_env("DB_SEARCH_PATH"), label: "DB_SEARCH_PATH")
    accounts = Accounts.list_accounts()
    render(conn, :index, accounts: accounts)
  end

  def create(conn, %{"account" => account_params}) do
    with {:ok, %Account{} = account} <- Accounts.create_account(account_params),
          {:ok, %User{} = _user} <- Users.create_user(account, account_params) do
          authorize_account(conn, account.email, account_params["hash_password"])
    end
  end

  def sign_in(conn, %{"email" => email, "hash_password" => hash_password}) do
    authorize_account(conn, email, hash_password)
  end

  defp authorize_account(conn, email, hash_password) do
    with  {:ok, %Account{} = account, token} <- Guardian.authenticate(email, hash_password) do
      System.put_env("DB_SEARCH_PATH", account.id)
      conn
      |> Plug.Conn.put_session(:account_id, account.id)
      |> put_status(:ok)
      |> render(:account_token, %{account: account, token: token})
    else
      {:error, :unauthorized} ->
        raise ErrorResponse.Unauthorized, message: "Email or Password incorrect."
    end
  end

  def refresh_session(conn, %{}) do
    old_token = Guardian.Plug.current_token(conn)
    with {:ok, account, new_token} <- Guardian.authenticate(old_token) do
      conn
      |> put_session(:account_id, account.id)
      |> put_status(:ok)
      |> render(:account_token, %{account: account, token: new_token})
    else
      {:error, _reason} ->
        raise ErrorResponse.NotFound
    end
  end

  def sign_out(conn, %{}) do
    account = conn.assigns[:account]

    # get the current token and revoke from db
    token = Guardian.Plug.current_token(conn)
    Guardian.revoke(token)

    conn
    |> Plug.Conn.clear_session()
    |> put_status(:ok)
    |> render(:account_token, %{account: account, token: nil})
  end

  def show(conn, %{"id" => id}) do
    account = Accounts.get_full_account(id)
    render(conn, :full_account, %{account: account, token: nil})
  end

  def update(conn, %{"current_hash_password" => current_hash_password, "account" => account_params}) do

    with {:ok, _account, _token} <- Guardian.authenticate(conn.assigns.account.email, current_hash_password),
        {:ok, %Account{} = account} <- Accounts.update_account(conn.assigns.account, account_params) do
          render(conn, :show, account: account)
    else
      {:error, :unauthorized} ->
        raise ErrorResponse.Unauthorized, message: "Incorrect password."
   end
  end

  def delete(conn, %{"account" => account_params}) do
    account = Accounts.get_account!(account_params["id"])

    with {:ok, %Account{}} <- Accounts.delete_account(account) do
      send_resp(conn, :no_content, "")
    end
  end
end
