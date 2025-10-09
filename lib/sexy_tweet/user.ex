defmodule SexyTweet.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :x_user_id, :string
    field :x_username, :string
    field :access_token, :string
    field :access_secret, :string

    has_many :tweets, SexyTweet.Tweet
    has_many :scheduled_posts, SexyTweet.ScheduledPost

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:x_user_id, :x_username, :access_token, :access_secret])
    |> validate_required([:x_user_id, :x_username, :access_token, :access_secret])
    |> unique_constraint(:x_user_id)
  end
end
