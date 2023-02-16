defmodule EventStream.ReceivedLive do
  use EventStream, :live_view

  alias EventStream.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    events = ["{\"block_number\":17777818,\"contract_address_hash\":\"0x471ece3750da237f93b8e339c536989b8978a438\",\"log_index\":2,\"name\":\"Transfer\",\"params\":{\"from\":\"0xb460f9ae1fea4f77107146c1960bb1c978118816\",\"to\":\"0x0ef38e213223805ec1810eebd42153a072a2d89a\",\"value\":6177463272192542},\"topic\":\"0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef\",\"transaction_hash\":\"0x7640d07bdc3b51065169b8f6a4720c2f807716f31e40212d81b41dfe1441668b\"}"]
    assigns =
      socket
      |> assign(query: "", results: %{})
      |> assign(events: events)
    {:ok,  assigns}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
          socket
          |> put_flash(:error, "No dependencies found matching \"#{query}\"")
          |> assign(results: %{}, query: query)}
    end
  end

  defp search(query) do
    if not Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
