// personal assistant agent

broadcast(jason).

/* Initial goals */ 

// The agent has the goal to start
!start.

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: true (the plan is always applicable)
 * Body: greets the user
*/
@start_plan
+!start : true <-
    .print("Personal assistant starting...");
    .my_name(MyName);
    makeArtifact("mqttArtifactPA", "room.MQTTArtifact", [MyName], MQTTId);
    focus(MQTTId);
    .wait(2000);
    !send_mqtt("personal_assistant", tell, "Hello from personal assistant").

@message_plan
+message(Sender, tell, Content) : true <-
    .print("Lights manager received message from ", Sender, ": ", Content).

/*
 * Plan for sending an MQTT message.
 * Triggered by the goal !send_mqtt(Recipient,Performative,Content),
 * it invokes the artifact’s sendMsg operation.
 */
@send_mqtt_plan
+!send_mqtt(Sender, Performative, Content) : true <-
    .print("Sending MQTT message from ", Sender, " with content: ", Content);
    sendMsg(Sender, Performative, Content).

/*
 * Plan for selective broadcast.
 * Depending on the Mode, the agent either sends via MQTT or uses Jason’s broadcast.
 */
@selective_broadcast_plan
+!selective_broadcast(Mode, Recipient, Performative, Content) : Mode = "mqtt" <-
    !send_mqtt(Recipient, Performative, Content).

+!selective_broadcast(Mode, Recipient, Performative, Content) : Mode = "jason" <-
    .broadcast(Performative, Content);
    .print("Broadcasting via Jason: ", Content).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }