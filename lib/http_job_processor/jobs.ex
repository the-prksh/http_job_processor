defmodule HttpJobProcessor.Jobs do
  @moduledoc false
  alias HttpJobProcessor.Jobs.Exceptions.CyclicDepsError

  @doc """
    A Function to schedule the GIven List of Tasks based on
  the given dependencies.

  Example:

  iex> tasks = [
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

  iex> HttpJobProcessor.Jobs.schedule(tasks)
  {:ok,
    [
      %{command: "touch /tmp/file1", name: "task-1"},
      %{
        command: "echo 'Hello World!' > /tmp/file1",
        name: "task-3",
        requires: ["task-1"]
      },
      %{command: "cat /tmp/file1", name: "task-2", requires: ["task-3"]},
      %{command: "rm /tmp/file1", name: "task-4", requires: ["task-2", "task-3"]}
    ]}
  """
  def schedule(tasks) do
    try do
      {:ok, topological_sort(tasks)}
    rescue
      e in CyclicDepsError ->
        {:error, e.message}
    end
  end

  @doc """
      An Implementation of the DFS Topological Sorting Algorithm.

      Function also raise exception if given list of tasks has a Cyclic
    Dependencies.

    Example:

    iex> tasks = [
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

    iex(5)> HttpJobProcessor.Jobs.topological_sort tasks
    [
      %{command: "touch /tmp/file1", name: "task-1"},
      %{
        command: "echo 'Hello World!' > /tmp/file1",
        name: "task-3",
        requires: ["task-1"]
      },
      %{command: "cat /tmp/file1", name: "task-2", requires: ["task-3"]},
      %{command: "rm /tmp/file1", name: "task-4", requires: ["task-2", "task-3"]}
    ]

  """
  def topological_sort(tasks) do
    %{ordered: ordered} =
      for task <- tasks, reduce: %{visited: [], ordered: []} do
        %{visited: visited, ordered: ordered} = acc ->
          if task.name in visited do
            acc
          else
            dfs(task, tasks, visited, ordered, [])
          end
      end

    Enum.reverse(ordered)
  end

  defp dfs(%{name: name} = task, task_list, visited, ordered, cyclic_check) do
    if task.name in cyclic_check do
      raise(CyclicDepsError, "")
    end

    with {:visited, false} <- {:visited, task.name in visited},
         {:deps_nil, false} <- {:deps_nil, is_nil(task[:requires])} do
      visited = [name | visited]

      temp =
        for dep <- task.requires, reduce: %{visited: visited, ordered: ordered} do
          %{visited: visited, ordered: ordered} ->
            task_list
            |> Enum.find(fn t -> t.name == dep end)
            |> dfs(task_list, visited, ordered, [task.name | cyclic_check])
        end

      %{visited: temp.visited, ordered: [task | temp.ordered]}
    else
      {:visited, true} -> %{visited: visited, ordered: ordered}
      {:deps_nil, true} -> %{visited: [name | visited], ordered: [task | ordered]}
    end
  end
end
