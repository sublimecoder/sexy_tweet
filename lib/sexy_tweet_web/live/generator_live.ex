defmodule SexyTweetWeb.GeneratorLive do
  use SexyTweetWeb, :live_view
  import Ecto.Query
  alias SexyTweet.{Repo, Tweet, ScheduledPost, AIGenerator}

  def mount(_p, _s, socket) do
    tweets = Repo.all(from t in Tweet, limit: 50, order_by: [desc: t.inserted_at])
    {:ok, assign(socket, tweets: tweets, generated: [])}
  end

  def handle_event("generate", _params, socket) do
    candidates = AIGenerator.generate_from_history(socket.assigns.tweets, 5)
    {:noreply, assign(socket, generated: candidates)}
  end

  def handle_event("schedule", %{"text" => text}, socket) do
    user_id = socket.assigns.tweets |> List.first() |> Map.get(:user_id) || raise "no user"
    time = DateTime.add(DateTime.utc_now(), 10 * 60)

    Repo.insert!(%ScheduledPost{
      user_id: user_id,
      text: text,
      scheduled_for: time,
      status: "queued"
    })

    # ck = System.get_env("X_CONSUMER_KEY")
    # cs = System.get_env("X_CONSUMER_SECRET")
    # SexyTweet.Workers.PostScheduled.enqueue_for(sp, ck, cs)

    {:noreply, put_flash(socket, :info, "Scheduled in 10 minutes")}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h2 class="text-2xl font-bold mb-4">Generate New Tweets</h2>
      <.button phx-click="generate">Generate</.button>

      <%= if @generated != [] do %>
        <h3 class="text-xl font-semibold mt-6 mb-2">Suggestions</h3>
        <ul class="space-y-2">
          <%= for g <- @generated do %>
            <li class="border rounded p-3 flex items-center justify-between">
              <span>{g}</span>
              <.button phx-click="schedule" phx-value-text={g}>Schedule</.button>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end
end
