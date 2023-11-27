defmodule HttpJobProcessorWeb.JobTEXT do
  def create(%{tasks: tasks}) do
    commands_list =
      for task <- tasks, str = data(task), reduce: [] do
        acc -> [str | acc]
      end
      |> Enum.reverse()

    "#!/usr/bin/env bash\n\n" <> Enum.join(commands_list, "\n")
  end

  defp data(task) do
    String.Chars.to_string(task[:command])
  end
end
