defmodule SexyTweet.Tweet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tweets" do
    field :x_tweet_id, :string
    field :text, :string
    field :metrics, :map, default: %{}
    field :score, :float
    field :imported_at, :utc_datetime

    belongs_to :user, SexyTweet.User
    timestamps()
  end

  def changeset(tweet, attrs) do
    tweet
    |> cast(attrs, [:x_tweet_id, :text, :metrics, :score, :imported_at, :user_id])
    |> validate_required([:x_tweet_id, :text, :user_id])
    |> unique_constraint(:x_tweet_id)
  end
end
