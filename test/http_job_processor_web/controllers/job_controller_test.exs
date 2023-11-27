defmodule HttpJobProcessorWeb.JobControllerTest do
  use HttpJobProcessorWeb.ConnCase

  describe "Schedule Tasks, " do
    setup _ctx do
      {:ok,
       payload: %{
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
       }}
    end

    test "when data is valid and json response content-type.", %{
      conn: conn,
      payload: payload
    } do
      resp =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/api/schedule", payload)
        |> json_response(200)

      assert [
               %{"command" => "touch /tmp/file1", "name" => "task-1"},
               %{"command" => "echo 'Hello World!' > /tmp/file1", "name" => "task-3"},
               %{"command" => "cat /tmp/file1", "name" => "task-2"},
               %{"command" => "rm /tmp/file1", "name" => "task-4"}
             ] == resp
    end

    test "when data is valid and text/plain response content-type.", %{
      conn: conn,
      payload: payload
    } do
      resp =
        conn
        |> put_req_header("accept", "text/plain")
        |> post(~p"/api/schedule", payload)
        |> text_response(200)

      assert String.trim_trailing(~S"""
             #!/usr/bin/env bash

             touch /tmp/file1
             echo 'Hello World!' > /tmp/file1
             cat /tmp/file1
             rm /tmp/file1
             """) == resp
    end
  end

  describe "Schedule Tasks with cyclic deps, " do
    setup _ctx do
      {:ok,
       payload: %{
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
             requires: ["task-1", "task-2"]
           },
           %{
             name: "task-4",
             command: "rm /tmp/file1",
             requires: ["task-2", "task-3"]
           }
         ]
       }}
    end

    test "when data is invalid and json response content-type.", %{
      conn: conn,
      payload: payload
    } do
      resp =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/api/schedule", payload)
        |> json_response(422)

      assert %{"errors" => %{"detail" => "the Task Definition contains a cycle"}} == resp
    end

    test "when data is valid and text/plain response content-type.", %{
      conn: conn,
      payload: payload
    } do
      resp =
        conn
        |> put_req_header("accept", "text/plain")
        |> post(~p"/api/schedule", payload)
        |> text_response(422)

      assert "echo \"error-the Task Definition contains a cycle\"" == resp
    end
  end
end
