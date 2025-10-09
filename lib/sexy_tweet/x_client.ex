defmodule SexyTweet.XClient do
  @moduledoc """
  Minimal X.com API client using Req + OAuth 1.0a (signing omitted here).
  Fill in signing in `auth_headers/5`.
  """
  @base "https://api.x.com/2"

  # ===== Replace with a real OAuth1 header using OAuther =====
  defp auth_headers(_ck, _cs, _token, _secret, _method) do
    # e.g., [{"authorization", oauth_header_string}]
    []
  end

  def get_user_tweets(x_user_id, %{
        consumer_key: ck,
        consumer_secret: cs,
        access_token: t,
        access_secret: s
      }) do
    url = "#{@base}/users/#{x_user_id}/tweets?max_results=100"
    headers = auth_headers(ck, cs, t, s, :get)

    case Req.get(url: url, headers: [{"accept", "application/json"} | headers]) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok,
         Enum.map(data, fn %{"id" => id, "text" => text} ->
           %{id: id, text: text, metrics: %{}}
         end)}

      other ->
        {:error, other}
    end
  end

  def post_tweet(
        %{consumer_key: ck, consumer_secret: cs, access_token: t, access_secret: s},
        text
      ) do
    url = "#{@base}/tweets"
    headers = [{"content-type", "application/json"} | auth_headers(ck, cs, t, s, :post)]
    body = %{text: text}

    case Req.post(url: url, headers: headers, json: body) do
      {:ok, %{status: 201, body: %{"data" => %{"id" => id}}}} -> {:ok, id}
      other -> {:error, other}
    end
  end
end
