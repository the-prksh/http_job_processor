defmodule HttpJobProcessor.JobsTest do
  use ExUnit.Case, async: true

  alias HttpJobProcessor.Jobs.Exceptions.CyclicDepsError
  alias HttpJobProcessor.Jobs

  @complex_graph [
    %{
      name: "task-1",
      command: "touch /tmp/file1",
      requires: []
    },
    %{
      name: "task-2",
      command: "cat /tmp/file1",
      requires: ["task-1", "task-3"]
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
    },
    %{
      name: "task-5",
      command: "mkdir /tmp/dir",
      requires: ["task-4"]
    },
    %{
      name: "task-6",
      command: "mv /tmp/file1 /tmp/dir",
      requires: ["task-5"]
    },
    %{
      name: "task-7",
      command: "ls /tmp/dir",
      requires: ["task-6"]
    },
    %{
      name: "task-8",
      command: "rmdir /tmp/dir",
      requires: ["task-7"]
    },
    %{
      name: "task-9",
      command: "rm /tmp/file1",
      requires: ["task-8"]
    },
    %{
      name: "task-10",
      command: "touch /tmp/file2",
      requires: ["task-9"]
    },
    %{
      name: "task-11",
      command: "mv /tmp/file2 /tmp/dir",
      requires: ["task-10"]
    },
    %{
      name: "task-12",
      command: "rm /tmp/file2",
      requires: ["task-11"]
    }
  ]

  @without_edge [
    %{
      name: "task-1",
      command: "touch /tmp/file1"
    },
    %{
      name: "task-2",
      command: "cat /tmp/file1"
    },
    %{
      name: "task-3",
      command: "echo 'Hello World!' > /tmp/file1"
    },
    %{
      name: "task-4",
      command: "rm /tmp/file1"
    }
  ]

  @duplicate_task [
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
    },
    %{
      name: "task-2",
      command: "cat /tmp/file1",
      requires: ["task-3"]
    }
  ]

  @duplicate_requires [
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
      requires: ["task-2", "task-3", "task-2"]
    }
  ]

  @valid_data [
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

  describe "Testing Sorting Algorithm" do
    test "with valid data", _context do
      assert [
               %{command: "touch /tmp/file1", name: "task-1"},
               %{
                 command: "echo 'Hello World!' > /tmp/file1",
                 name: "task-3",
                 requires: ["task-1"]
               },
               %{command: "cat /tmp/file1", name: "task-2", requires: ["task-3"]},
               %{command: "rm /tmp/file1", name: "task-4", requires: ["task-2", "task-3"]}
             ] == Jobs.topological_sort(@valid_data)
    end

    test "with invalid data, cyclic deps", _context do
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

  describe "Testing Sorting Algorithm, negative scenarios, " do
    test "with duplicate requirements", _context do
      assert [
               %{command: "touch /tmp/file1", name: "task-1"},
               %{
                 command: "echo 'Hello World!' > /tmp/file1",
                 name: "task-3",
                 requires: ["task-1"]
               },
               %{command: "cat /tmp/file1", name: "task-2", requires: ["task-3"]},
               %{
                 command: "rm /tmp/file1",
                 name: "task-4",
                 requires: ["task-2", "task-3", "task-2"]
               }
             ] == Jobs.topological_sort(@duplicate_requires)
    end

    test "with duplicate task", _context do
      assert [
               %{command: "touch /tmp/file1", name: "task-1"},
               %{
                 command: "echo 'Hello World!' > /tmp/file1",
                 name: "task-3",
                 requires: ["task-1"]
               },
               %{command: "cat /tmp/file1", name: "task-2", requires: ["task-3"]},
               %{
                 command: "rm /tmp/file1",
                 name: "task-4",
                 requires: ["task-2", "task-3"]
               }
             ] == Jobs.topological_sort(@duplicate_task)
    end

    test "with graph without edge", _context do
      assert [
               %{command: "touch /tmp/file1", name: "task-1"},
               %{command: "cat /tmp/file1", name: "task-2"},
               %{command: "echo 'Hello World!' > /tmp/file1", name: "task-3"},
               %{command: "rm /tmp/file1", name: "task-4"}
             ] == Jobs.topological_sort(@without_edge)
    end

    test "with complex graph", _context do
      assert [
               %{command: "touch /tmp/file1", name: "task-1", requires: []},
               %{
                 command: "echo 'Hello World!' > /tmp/file1",
                 name: "task-3",
                 requires: ["task-1"]
               },
               %{command: "cat /tmp/file1", name: "task-2", requires: ["task-1", "task-3"]},
               %{command: "rm /tmp/file1", name: "task-4", requires: ["task-2", "task-3"]},
               %{command: "mkdir /tmp/dir", name: "task-5", requires: ["task-4"]},
               %{command: "mv /tmp/file1 /tmp/dir", name: "task-6", requires: ["task-5"]},
               %{command: "ls /tmp/dir", name: "task-7", requires: ["task-6"]},
               %{command: "rmdir /tmp/dir", name: "task-8", requires: ["task-7"]},
               %{command: "rm /tmp/file1", name: "task-9", requires: ["task-8"]},
               %{command: "touch /tmp/file2", name: "task-10", requires: ["task-9"]},
               %{command: "mv /tmp/file2 /tmp/dir", name: "task-11", requires: ["task-10"]},
               %{command: "rm /tmp/file2", name: "task-12", requires: ["task-11"]}
             ] == Jobs.topological_sort(@complex_graph)
    end
  end
end
