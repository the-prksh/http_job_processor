defmodule HttpJobProcessorWeb.Router do
  use HttpJobProcessorWeb, :router

  pipeline :api do
    plug :accepts, ["json", "text"]
    plug PhoenixSwagger.Plug.Validate
  end

  def swagger_info do
    %{
      info: %{
        version: "0.1",
        title: "HTTP Job Schedular"
      },
      consumes: ["application/json"],
      produces: ["application/json", "text/plain"]
    }
  end

  scope "/api", HttpJobProcessorWeb do
    pipe_through :api

    post "/schedule", JobController, :create
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :http_job_processor,
      swagger_file: "swagger.json"
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:http_job_processor, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: HttpJobProcessorWeb.Telemetry
    end
  end
end
