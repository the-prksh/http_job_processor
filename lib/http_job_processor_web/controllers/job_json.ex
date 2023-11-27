defmodule HttpJobProcessorWeb.JobJSON do
  def create(%{tasks: tasks}) do
    for(task <- tasks, do: data(task))
  end

  defp data(task) do
    %{
      name: task[:name],
      command: task[:command]
    }
  end
end
