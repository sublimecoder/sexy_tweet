defmodule SexyTweetWeb.ConnectLive do
  use SexyTweetWeb, :live_view
  alias SexyTweet.{Repo, User}
  alias SexyTweet.Workers.TweetImporter

  def mount(_p, _s, socket), do: {:ok, assign(socket, changeset: User.changeset(%User{}, %{}))}

  # lib/sexy_tweet_web/live/connect_live.ex
  def render(assigns) do
    ~H"""
    <div class="p-8 max-w-lg mx-auto">
      <h2 class="text-2xl font-bold mb-4">Connect X.com</h2>
      <p class="text-sm text-gray-600 mb-4">Enter your X account details and tokens.</p>

      <form phx-submit="save" class="space-y-3">
        <label class="block">
          <span class="text-sm">X User ID</span>
          <input type="text" name="x_user_id" class="border rounded p-2 w-full" />
        </label>

        <label class="block">
          <span class="text-sm">Username</span>
          <input type="text" name="x_username" class="border rounded p-2 w-full" />
        </label>

        <label class="block">
          <span class="text-sm">Access Token</span>
          <input type="text" name="access_token" class="border rounded p-2 w-full" />
        </label>

        <label class="block">
          <span class="text-sm">Access Secret</span>
          <input type="text" name="access_secret" class="border rounded p-2 w-full" />
        </label>

        <label class="block">
          <span class="text-sm">App Consumer Key</span>
          <input type="text" name="consumer_key" class="border rounded p-2 w-full" />
        </label>

        <label class="block">
          <span class="text-sm">App Consumer Secret</span>
          <input type="text" name="consumer_secret" class="border rounded p-2 w-full" />
        </label>

        <button class="bg-blue-600 text-white px-4 py-2 rounded">Save & Import</button>
      </form>
    </div>
    """
  end

  def handle_event("save", params, socket) do
    {ck, cs} = {Map.get(params, "consumer_key", ""), Map.get(params, "consumer_secret", "")}
    user_params = Map.take(params, ~w[x_user_id x_username access_token access_secret])

    case Repo.insert(User.changeset(%User{}, user_params)) do
      {:ok, user} ->
        # kick off import
        Oban.insert!(
          TweetImporter.new(%{
            "user_id" => user.id,
            "consumer_key" => ck,
            "consumer_secret" => cs
          })
        )

        {:noreply,
         socket |> put_flash(:info, "Connected! Import queued.") |> push_navigate(to: ~p"/tweets")}

      {:error, cs} ->
        {:noreply, assign(socket, changeset: cs) |> put_flash(:error, "Fix form errors")}
    end
  end
end
