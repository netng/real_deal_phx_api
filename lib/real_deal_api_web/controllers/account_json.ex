defmodule RealDealApiWeb.AccountJSON do
  require Logger
  alias RealDealApi.{Accounts.Account, Users.User}
  alias RealDealApiWeb.UserJSON

  @doc """
  Renders a list of accounts.
  """
  def index(%{accounts: accounts}) do
    %{data: for(account <- accounts, do: data(account))}
  end

  @doc """
  Renders a single account.
  """
  def show(%{account: account}) do
    %{data: data(account)}
  end

  def account_token(%{account: account, token: token}) do
    %{data: data(account, token)}
  end

  def full_account(%{account: account, token: token}) do
    %{
      data: %{
        id: account.id,
        email: account.email,
        user: UserJSON.user(account.user)
      }
    }
  end

  defp data(%Account{} = account, token \\ nil) do
    %{
      id: account.id,
      email: account.email,
      # hash_password: account.hash_password,
      token: token,
    }
  end
end
