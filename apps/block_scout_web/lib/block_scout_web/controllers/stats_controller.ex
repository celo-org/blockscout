defmodule BlockScoutWeb.StatsController do
  use BlockScoutWeb, :controller

  def index(conn, _params) do
    conn
    |> redirect(to: "/stats/overview")
  end

  def overview(conn, _params) do
    conn
    |> put_status(200)
    |> render("notification.html", active: "overview")
  end

  def addresses(conn, _params) do
    conn
    |> put_status(200)
    |> render("iframe.html", active: "addresses")
  end

  def mento(conn, _params) do
    conn
    |> put_status(200)
    |> render("notification.html", active: "mento")
  end

  def mento_reserve(conn, _params) do
    conn
    |> put_status(200)
    |> render("notification.html", active: "mento-reserve")
  end

  def transactions(conn, _params) do
    conn
    |> put_status(200)
    |> render("iframe.html", active: "transactions")
  end

  def epochs(conn, _params) do
    conn
    |> put_status(200)
    |> render("iframe.html", active: "epoch")
  end
end
