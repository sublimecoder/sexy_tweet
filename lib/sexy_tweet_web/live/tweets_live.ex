defmodule SexyTweetWeb.TweetsLive do
  use SexyTweetWeb, :live_view
  import Ecto.Query

  alias SexyTweet.{Repo, Tweet, ScheduledPost}
  alias SexyTweet.Workers.PostScheduled

  @impl true
  def mount(_params, session, socket) do
    user_id = Map.get(session, "current_user_id")

    if is_nil(user_id) do
      {:ok,
       socket
       |> put_flash(:error, "Please connect your X account first.")
       |> push_navigate(to: ~p"/")}
    else
      tweets =
        Repo.all(
          from t in Tweet,
            where: t.user_id == ^user_id,
            order_by: [desc: t.inserted_at],
            limit: 100
        )

      {:ok,
       assign(socket,
         user_id: user_id,
         tweets: tweets,
         schedule_in_minutes: "10",
         flash_msg: nil
       )}
    end
  end

  @impl true
  def handle_event("schedule", %{"text" => text, "mins" => mins_str}, socket) do
    mins = parse_positive_int(mins_str, 10)
    at = DateTime.add(DateTime.utc_now(), mins * 60)

    sp =
      Repo.insert!(%ScheduledPost{
        user_id: socket.assigns.user_id,
        text: text,
        scheduled_for: at,
        status: "queued"
      })

    ck = System.get_env("X_CONSUMER_KEY")
    cs = System.get_env("X_CONSUMER_SECRET")

    PostScheduled.enqueue_for(sp, ck, cs)

    {:noreply, put_flash(socket, :info, "Scheduled in #{mins} min")}
  end

  defp parse_positive_int(str, default) do
    case Integer.parse(to_string(str)) do
      {n, ""} when n > 0 -> n
      _ -> default
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-8 max-w-4xl mx-auto">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-2xl font-bold">My Tweets</h2>
        <a href={~p"/generate"} class="px-3 py-2 rounded bg-purple-600 text-white">Generate New</a>
      </div>

      <div class="mb-4">
        <label class="text-sm text-gray-700">Schedule repost delay (minutes)</label>
        <input
          type="number"
          min="1"
          name="mins"
          value={@schedule_in_minutes}
          class="border rounded p-2 w-32 ml-2"
        />
        <span class="text-xs text-gray-500 ml-2">Used as default when you click “Schedule”</span>
      </div>

      <ul class="space-y-3">
        <%= for t <- @tweets do %>
          <li class="border rounded p-3">
            <div class="text-xs text-gray-500 mb-1">x_id: {t.x_tweet_id}</div>
            <div class="mb-3 whitespace-pre-wrap">{t.text}</div>

            <form phx-submit="schedule" class="flex items-center gap-2">
              <input type="hidden" name="text" value={t.text} />
              <input
                type="number"
                min="1"
                name="mins"
                value={@schedule_in_minutes}
                class="border rounded p-2 w-24"
              />
              <button class="px-3 py-2 rounded bg-blue-600 text-white">Schedule</button>
            </form>
          </li>
        <% end %>
      </ul>

      <%= if @tweets == [] do %>
        <div class="text-center text-gray-500 mt-10">
          No tweets imported yet. They’ll appear here after your first sync finishes.
        </div>
      <% end %>
    </div>
    """
  end
end
