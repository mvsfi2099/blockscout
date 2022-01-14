defmodule Explorer.Repo.Migrations.AddRewardToAddressNames do
  use Ecto.Migration

  def change do
    alter table(:address_names) do
      add(:reward, :string)
    end
  end
end
