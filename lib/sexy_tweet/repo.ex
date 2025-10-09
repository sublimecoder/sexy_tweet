defmodule SexyTweet.Repo do
  use Ecto.Repo,
    otp_app: :sexy_tweet,
    adapter: Ecto.Adapters.Postgres
end
