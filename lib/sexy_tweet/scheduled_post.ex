defmodule SexyTweet.ScheduledPost do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scheduled_posts" do
    field :text, :string
    field :scheduled_for, :utc_datetime
    field :status, :string, default: "draft"

    belongs_to :user, SexyTweet.User
    timestamps()
  end

  def changeset(sp, attrs) do
    sp
    |> cast(attrs, [:text, :scheduled_for, :status, :user_id])
    |> validate_required([:text, :scheduled_for, :user_id])
  end
end
