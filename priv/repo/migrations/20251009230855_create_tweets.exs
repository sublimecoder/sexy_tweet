defmodule SexyTweet.Repo.Migrations.CreateTweets do
  use Ecto.Migration

  def change do
    create table(:tweets) do
      add :x_tweet_id, :string
      add :text, :text
      add :metrics, :map
      add :score, :float
      add :imported_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:tweets, [:user_id])
  end
end
