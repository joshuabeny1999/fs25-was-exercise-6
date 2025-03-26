package room;

import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import org.eclipse.paho.client.mqttv3.*;

/**
 * A CArtAgO artifact that provides an operation for sending messages to agents
 * with KQML performatives using the dweet.io API
 */
public class MQTTArtifact extends Artifact {

    MqttClient client;
    String broker = "tcp://test.mosquitto.org:1883";
    String clientId;
    String topic = "was-exercise-6/communication-joshuah";
    int qos = 2;

    public void init(String name) {
        try {
            clientId = name;
            client = new MqttClient(broker, clientId);
            client.setCallback(new MQTTCallbackImpl());
            MqttConnectOptions options = new MqttConnectOptions();
            options.setCleanSession(true);
            client.connect(options);
            client.subscribe(topic, qos);
            System.out.println("Connected as " + clientId + " and subscribed to topic: " + topic);
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    @OPERATION
    public void sendMsg(String agent, String performative, String content) {
        try {
            String fullMessage = agent + "," + performative + "," + content;
            MqttMessage message = new MqttMessage(fullMessage.getBytes());
            message.setQos(qos);
            client.publish(topic, message);
            System.out.println("Message published: " + fullMessage);
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    @INTERNAL_OPERATION
    public void addMessage(String agent, String performative, String content) {
        defineObsProperty("message", agent, performative, content);
        System.out.println("Observable property created: " + agent + "," + performative + "," + content);
    }

    // Custom callback class for handling incoming MQTT messages.
    private class MQTTCallbackImpl implements MqttCallback {

        @Override
        public void connectionLost(Throwable cause) {
            System.err.println("MQTT connection lost: " + cause.getMessage());
        }

        @Override
        public void messageArrived(String topic, MqttMessage message) throws Exception {
            String payload = new String(message.getPayload());
            // Expecting payload in format: "sender_agent,performative,content"
            String[] parts = payload.split(",", 3); // limit to three parts
            if (parts.length == 3) {
                String sender = parts[0].trim();
                String performative = parts[1].trim();
                String content = parts[2].trim();
                // Only process messages with the "tell" performative.
                if ("tell".equalsIgnoreCase(performative)) {
                    // Create an observable property by calling an internal operation.
                    execInternalOp("addMessage", sender, performative, content);
                }
            }
        }

        @Override
        public void deliveryComplete(IMqttDeliveryToken token) {
            // This callback confirms that a message published by this client was delivered.
        }
    }
}
