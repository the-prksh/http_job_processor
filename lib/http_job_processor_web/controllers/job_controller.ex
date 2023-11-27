defmodule HttpJobProcessorWeb.JobController do
  use Phoenix.Controller, formats: [:text, :json]
  use PhoenixSwagger
  alias HttpJobProcessor.Jobs

  action_fallback HttpJobProcessorWeb.FallbackController

  require Logger

  def swagger_definitions do
    %{
      JobScheduleRequest:
        swagger_schema do
          title("Job")
          description("")

          properties do
            name(:string, "Task Name", required: true)
          end
        end,
      Task:
        swagger_schema do
          title("Job")

          properties do
            name(:string, "Task Name", required: true)
            command(:string, "Command", required: true)
            requires(:array, "list of task dependencies", items: :string)
          end

          example(%{
            name: "task-1",
            command: "touch /tmp/file",
            requires: ["task-3"]
          })
        end,
      JobScheduleResponse:
        swagger_schema do
          title("Job")

          properties do
          end
        end
    }
  end

  swagger_path :schedule do
    post("/api/schedule")
    description("")
    produces("application/json")
    produces("text/plain")

    parameters do
      tasks(:body, Schema.ref(:JobScheduleRequest), "The Tasks Details.",
        example: %{
          tasks: [
            %{
              name: "task-1",
              command: "touch /tmp/file1"
            },
            %{
              name: "task-2",
              command: "cat /tmp/file1",
              requires: ["task-3"]
            },
            %{
              name: "task-3",
              command: "echo 'Hello World!' > /tmp/file1",
              requires: ["task-1"]
            },
            %{
              name: "task-4",
              command: "rm /tmp/file1",
              requires: ["task-2", "task-3"]
            }
          ]
        }
      )
    end

    response(200, "OK", Schema.ref(:JobScheduleResponse))

    response(422, "Unprocessable Entity.")
    tag("Jobs")
  end

  def create(conn, params) do
    with tasks = params["tasks"],
         {:ok, tasks} <- tasks |> atomize_keys() |> Jobs.schedule() do
      render(conn, :create, tasks: tasks)
    end
  end

  @doc """
  Convert map string keys to :atom keys
  """
  def atomize_keys(nil), do: nil

  def atomize_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  # Walk the list and atomize the keys of
  # of any map members
  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(not_a_map) do
    not_a_map
  end
end
