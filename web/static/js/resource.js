import {Socket} from "deps/phoenix/web/static/js/phoenix";
import React from "react"
import ReactDOM from 'react-dom'
import moment from "moment"
import _ from "lodash"

function isFutureEvent(event) { return moment().isBefore(event.start.dateTime) }
function durationToStart(event) { return moment.duration(moment(event.start.dateTime).diff(moment())) }
function durationToEnd(event) { return moment.duration(moment(event.end.dateTime).diff(moment())) }

function connectResource(id) {
  if (!window.authSocket) {
    window.authSocket = new Socket("/socket");
    window.authSocket.connect();
  }


  class EventList extends React.Component {
    constructor(props) {
      super(props);
      this.state = {
        events: [],
        isFullScreen: false,
        currentTime: moment().format("HH:mm:ss a")
      };
    }
    componentDidMount() {
      const token = $('meta[name="guardian_token"]').attr('content');
      window.channel = authSocket.channel(`authorized:resource:${id}`, {guardian_token: token});
      channel.join()
              .receive("ok", resp => {
                channel.push("eventsRequested")
              })
              .receive("error", resp => {
                socketTalk(resp.error);
              });

      channel.on("eventsFetched", data => {
        this.setState({events: data.events})
      });

      const socketTalk = (message, from) => {
      };
      document.onwebkitfullscreenchange = () => {
        this.setState({ isFullScreen: !this.state.isFullScreen })
      }
      this.timer = setInterval(() => {
        // this.props.requestCalendarSchedule(this.props.calendarId)
        this.setState({currentTime: moment().format("hh:mm:ss a")})
      }, 1000);
    }
    componentWillUnmount() {
      clearInterval(this.timer);
    }
    toggleFullscreen () {
      this.eventContainerDOM.webkitRequestFullscreen()
    }
    getMainEvent() {
      return _.chain(this.state.events)
        .reject((event) => moment(event.end.dateTime).isBefore(moment()))
        .first()
        .value()
    }

    renderAttendee (attendee) {
      return (
        <div key={attendee.email}>
          { attendee.displayName || attendee.email }
        </div>
        )
    }
    renderAttendees (event) {
      const attendees =
        event
          .attendees
          .filter((a) => !a.email.endsWith("resource.calendar.google.com"))
      return (
        <div className="attendees">
          <h5>Attendees ({ attendees.length }):</h5>
          { attendees.map(this.renderAttendee) }
        </div>
        )
    }
    renderMainEvent () {
      if (this.state.events.length == 0) return null
      const event = this.getMainEvent()
      let containerClassName = "mainEventContainer card card-with-background-image"
      if (this.state.isFullScreen) containerClassName += " fullscreen"

      if (!isFutureEvent(event)){
        containerClassName += " busy"
      }
      else if (durationToStart(event) > moment.duration(10, 'minutes')){
        containerClassName += " free"
      }
      else {
        containerClassName += " soonBusy"
      }
      return (
        <div>
          <button onClick={() => this.toggleFullscreen()}>Make Fullscreen</button>
          <div className={containerClassName} ref={(c) => this.eventContainerDOM = c }>
            <div className="card-background-image" style={{backgroundImage: "url(http://media1.popsugar-assets.com/files/thumbor/5B5qQbx9kzVt5rXGr8fceloRagQ/fit-in/2048xorig/filters:format_auto-!!-:strip_icc-!!-/2014/09/03/782/n/1922398/6d9cc7f66541e321_183667283_10/i/Jay-Z-Shawn-Corey-Carter.jpg)"}} />
            <div className="businessIndicatorOverlay" />
            <div className="card-header-time">
              { this.state.currentTime }
            </div>
            <div className="card-content">
              <div className="mainEventDetail">
                <h2> { event.summary }</h2>
                <h4> { moment(event.start.dateTime).format("HH:mm a") } - { moment(event.end.dateTime).format("HH:mm a") } </h4>
                <p> { event.description } </p>
                { this.renderAttendees(event) }
              </div>
              <div className="futureEvents">
                <h5>And theeen:</h5>
                <ul className="collection">
                  { this.state.events.map(this.renderEvent)}
                </ul>
              </div>
            </div>
            <footer><h5>{ window.resource.summary } </h5></footer>
          </div>
        </div>
        )
    }
    renderEvent(event) {
      return (
        <li className="collection-item" key={event.id}>
          <p> { moment(event.start.dateTime).format("HH:mm a") } - { moment(event.end.dateTime).format("HH:mm a") } </p>
          <h5 className="title">{ event.summary }</h5>
          <p> { event.description } </p>
        </li>
        )
    }
    render() {
      return (
        <div>
          { this.renderMainEvent() }
        </div>
        )
    }
  }

  ReactDOM.render(
    <EventList/>,
    document.getElementById("resourceContainer")
  )
}

export default connectResource;
