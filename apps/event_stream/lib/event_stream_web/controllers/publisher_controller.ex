defmodule EventStream.PublisherController do
  use EventStream, :controller

  def stats(conn, _two) do
    render(conn, "stats.html", %{})
  end
end