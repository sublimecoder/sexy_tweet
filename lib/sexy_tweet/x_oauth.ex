defmodule SexyTweet.XOAuth do
  @moduledoc """
  OAuth 1.0a dance for X/Twitter using OAuther + Req.
  Returns clean errors on non-200 responses and only decodes query strings on success.
  """

  # IMPORTANT: OAuth endpoints still commonly live on api.twitter.com
  # Switch back to api.x.com only if your app works there.
  @oauth_host "https://api.twitter.com"

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

    # We want raw body (string like "oauth_token=...&oauth_token_secret=...")
    case Req.post(url: @req_token_url, headers: [{key, val}], decode_body: false) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        {:ok, token_map} = decode_query_string(body)
        {:ok, token_map["oauth_token"], token_map["oauth_token_secret"]}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:req_error, reason}}
    end
  end

  def authorize_url(oauth_token),
    do: "#{@auth_url}?oauth_token=#{URI.encode(oauth_token)}"

  def access_token(oauth_token, oauth_verifier, req_token_secret) do
    {ck, cs} = consumer()

    params = [
      {"oauth_token", oauth_token},
      {"oauth_verifier", oauth_verifier}
    ]

    {:ok, {key, val}} =
      sign(:post, @access_url, params, ck, cs, oauth_token, req_token_secret)

    case Req.post(url: @access_url, headers: [{key, val}], decode_body: false) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        {:ok, m} = decode_query_string(body)

        {:ok,
         %{
           access_token: m["oauth_token"],
           access_secret: m["oauth_token_secret"],
           user_id: m["user_id"],
           screen_name: m["screen_name"]
         }}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, {:req_error, reason}}
    end
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

    # Returns OAuth param list
    auth_params = OAuther.sign(method_str, url, params, creds)

    # Returns {{key, value}, extra}
    {{key, value}, _extra} = OAuther.header(auth_params)

    {:ok, {key, value}}
  end

  defp decode_query_string(body) when is_binary(body) do
    # twitter returns form-encoded "k=v&k2=v2"
    {:ok, URI.decode_query(body)}
  rescue
    _ -> {:error, :bad_query_body}
  end
end
