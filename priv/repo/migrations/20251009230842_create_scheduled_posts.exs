defmodule SexyTweet.Repo.Migrations.CreateScheduledPosts do
  use Ecto.Migration

  def change do
    create table(:scheduled_posts) do
      add :text, :text
      add :scheduled_for, :utc_datetime
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:scheduled_posts, [:user_id])
  end
end
