// personal assistant agent

broadcast(mqtt).
owner_awake :- owner_state("awake").
owner_asleep :- owner_state("asleep").

best_option(Option) 
    :- 
        wake_up_ranking(Option, Rank)
        & not lower_ranking_exists(Rank)
        & not used_method(Option)
    .

lower_ranking_exists(Rank) 
    :-
        wake_up_ranking(_, LowerRank)
        & LowerRank < Rank
        & not used_method(_)
    .
    
// Beliefs
wake_up_ranking(natural_light, 0).
wake_up_ranking(artificial_light, 1).

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
    focus(MQTTId).


@message_plan
+message(Sender, tell, Content) : true <-
    .print("Personal Assistant received message from ", Sender, ": ", Content).

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
+!selective_broadcast(Sender, Performative, Content) : broadcast(mqtt) <-
    !send_mqtt(Sender, Performative, Content).

+!selective_broadcast(Sender, Performative, Content) : broadcast(jason) <-
    .broadcast(Performative, Content);
    .print("Broadcasting via Jason: ", Content).

@handle_upcoming_event_awake_plan
+upcoming_event("now")
    : owner_awake
    <-
        .print("Enjoy your event");
    .

@handle_upcoming_event_asleep_plan
+upcoming_event("now")
    : owner_asleep
    <-
    .print("Starting wake-up routine");
    !initiate_cfp.

@initiate_cfp_plan_owner_asleep
+!initiate_cfp : owner_asleep <-
    .print("Broadcasting CFP for wake-up task");
    !selective_broadcast("personal_assistant", tell, cfp(wake_up("increase illuminance")));
    .wait(5000);
    !process_proposals.

@initiate_cfp_plan_owner_awake
+!initiate_cfp : owner_awake <-
    .print("Goal Reached: Owner is now awake; no need to initiate CFP");
    -used_method(natural_light);
    -used_method(artificial_light).


@process_proposals_plan_natural_light
+!process_proposals : best_option(natural_light) & proposal(Agent, proposal(natural_light, _)) <-
    .send(Agent, tell, "accept_proposal(natural_light)");
    +used_method(natural_light);
    .wait(2000);
    !initiate_cfp.

@process_proposals_plan_artifical_light
+!process_proposals : best_option(artificial_light) & proposal(Agent, proposal(artifical_light, _)) <-
    .send(Agent, tell, "accept_proposal(artifical_light)");
    +used_method(natural_light);
    .wait(2000);
    !initiate_cfp.

@process_proposals_plan_no_proposal_everything_tried
+!process_proposals : not proposal(_, _) & used_method(natural_light) & used_method(artifical_light) <-
    .print("No proposals received; delegating wake-up to a friend");
    !send_mqtt("friend", achieve, wake_up("please wake up our user")).

@process_proposals_plan_no_proposal
+!process_proposals : not proposal(_, _) <-
    .print("No proposals received; trying again asking for proposals");
    !initiate_cfp.


/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }


