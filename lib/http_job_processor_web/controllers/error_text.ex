defmodule HttpJobProcessorWeb.ErrorTEXT do
  def render(template, assigns) do
    "echo \"error-#{assigns[:message] || Phoenix.Controller.status_message_from_template(template)}\""
  end
end
