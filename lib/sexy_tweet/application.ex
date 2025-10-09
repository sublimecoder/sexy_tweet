defmodule SexyTweet.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SexyTweetWeb.Telemetry,
      SexyTweet.Repo,
      {DNSCluster, query: Application.get_env(:sexy_tweet, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SexyTweet.PubSub},
      # Start a worker by calling: SexyTweet.Worker.start_link(arg)
      # {SexyTweet.Worker, arg},
      # Start to serve requests, typically the last entry
      SexyTweetWeb.Endpoint,
      {Oban, Application.fetch_env!(:sexy_tweet, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SexyTweet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SexyTweetWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
