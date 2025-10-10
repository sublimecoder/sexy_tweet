defmodule SexyTweetWeb.PageLive do
  use SexyTweetWeb, :live_view

  alias SexyTweet.{Repo, User}

  @impl true
  def mount(_params, session, socket) do
    user =
      case Map.get(session, "current_user_id") do
        nil -> nil
        id -> Repo.get(User, id)
      end

    {:ok, assign(socket, current_user: user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10 max-w-3xl mx-auto text-center">
      <h1 class="text-4xl font-extrabold mb-3">SexyTweet 🔥</h1>
      <p class="text-gray-600 mb-8">
        Turn-key AI tweet generator & scheduler for X.com.
        Connect your account, generate tone-matched posts, and schedule them—no app setup needed.
      </p>

      <%= if @current_user do %>
        <div class="mb-6">
          <p class="text-sm text-gray-700">
            Connected as <span class="font-semibold">@{@current_user.x_username}</span>
          </p>
        </div>

        <div class="flex flex-wrap gap-3 justify-center">
          <a href={~p"/tweets"} class="px-4 py-2 rounded bg-blue-600 text-white">My Tweets</a>
          <a href={~p"/generate"} class="px-4 py-2 rounded bg-purple-600 text-white">Generate New</a>
        </div>
      <% else %>
        <a href={~p"/auth/x"} class="inline-block px-5 py-3 rounded bg-black text-white">
          Connect X
        </a>
        <p class="text-xs text-gray-500 mt-3">
          You’ll be redirected to X to authorize, then sent back here automatically.
        </p>
      <% end %>

      <hr class="my-10 border-gray-200" />

      <div class="grid md:grid-cols-3 gap-6 text-left">
        <div class="border rounded-lg p-5">
          <h3 class="font-semibold mb-1">Import History</h3>
          <p class="text-sm text-gray-600">
            We sync your recent posts so you can browse, search, and reuse your best content.
          </p>
        </div>
        <div class="border rounded-lg p-5">
          <h3 class="font-semibold mb-1">AI Generation</h3>
          <p class="text-sm text-gray-600">
            Draft new tweets matched to your tone. Edit, approve, and queue with one click.
          </p>
        </div>
        <div class="border rounded-lg p-5">
          <h3 class="font-semibold mb-1">Schedule & Repost</h3>
          <p class="text-sm text-gray-600">
            Schedule posts and auto-repost your all-time best performers at smart intervals.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
