defmodule SexyTweetWeb.TweetsLive do
  use SexyTweetWeb, :live_view
  import Ecto.Query
  alias SexyTweet.{Repo, Tweet, ScheduledPost}

  def mount(_p, _s, socket) do
    {:ok,
     assign(socket, tweets: Repo.all(from t in Tweet, order_by: [desc: t.inserted_at], limit: 50))}
  end

  def handle_event("schedule", %{"text" => text}, socket) do
    # In a real app, tie to current user; here we grab any user
    user_id = Repo.one(from t in Tweet, select: t.user_id, limit: 1) || raise "no user"
    # 5 minutes later
    time = DateTime.add(DateTime.utc_now(), 5 * 60)

    Repo.insert!(%ScheduledPost{
      user_id: user_id,
      text: text,
      scheduled_for: time,
      status: "queued"
    })

    {:noreply, put_flash(socket, :info, "Scheduled for 5 minutes from now")}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h2 class="text-2xl font-bold mb-4">Imported Tweets</h2>
      <ul class="space-y-3">
        <%= for t <- @tweets do %>
          <li class="border rounded p-3">
            <div class="text-sm text-gray-500 mb-1">ID: {t.x_tweet_id}</div>
            <div class="mb-3">{t.text}</div>
            <.button phx-click="schedule" phx-value-text={t.text}>Schedule Repost</.button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
