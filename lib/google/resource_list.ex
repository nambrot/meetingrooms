defmodule Google.ResourceList do
  use GenServer
  require IEx
  require Logger
  alias PhoenixGuardian.{Repo, User, Resource, Authorization}
  alias Ueberauth.Strategy.Google.OAuth
  @doc """
  Starts the registry.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def all(user) do
    case user
      |> access_token
      |> OAuth2.AccessToken.get("https://www.googleapis.com/calendar/v3/users/me/calendarList")
    do
      {:ok, res} ->
        res.body["items"]
          |> Enum.filter(&(String.ends_with?(&1["id"], "resource.calendar.google.com")))
          |> Enum.map(&(find_or_create(&1, user)))
    end
  end

  def find_or_create(item, user) do
    {_, model} = case Repo.get_by(Resource, gid: item["id"]) do
      nil -> Ecto.build_assoc(user, :resources, %{gid: item["id"]})
      post -> post
    end
    |> Resource.changeset(%{summary: item["summary"], description: item["description"]})
    |> Repo.insert_or_update

    model
  end

  # {
  #                 timeMin: moment().subtract(2, 'hours').toISOString(),
  #                 timeMax: moment().add(5, 'days').toISOString(),
  #                 singleEvents: true,
  #                 orderBy: 'startTime'
  #               }
  def broadcast_events(user, resource) do
     {:ok, res} = Repo.get(User, resource.user_id)
     |> access_token
     |> OAuth2.AccessToken.get(
          "https://www.googleapis.com/calendar/v3/calendars/#{resource.gid}/events",
          [],
          [
            params: %{
              timeMin: Timex.now |> Timex.shift(hours: -2) |> Timex.format!("{ISO:Extended}"),
              timeMax: Timex.now |> Timex.shift(days: 2) |> Timex.format!("{ISO:Extended}"),
              singleEvents: true,
              orderBy: "startTime"
            }
          ])

    PhoenixGuardian.Endpoint.broadcast! "authorized:resource:#{resource.id}", "eventsFetched", %{events: res.body["items"] }
  end

  def access_token(user) do
    authorization = user |> Ecto.assoc(:authorizations) |> Repo.get_by(provider: "google") |> potentially_refresh_authorization

    OAuth2.AccessToken.new(authorization.token, Ueberauth.Strategy.Google.OAuth.client)
  end

  def potentially_refresh_authorization(authorization) do
    if (authorization.expires_at |> Timex.from_unix |> Timex.before?(Timex.now)) do
      {:ok, access_token} = OAuth2
            .AccessToken
            .refresh(%{
              refresh_token: authorization.refresh_token,
              client: Ueberauth.Strategy.Google.OAuth.client})

      case authorization |> Authorization.update(%{
            token: access_token.access_token,
            expires_at: access_token.expires_at}) |> Repo.update do
        {:ok, update_authorization} -> update_authorization
        {:error, error} -> Logger.debug(error)
      end
    else
      authorization
    end
  end

  @doc """
  Ensures there is a bucket associated to the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  def handle_cast({:create, name}, names) do
    {:noreply, Map.put(names, name, name) }
  end
end
