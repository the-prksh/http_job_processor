defmodule HttpJobProcessor.Jobs.Exceptions.CyclicDepsError do
  defexception [:message]

  @impl true
  def exception(_term) do
    msg = "the Task Definition contains a cycle"
    %__MODULE__{message: msg}
  end
end
