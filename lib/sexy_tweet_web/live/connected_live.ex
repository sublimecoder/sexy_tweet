defmodule SexyTweetWeb.ConnectedLive do
  use SexyTweetWeb, :live_view
  alias SexyTweet.{Repo, User}

  @impl true
  def mount(_params, session, socket) do
    user =
      case Map.get(session, "current_user_id") do
        nil -> nil
        id -> Repo.get(User, id)
      end

    {:ok, assign(socket, user: user)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10 max-w-xl mx-auto text-center">
      <%= if @user do %>
        <h1 class="text-3xl font-bold mb-3">Connected 🎉</h1>
        <p class="text-gray-700 mb-6">
          Authorized as <span class="font-semibold">@<%= @user.x_username %></span>.
        </p>
        <div class="flex gap-3 justify-center">
          <a href={~p"/tweets"} class="bg-blue-600 text-white px-4 py-2 rounded">View Tweets</a>
          <a href={~p"/generate"} class="bg-purple-600 text-white px-4 py-2 rounded">Generate</a>
        </div>

        <form action={~p"/auth/disconnect"} method="post" class="mt-8">
          <input type="hidden" name="_method" value="delete" />
          <button class="text-sm text-red-600 underline">Disconnect</button>
        </form>
      <% else %>
        <h1 class="text-2xl font-bold mb-3">No account found</h1>
        <p class="text-gray-600 mb-6">Please connect your X account.</p>
        <a href={~p"/connect"} class="bg-black text-white px-4 py-2 rounded">Connect X</a>
      <% end %>
    </div>
    """
  end
end
