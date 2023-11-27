# HttpJobProcessor

Implementation of a Http Task Scheduling Service. 

```text 
A job is a collection of tasks, where each task has a name and a shell command. Tasks may depend on other tasks and require that those are executed beforehand. The service takes care of sorting the tasks to create a proper execution order.
```

### Local Setup
```bash
mix deps.get
iex -S mix phx.server
```

Once successfully started The Service will be listening to port `4000`.

## Documentation

We are using [Swagger](https://swagger.io/docs/specification/about/) to document all available endpoints and their required parameters.

### Generate the swagger file

```bash
mix phx.swagger.generate
```

### Access to Swagger UI and Swagger File

Swagger UI [`localhost:4000/api/swagger`](http://localhost:4000/api/swagger)

Swagger file [`localhost:4000/api/swagger/swagger.json`](http://localhost:4000/api/swagger/swagger.json)

### API Response

By default all REST API endpoint response will be in `json` format. Endpoints also support `text` format to used response to piping into a shell script.  

Example:

- for `json` response
```bash 
curl -X POST "http://localhost:4000/api/schedule" -H "accept: application/json" -H "content-type: application/json" -d "{ \"tasks\": [ { \"command\": \"touch /tmp/file1\", \"name\": \"task-1\" }, { \"command\": \"cat /tmp/file1\", \"name\": \"task-2\", \"requires\": [ \"task-3\" ] }, { \"command\": \"echo 'Hello World!' > /tmp/file1\", \"name\": \"task-3\", \"requires\": [ \"task-1\" ] }, { \"command\": \"rm /tmp/file1\", \"name\": \"task-4\", \"requires\": [ \"task-2\", \"task-3\" ] } ]}"
```

```bash 
[
  {
    "command": "touch /tmp/file1",
    "name": "task-1"
  },
  {
    "command": "echo 'Hello World!' > /tmp/file1",
    "name": "task-3"
  },
  {
    "command": "cat /tmp/file1",
    "name": "task-2"
  },
  {
    "command": "rm /tmp/file1",
    "name": "task-4"
  }
]
```

#### 'text` content-type

```bash
curl -X POST "http://localhost:4000/api/schedule" -H "accept: text/plain" -H "content-type: application/json" -d "{ \"tasks\": [ { \"command\": \"touch /tmp/file1\", \"name\": \"task-1\" }, { \"command\": \"cat /tmp/file1\", \"name\": \"task-2\", \"requires\": [ \"task-3\" ] }, { \"command\": \"echo 'Hello World!' > /tmp/file1\", \"name\": \"task-3\", \"requires\": [ \"task-1\" ] }, { \"command\": \"rm /tmp/file1\", \"name\": \"task-4\", \"requires\": [ \"task-2\", \"task-3\" ] } ]}"
```

```bash
#!/usr/bin/env bash

touch /tmp/file1
echo 'Hello World!' > /tmp/file1
cat /tmp/file1
rm /tmp/file1
```  