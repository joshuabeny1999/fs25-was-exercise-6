// calendar manager agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService (was:CalendarService)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/calendar-service.ttl").

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:CalendarService is located at Url
 * Body: greets the user
*/
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#CalendarService", Url) <-
    .print("Calendar manager starting...");
    // Create a ThingArtifact for the calendar service using the TD URL
    makeArtifact("calendar", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], ArtId);
    .wait(5000);
    !read_upcoming_event.

/* 
 * Plan for reading the upcoming event.
 * Triggering event: addition of goal !read_upcoming_event.
 * Context: true.
 * Body: every 5000ms, the agent reads the property affordance was:ReadUpcomingEvent (which returns a list of event values),
 *       extracts the first element (e.g., "now"), prints it, and then re-creates the goal.
 */
@read_upcoming_event_plan
+!read_upcoming_event : true <-
    readProperty("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#ReadUpcomingEvent", EventList);
    .nth(0, EventList, Event);
    .print("Upcoming event: ", Event);
    .send("personal_assistant", tell, upcoming_event(Event));
    .wait(60000);
    !read_upcoming_event.

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }
