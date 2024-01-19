defmodule RealDealApiWeb.DefaultController do
  use RealDealApiWeb, :controller

  def index(conn, _params) do
    text(conn, "Real deal API is LIVE - #{Mix.env()}")
  end
end
