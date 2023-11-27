defmodule HttpJobProcessor.Jobs do
  alias HttpJobProcessor.Jobs.Exceptions.CyclicDepsError

  # tasks = [
  #   %{
  #     name: "task-1",
  #     command: "touch /tmp/file1"
  #   },
  #   %{
  #     name: "task-2",
  #     command: "cat /tmp/file1",
  #     requires: ["task-3"]
  #   },
  #   %{
  #     name: "task-3",
  #     command: "echo 'Hello World!' > /tmp/file1",
  #     requires: ["task-1"]
  #   },
  #   %{
  #     name: "task-4",
  #     command: "rm /tmp/file1",
  #     requires: ["task-2", "task-3"]
  #   }
  # ]
  def schedule(tasks) do
    tasks
    |> topological_sort()
  end

  def topological_sort(tasks) do
    %{ordered: ordered} =
      for task <- tasks, reduce: %{visited: [], ordered: []} do
        %{visited: visited, ordered: ordered} = acc ->
          if task.name not in visited do
            dfs(task, tasks, visited, ordered, [])
          else
            acc
          end
      end

    Enum.reverse(ordered)
  end

  defp dfs(%{name: name} = task, task_list, visited, ordered, cyclic_check) do
    if task.name in cyclic_check do
      raise(CyclicDepsError, "")
    end

    if(task.name not in visited) do
      visited = [name | visited]

      if is_nil(task[:requires]) do
        %{visited: visited, ordered: [task | ordered]}
      else
        temp =
          for dep <- task.requires, reduce: %{visited: visited, ordered: ordered} do
            %{visited: visited, ordered: ordered} ->
              task_list
              |> Enum.find(fn t -> t.name == dep end)
              |> dfs(task_list, visited, ordered, [task.name | cyclic_check])
          end

        %{visited: temp.visited, ordered: [task | temp.ordered]}
      end
    else
      %{visited: visited, ordered: ordered}
    end
  end
end
