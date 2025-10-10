# lib/sexy_tweet_web/controllers/auth_controller.ex
defmodule SexyTweetWeb.AuthController do
  use SexyTweetWeb, :controller
  alias SexyTweet.{Repo, User}
  alias SexyTweet.XOAuth
  alias SexyTweet.Workers.TweetImporter

  # map: oauth_token => request_token_secret
  @session_key "x_req_token_secrets"

  def request(conn, _params) do
    callback = url(~p"/auth/x/callback")

    with {:ok, oauth_token, oauth_token_secret} <- XOAuth.request_token(callback) do
      conn
      |> put_req_secret(oauth_token, oauth_token_secret)
      |> redirect(external: XOAuth.authorize_url(oauth_token))
    else
      err ->
        conn
        |> put_flash(:error, "Could not start X authorization: #{inspect(err)}")
        |> redirect(to: ~p"/connect")
    end
  end

  def callback(conn, %{"oauth_token" => oauth_token, "oauth_verifier" => verifier}) do
    case pop_req_secret(conn, oauth_token) do
      {nil, conn} ->
        conn
        |> put_flash(:error, "Missing or expired OAuth request token.")
        |> redirect(to: ~p"/connect")

      {req_secret, conn} ->
        with {:ok, auth} <- XOAuth.access_token(oauth_token, verifier, req_secret) do
          attrs = %{
            x_user_id: auth.user_id,
            x_username: auth.screen_name,
            access_token: auth.access_token,
            access_secret: auth.access_secret
          }

          user =
            Repo.insert!(
              User.changeset(%User{}, attrs),
              on_conflict: [set: Map.to_list(Map.delete(attrs, :x_user_id))],
              conflict_target: :x_user_id
            )

          # Queue first import using your app's keys
          ck = System.get_env("X_CONSUMER_KEY")
          cs = System.get_env("X_CONSUMER_SECRET")

          Oban.insert!(
            TweetImporter.new(%{
              "user_id" => user.id,
              "consumer_key" => ck,
              "consumer_secret" => cs
            })
          )

          conn
          |> put_session(:current_user_id, user.id)
          |> put_flash(:info, "Connected to X as @#{user.x_username}")
          |> redirect(to: ~p"/connected")
        else
          err ->
            conn
            |> put_flash(:error, "Authorization failed: #{inspect(err)}")
            |> redirect(to: ~p"/connect")
        end
    end
  end

  def disconnect(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Disconnected.")
    |> redirect(to: ~p"/")
  end

  # --- session helpers for storing the request_token_secret keyed by oauth_token ---

  defp put_req_secret(conn, token, secret) do
    bag = get_session(conn, @session_key) || %{}
    put_session(conn, @session_key, Map.put(bag, token, secret))
  end

  defp pop_req_secret(conn, token) do
    bag = get_session(conn, @session_key) || %{}
    {Map.get(bag, token), put_session(conn, @session_key, Map.delete(bag, token))}
  end
end
