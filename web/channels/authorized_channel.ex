defmodule PhoenixGuardian.AuthorizedChannel do
  use PhoenixGuardian.Web, :channel
  use Guardian.Channel
  require Logger
  alias PhoenixGuardian.{ Repo, Resource }
  require IEx
  intercept ["eventsFetched"]

  def join("authorized:lobby", %{claims: claim, resource: resource}, socket) do
    {:ok, %{message: "Welcome #{resource.name}"}, socket}
  end

  def join("authorized:resource:" <> id, %{claims: claim, resource: resource}, socket) do
    {:ok, %{message: "Welcome #{resource.name}"}, socket}
  end

  # Deny joining the channel if the user isn't authenticated
  def join("authorized:lobby", _, socket) do
    {:error, %{error: "not authorized, are you logged in?"}}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, %{message: "pong"}}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (authorized:lobby).
  def handle_in("shout", payload, socket) do
    user = current_resource(socket)
    broadcast! socket, "shout", Map.put(payload, :from, user.name)
    {:noreply, socket}
  end

  def handle_in("eventsRequested", payload, %Phoenix.Socket{topic: "authorized:resource:" <> id} = socket) do
    user = current_resource(socket)
    Google.ResourceList.broadcast_events(user, Repo.get(Resource, id))
    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out("shout", payload, socket) do
    push socket, "shout", payload
    {:noreply, socket}
  end

  def handle_out("eventsFetched", payload, %Phoenix.Socket{topic: "authorized:resource:" <> id} = socket) do
    user = current_resource(socket)
    spawn fn ->
      Process.sleep(20000)
      Google.ResourceList.broadcast_events(user, Repo.get(Resource, id))
    end
    push socket, "eventsFetched", payload
    {:noreply, socket}
  end
end
