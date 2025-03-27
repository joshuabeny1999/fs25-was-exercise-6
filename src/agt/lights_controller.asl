// lights controller agent

/* Initial beliefs */

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights (was:Lights)
td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/lights.ttl").

// The agent initially believes that the lights are "off"
lights("off").

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agents believes that a WoT TD of a was:Lights is located at Url
 * Body: greets the user
*/
@start_plan
+!start : td("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#Lights", Url) <-
    .print("Lights controller starting...");
    makeArtifact("lights", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], ArtId);
    .my_name(MyName);
    makeArtifact("mqttArtifactL", "room.MQTTArtifact", [MyName], MQTTId);
    focus(MQTTId).

@message_plan
+message(Sender, "tell", Content) : true <-
    .print("Lights manager received message from ", Sender, ": ", Content).

/* 
 * Plan for turning on the lights.
 * Triggered by the goal !turn__lights_on.
 * Context: true.
 * Body: the agent invokes the action affordance was:SetState with input "on".
 *       It prints the response and updates its belief.
 */
@turn_on_plan
+!turn_lights_on : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", ["on"]);
    .print("Lights turned on");
    -+lights("off");
    +lights("on");
    .send("personal_assistant", tell, lights("on")).


 /* 
 * Plan for turning off the lights.
 * Triggered by the goal !turn_lights_off.
 * Context: true.
 * Body: the agent invokes the action affordance was:SetState with input "off".
 *       It prints the response and updates its belief.
 */
@turn_off_plan
+!turn_lights_off : true <-
    invokeAction("https://was-course.interactions.ics.unisg.ch/wake-up-ontology#SetState", ["off"]);
    .print("Lights turned off");
    -+lights("on");
    +lights("off");
    .send("personal_assistant", tell, lights("off")).


/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }