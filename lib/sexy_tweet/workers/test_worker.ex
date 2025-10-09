defmodule SexyTweet.Workers.TestWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(_job) do
    IO.puts("🔥 Oban is working! Your test job ran successfully.")
    :ok
  end
end
