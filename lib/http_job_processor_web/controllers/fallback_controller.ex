defmodule HttpJobProcessorWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use HttpJobProcessorWeb, :controller

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(text: HttpJobProcessorWeb.ErrorTEXT, json: HttpJobProcessorWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, message}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(text: HttpJobProcessorWeb.ErrorTEXT, json: HttpJobProcessorWeb.ErrorJSON)
    |> render(:"422", message: message)
  end
end
