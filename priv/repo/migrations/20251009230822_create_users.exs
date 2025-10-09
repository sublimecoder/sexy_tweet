defmodule SexyTweet.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :x_user_id, :string
      add :x_username, :string
      add :access_token, :string
      add :access_secret, :string

      timestamps(type: :utc_datetime)
    end
  end
end
