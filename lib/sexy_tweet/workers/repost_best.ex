defmodule SexyTweet.Workers.RepostBest do
  use Oban.Worker, queue: :schedule
  import Ecto.Query
  alias SexyTweet.{Repo, Tweet, ScheduledPost}

  @impl true
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    tweet =
      Repo.one(
        from t in Tweet,
          where: t.user_id == ^user_id,
          order_by: [desc: t.score],
          limit: 1
      )

    if tweet do
      # 1 hour later
      time = DateTime.add(DateTime.utc_now(), 3600)

      Repo.insert!(%ScheduledPost{
        user_id: user_id,
        text: tweet.text,
        scheduled_for: time,
        status: "queued"
      })
    end

    :ok
  end
end
