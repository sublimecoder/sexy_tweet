# lib/sexy_tweet_web/live/auth_live.ex
defmodule SexyTweetWeb.AuthLive do
  use SexyTweetWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, current_user_id: Map.get(session, "current_user_id"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10 max-w-xl mx-auto text-center">
      <h1 class="text-3xl font-bold mb-3">Connect your X account</h1>
      <p class="text-gray-600 mb-8">
        Click the button below to authorize SexyTweet.
      </p>

      <a href={~p"/auth/x"} class="inline-block bg-black text-white px-5 py-3 rounded">
        Connect X
      </a>

      <p class="text-xs text-gray-500 mt-4">
        You’ll be redirected to X.com to approve access and then returned here.
      </p>
    </div>
    """
  end
end
