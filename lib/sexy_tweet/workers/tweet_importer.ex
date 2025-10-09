defmodule SexyTweet.Workers.TweetImporter do
  use Oban.Worker, queue: :import
  import Ecto.Query, only: [from: 2]
  alias SexyTweet.{Repo, XClient, Tweet, User}

  @impl true
  def perform(%Oban.Job{
        args: %{"user_id" => user_id, "consumer_key" => ck, "consumer_secret" => cs}
      }) do
    user = Repo.get!(User, user_id)

    creds = %{
      consumer_key: ck,
      consumer_secret: cs,
      access_token: user.access_token,
      access_secret: user.access_secret
    }

    with {:ok, tweets} <- XClient.get_user_tweets(user.x_user_id, creds) do
      now = DateTime.utc_now()

      existing_ids =
        Repo.all(from t in Tweet, where: t.user_id == ^user.id, select: t.x_tweet_id)
        |> MapSet.new()

      new_rows =
        tweets
        |> Enum.reject(&(&1.id in existing_ids))
        |> Enum.map(fn t ->
          %{
            x_tweet_id: t.id,
            text: t.text,
            metrics: t.metrics || %{},
            score: score(t),
            user_id: user.id,
            imported_at: now,
            inserted_at: now,
            updated_at: now
          }
        end)

      if new_rows != [] do
        Repo.insert_all(Tweet, new_rows, on_conflict: :nothing)
      end

      :ok
    end
  end

  defp score(%{metrics: m}) when is_map(m) do
    likes = Map.get(m, "like_count", 0)
    reposts = Map.get(m, "retweet_count", 0)
    replies = Map.get(m, "reply_count", 0)
    likes * 1.0 + reposts * 2.0 + replies * 1.5
  end

  defp score(_), do: 0.0
end
