defmodule BlockScoutWeb.PosValidatorsController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain, only: [paging_options: 1]

  alias HTTPoison.Response

  def index(conn, %{"type" => "JSON"} = params) do
    filter =
      if Map.has_key?(params, "filter") do
        Map.get(params, "filter")
      else
        nil
      end

    paging_params =
      params
      |> paging_options()
    _ = paging_params

    api_url = System.get_env("POSEIDON_JSONRPC_HTTP_URL") || "http://localhost:2028"
    result = case HTTPoison.get("#{api_url}/api/validators?filter=#{filter}") do
      {:ok, %Response{body: body, status_code: 200}} ->
        json = Jason.decode!(body)
        json
      _ ->
        nil
    end

    items =
      case result do
        nil ->
          %{}

        json ->
          json["items"]
      end

    next_page_path =
      case result do
        nil ->
          ""

        json ->
          json["next_page_path"]
      end

    json(
      conn,
      %{
        items: items,
        next_page_path: next_page_path
      }
    )
  end

  def index(conn, _params) do
    render(conn, "index.html", current_path: current_path(conn))
  end
end
