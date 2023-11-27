defmodule HttpJobProcessor.JobsTest do
  use ExUnit.Case, async: true

  alias HttpJobProcessor.Jobs.Exceptions.CyclicDepsError
  alias HttpJobProcessor.Jobs

  describe "Testing Sorting Algorithm" do
    test "with valid data", context do
      tasks = [
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

      assert [
               %{command: "touch /tmp/file1", name: "task-1"},
               %{
                 command: "echo 'Hello World!' > /tmp/file1",
                 name: "task-3",
                 requires: ["task-1"]
               },
               %{command: "cat /tmp/file1", name: "task-2", requires: ["task-3"]},
               %{command: "rm /tmp/file1", name: "task-4", requires: ["task-2", "task-3"]}
             ] == Jobs.topological_sort(tasks)
    end

    test "with invalid data, cyclic deps", context do
      tasks = [
        %{
          name: "task-1",
          command: "touch /tmp/file1",
          requires: ["task-2"]
        },
        %{
          name: "task-2",
          command: "cat /tmp/file1",
          requires: ["task-1"]
        }
      ]

      assert_raise CyclicDepsError, fn -> Jobs.topological_sort(tasks) end
    end
  end
end
