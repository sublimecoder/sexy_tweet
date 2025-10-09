defmodule SexyTweetWeb.PageController do
  use SexyTweetWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
