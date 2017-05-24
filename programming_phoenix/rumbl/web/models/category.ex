defmodule Rumbl.Category do
  use Rumbl.Web, :model

  schema "categories" do
    field :name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
    |> foreign_key_constraint(:videos, name: :videos_category_id_fkey, message: "still exist")
    |> unique_constraint(:name)
  end

  def alphabetical(query) do
    from c in query, order_by: [asc: c.name]
  end

  def names_and_ids(query) do
    from c in query, select: { c.name, c.id }
  end
end
