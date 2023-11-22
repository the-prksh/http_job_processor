import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :http_job_processor, HttpJobProcessorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "xVrMMS3yeKk6yIlDU0dFSCivHTh6abj7tkUHZ5Vqfcmz1bDjST6d29dx2IFVhW/F",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
