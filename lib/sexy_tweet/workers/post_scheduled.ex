defmodule SexyTweet.Workers.PostScheduled do
  use Oban.Worker, queue: :schedule
  alias SexyTweet.{Repo, ScheduledPost, XClient}

  @impl true
  def perform(%Oban.Job{
        args: %{"scheduled_post_id" => id, "consumer_key" => ck, "consumer_secret" => cs}
      }) do
    sp = Repo.get!(ScheduledPost, id) |> Repo.preload(:user)
    if sp.status == "sent", do: :ok, else: do_post(sp, ck, cs)
  end

  defp do_post(sp, ck, cs) do
    creds = %{
      consumer_key: ck,
      consumer_secret: cs,
      access_token: sp.user.access_token,
      access_secret: sp.user.access_secret
    }

    case XClient.post_tweet(creds, sp.text) do
      {:ok, _x_id} ->
        sp |> Ecto.Changeset.change(status: "sent") |> Repo.update!()
        :ok

      {:error, reason} ->
        IO.inspect(reason, label: "Post failed")
        {:error, reason}
    end
  end

  def enqueue_for(%SexyTweet.ScheduledPost{id: id, scheduled_for: at}, ck, cs) do
    Oban.insert!(
      __MODULE__.new(%{"scheduled_post_id" => id, "consumer_key" => ck, "consumer_secret" => cs},
        scheduled_at: at
      )
    )
  end
end
