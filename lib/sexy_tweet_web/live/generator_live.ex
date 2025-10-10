defmodule SexyTweetWeb.GeneratorLive do
  use SexyTweetWeb, :live_view
  import Ecto.Query

  alias SexyTweet.{Repo, Tweet, ScheduledPost, AIGenerator}
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
            limit: 80
        )

      {:ok,
       assign(socket,
         user_id: user_id,
         tweets: tweets,
         generated: [],
         schedule_in_minutes: "10",
         generating: false
       )}
    end
  end

  @impl true
  def handle_event("generate", _params, socket) do
    # Simple synchronous generation; switch to Oban worker if you want async.
    suggestions = AIGenerator.generate_from_history(socket.assigns.tweets, 5)
    {:noreply, assign(socket, generated: suggestions, generating: false)}
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
    <div class="p-8 max-w-3xl mx-auto">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-2xl font-bold">AI Generator</h2>
        <a href={~p"/tweets"} class="px-3 py-2 rounded bg-blue-600 text-white">My Tweets</a>
      </div>

      <form phx-submit="generate" class="mb-4">
        <button class="px-4 py-2 rounded bg-purple-600 text-white">
          Generate Suggestions
        </button>
      </form>

      <div class="mb-4">
        <label class="text-sm text-gray-700">Schedule delay (minutes)</label>
        <input
          type="number"
          min="1"
          name="mins"
          value={@schedule_in_minutes}
          phx-hook="NoHook"
          class="border rounded p-2 w-32 ml-2"
          phx-update="ignore"
        />
      </div>

      <%= if @generated == [] do %>
        <p class="text-gray-500">No suggestions yet. Click “Generate Suggestions”.</p>
      <% else %>
        <ul class="space-y-3">
          <%= for g <- @generated do %>
            <li class="border rounded p-3">
              <div class="mb-3 whitespace-pre-wrap">{g}</div>
              <form phx-submit="schedule" class="flex items-center gap-2">
                <input type="hidden" name="text" value={g} />
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
      <% end %>
    </div>
    """
  end
end
