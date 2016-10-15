defmodule PhoenixGuardian.ResourceController do
  use PhoenixGuardian.Web, :controller
  use Guardian.Phoenix.Controller
  alias PhoenixGuardian.{ Repo, Resource }
  alias Phoenix.Controller
  require Logger

  plug :scrub_params, "resource" when action in [:create, :update]

  def index(conn, _params, current_user, _claims) do
    try do
      resources = Google.ResourceList.all(current_user)
      render(conn, "index.html", current_user: current_user, resources: resources)
    rescue
      MatchError ->
        Phonix.Controller.put_flash(:error, "Match Error, probably refresh token is not there")
        render(conn, "index.html", current_user: current_user, resources: [])
    end
  end

  def new(conn, _params, current_user, _claims) do
    changeset = Resource.changeset(%Resource{})
    render(conn, "new.html", changeset: changeset, current_user: current_user)
  end

  def create(conn, %{"resource" => resource_params}, current_user, _claims) do
    changeset = Resource.changeset(%Resource{}, resource_params)

    case Repo.insert(changeset) do
      {:ok, _resource} ->
        conn
        |> put_flash(:info, "Resource created successfully.")
        |> redirect(to: resource_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, current_user: current_user)
    end
  end

  def show(conn, %{"id" => id}, current_user, _claims) do
    resource = current_user |> Ecto.Model.assoc(:resources) |> Repo.get!(id)
    render(conn, "show.html", resource: resource, current_user: current_user)
  end

  def edit(conn, %{"id" => id}, current_user, _claims) do
    resource = Repo.get!(Resource, id)
    changeset = Resource.changeset(resource)
    render(conn, "edit.html", resource: resource, changeset: changeset, current_user: current_user)
  end

  def update(conn, %{"id" => id, "resource" => resource_params}, current_user, _claims) do
    resource = Repo.get!(Resource, id)
    changeset = Resource.changeset(resource, resource_params)

    case Repo.update(changeset) do
      {:ok, resource} ->
        conn
        |> put_flash(:info, "Resource updated successfully.")
        |> redirect(to: resource_path(conn, :show, resource))
      {:error, changeset} ->
        render(conn, "edit.html", resource: resource, changeset: changeset, current_user: current_user)
    end
  end

  def delete(conn, %{"id" => id}, current_user, _claims) do
    resource = Repo.get!(Resource, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(resource)

    conn
    |> put_flash(:info, "Resource deleted successfully.")
    |> redirect(to: resource_path(conn, :index))
  end

  def rebroadcast(conn, %{"resource_id" => id}, current_user, _claims) do
    Google.ResourceList.broadcast_events(Repo.get(Resource, id))
    text conn, ""
  end
end
