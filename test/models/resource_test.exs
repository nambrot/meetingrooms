defmodule PhoenixGuardian.ResourceTest do
  use PhoenixGuardian.ModelCase

  alias PhoenixGuardian.Resource

  @valid_attrs %{description: "some content", gid: "some content", summary: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Resource.changeset(%Resource{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Resource.changeset(%Resource{}, @invalid_attrs)
    refute changeset.valid?
  end
end
