# lib/sexy_tweet/x_oauth.ex
defmodule SexyTweet.XOAuth do
  @moduledoc """
  OAuth 1.0a for X.com using OAuther + Req.
  """

  # change to https://api.twitter.com if needed
  @oauth_host "https://api.x.com"
  @req_token_url "#{@oauth_host}/oauth/request_token"
  @auth_url "#{@oauth_host}/oauth/authorize"
  @access_url "#{@oauth_host}/oauth/access_token"

  def consumer() do
    key = System.fetch_env!("X_CONSUMER_KEY")
    secret = System.fetch_env!("X_CONSUMER_SECRET")
    {key, secret}
  end

  def request_token(callback_url) do
    {ck, cs} = consumer()

    params = [{"oauth_callback", callback_url}]
    {:ok, {key, val}} = sign(:post, @req_token_url, params, ck, cs)

    {:ok, resp} =
      Req.post(url: @req_token_url, headers: [{key, val}])

    body = URI.decode_query(to_string(resp.body))
    {:ok, body["oauth_token"], body["oauth_token_secret"]}
  end

  def authorize_url(oauth_token),
    do: "#{@auth_url}?oauth_token=#{URI.encode(oauth_token)}"

  def access_token(oauth_token, oauth_verifier, req_token_secret) do
    {ck, cs} = consumer()

    params = [
      {"oauth_token", oauth_token},
      {"oauth_verifier", oauth_verifier}
    ]

    {:ok, {key, val}} = sign(:post, @access_url, params, ck, cs, oauth_token, req_token_secret)
    {:ok, resp} = Req.post(url: @access_url, headers: [{key, val}])

    body = URI.decode_query(to_string(resp.body))

    {:ok,
     %{
       access_token: body["oauth_token"],
       access_secret: body["oauth_token_secret"],
       user_id: body["user_id"],
       screen_name: body["screen_name"]
     }}
  end

  # ----- signing helpers -----
  defp sign(method, url, params, ck, cs, token \\ nil, token_secret \\ nil) do
    method_str =
      case method do
        m when is_atom(m) -> m |> Atom.to_string() |> String.upcase()
        m when is_binary(m) -> String.upcase(m)
      end

    creds =
      OAuther.credentials(
        consumer_key: ck,
        consumer_secret: cs,
        token: token,
        token_secret: token_secret
      )

    # OAuther.sign/4 returns the OAuth param list
    auth_params = OAuther.sign(method_str, url, params, creds)

    # OAuther.header/1 returns {{key, value}, extra}
    {{key, value}, _extra} = OAuther.header(auth_params)

    # Return a standard header tuple you can pass into Req
    {:ok, {key, value}}
  end
end
