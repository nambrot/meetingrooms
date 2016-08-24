defmodule PhoenixGuardian.Resource do
  use PhoenixGuardian.Web, :model

  schema "resources" do
    field :gid, :string
    field :summary, :string
    field :description, :string

    belongs_to :user, PhoenixGuardian.User
    timestamps
  end

  @required_fields ~w(gid summary description)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
