// DIP
import 'package:grass_app/utils/database.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter/material.dart';
import 'package:grass_app/utils/settings.dart';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:grass_app/common.dart';
import 'package:grass_app/models/server.dart';

import 'package:grass_app/utils/authority.dart';

import 'dart:async';

@singleton
class AppMqttTransactions {
  final DatabaseService _db;
  AppMqttTransactions(this._db);
  Stream<String> temperatureStream, lightStream, moistureStream;
  StreamSubscription tempLoggingSubscription,
      lightLoggingSubscription,
      moistureLoggingSubscription;
  Stream<bool> relayStream, ledStream, servoStream;
  Map<String, MqttServerClient> topicToClient =
      Map<String, MqttServerClient>(); // topic to client
  bool loggedIn = false;

  // Implemented like this such that if there are multiple messages of the same topic,
  // the latest one would supersede earlier ones, eliminating pointless on-off pairs
  // and duplicates.
  // Maps from full topic URL to backlogged data.
  Map<String, String> topicBacklogs = Map<String, String>();

  // Pass topic without the name/feeds/ part, that is, only 'bk-iot-light' for example.
  Stream<T> _buildTopicStream<T>(String shortTopic, T Function(String) parser) {
    MqttServerClient srcClient = topicToClient[shortTopic];
    Stream<List<MqttReceivedMessage<MqttMessage>>> mqttStream =
        srcClient.updates;
    String fullTopic =
        srcClient.connectionMessage.payload.username + '/feeds/' + shortTopic;
    // Wait until a new MQTT message is available
    return mqttStream
        .where((List<MqttReceivedMessage<MqttMessage>> lst) =>
            lst[0].topic == fullTopic)
        .map((List<MqttReceivedMessage<MqttMessage>> lst) {
      final MqttPublishMessage recMess = lst[0].payload;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      return parser(pt);
    });
  }

  // This is only done once all servers have been created and all devices have had its id matched.
  // @return  0: successful
  //          1: unable to connect
  //          2: remote authentication failure
  //          3: internal error
  Future<int> subscribeTopics() async {
    // Set status as intentionally logged in, such that any disconnection
    // will result in a reconnection attempt.
    this.loggedIn = true;
    // Set active profile
    // Server id to corresponding client, used to avoid duplicate connections to the same server.
    Map<int, MqttServerClient> serverToClient = Map<int, MqttServerClient>();

    // Connect to each of the specified servers of this profile
    Map<int, ServerRecord> userServers =
        await _db.getServersOfUser(Authority.currentProfile.name);
    // Light
    if (!serverToClient.containsKey(Authority.currentProfile.lightId)) {
      ServerRecord lightServer = userServers[Authority.currentProfile.lightId];
      List lightResult = await _login(lightServer);
      if (lightResult.last != 0) return lightResult.last;
      serverToClient[Authority.currentProfile.lightId] = lightResult.first;
      topicToClient['bk-iot-light'] = lightResult.first;
    } else {
      topicToClient['bk-iot-light'] =
          serverToClient[Authority.currentProfile.lightId];
    }
    // Light
    if (!serverToClient.containsKey(Authority.currentProfile.soilId)) {
      ServerRecord soilServer = userServers[Authority.currentProfile.soilId];
      List soilResult = await _login(soilServer);
      if (soilResult.last != 0) return soilResult.last;
      serverToClient[Authority.currentProfile.soilId] = soilResult.first;
      topicToClient['bk-iot-soil'] = soilResult.first;
    } else {
      topicToClient['bk-iot-soil'] =
          serverToClient[Authority.currentProfile.soilId];
    }
    // Temperature
    if (!serverToClient.containsKey(Authority.currentProfile.tempId)) {
      ServerRecord tempServer = userServers[Authority.currentProfile.tempId];
      List tempResult = await _login(tempServer);
      if (tempResult.last != 0) return tempResult.last;
      serverToClient[Authority.currentProfile.tempId] = tempResult.first;
      topicToClient['bk-iot-temp-humid'] = tempResult.first;
    } else {
      topicToClient['bk-iot-temp-humid'] =
          serverToClient[Authority.currentProfile.tempId];
    }
    // LED
    if (!serverToClient.containsKey(Authority.currentProfile.ledId)) {
      ServerRecord ledServer = userServers[Authority.currentProfile.ledId];
      List ledResult = await _login(ledServer);
      if (ledResult.last != 0) return ledResult.last;
      serverToClient[Authority.currentProfile.ledId] = ledResult.first;
      topicToClient['bk-iot-led'] = ledResult.first;
    } else {
      topicToClient['bk-iot-led'] =
          serverToClient[Authority.currentProfile.ledId];
    }
    // Relay
    if (!serverToClient.containsKey(Authority.currentProfile.relayId)) {
      ServerRecord relayServer = userServers[Authority.currentProfile.relayId];
      List relayResult = await _login(relayServer);
      if (relayResult.last != 0) return relayResult.last;
      serverToClient[Authority.currentProfile.relayId] = relayResult.first;
      topicToClient['bk-iot-relay'] = relayResult.first;
    } else {
      topicToClient['bk-iot-relay'] =
          serverToClient[Authority.currentProfile.relayId];
    }
    // Servo
    if (!serverToClient.containsKey(Authority.currentProfile.servoId)) {
      ServerRecord servoServer = userServers[Authority.currentProfile.servoId];
      List servoResult = await _login(servoServer);
      if (servoResult.last != 0) return servoResult.last;
      serverToClient[Authority.currentProfile.servoId] = servoResult.first;
      topicToClient['bk-iot-servo'] = servoResult.first;
    } else {
      topicToClient['bk-iot-servo'] =
          serverToClient[Authority.currentProfile.servoId];
    }

    // Connect and login
    List<String> deviceTopics = topicToClient.keys.toList();
    for (int i = 0; i < deviceTopics.length; i++) {
      int result = await subscribe(deviceTopics[i]);
      // Terminate early if error
      if (result != 0) return result;
    }

    // Now initialise our local feeds as streams
    this.temperatureStream =
        _buildTopicStream('bk-iot-temp-humid', (String jsonStr) {
      final json = jsonDecode(jsonStr);
      return json['data'].split('-')[0];
    });
    this.lightStream = _buildTopicStream('bk-iot-light', (String jsonStr) {
      final json = jsonDecode(jsonStr);
      return json['data'];
    });
    this.moistureStream = _buildTopicStream('bk-iot-soil', (String jsonStr) {
      final json = jsonDecode(jsonStr);
      return json['data'];
    });
    this.relayStream = _buildTopicStream('bk-iot-relay', (String jsonStr) {
      final json = jsonDecode(jsonStr);
      final String data = json['data'];
      return data == '1';
    });
    this.ledStream = _buildTopicStream('bk-iot-led', (String jsonStr) {
      final json = jsonDecode(jsonStr);
      final String data = json['data'];
      return data == '1';
    });
    this.servoStream = _buildTopicStream('bk-iot-servo', (String jsonStr) {
      final json = jsonDecode(jsonStr);
      final String data = json['data'];
      return data == '180';
    });

    // Now we can add listeners to these streams
    tempLoggingSubscription = this.temperatureStream.listen(_onTemperatureRecv);
    lightLoggingSubscription = this.lightStream.listen(_onLightRecv);
    moistureLoggingSubscription = this.moistureStream.listen(_onMoistureRecv);

    // Everything's good
    return 0;
  }

  void _onTemperatureRecv(String data) async {
    ProfileSettings.set('temperature-last-measurement', int.parse(data));
  }

  void _onLightRecv(String data) async {
    ProfileSettings.set('lighting-last-measurement', int.parse(data));
  }

  void _onMoistureRecv(String data) async {
    ProfileSettings.set('irrigation-last-measurement', int.parse(data));
  }

  Future<int> subscribe(String shortTopic) async {
    // unsolicited disconnection callback
    final MqttServerClient client = topicToClient[shortTopic];
    final String fullTopic =
        client.connectionMessage.payload.username + '/feeds/' + shortTopic;
    // onSubscribe callback
    client.onSubscribed = (String topicURL) {
      // Check if we have anything backlogged
      final List<String> backloggedTopics = topicBacklogs.keys.toList();
      for (int i = 0; i < backloggedTopics.length; ++i) {
        final String username = backloggedTopics[i].split('/').first;
        if (username == client.connectionMessage.payload.username) {
          // It's for us - publish now
          // Remove from map - it's ok because if we still fail, publish() will put it back in.
          topicBacklogs.remove(backloggedTopics[i]);
          publish(backloggedTopics[i], topicBacklogs[backloggedTopics[i]]);
        }
      }
    };

    client.subscribe(fullTopic, MqttQos.atMostOnce);
    return 0;
  }

  void logout() {
    // Set status as intentionally logged out, such that disconnections won't trigger
    // spurious reconnection callbacks.
    this.loggedIn = false;
    // Unsubscribe loggers from streams first
    if (tempLoggingSubscription != null) {
      tempLoggingSubscription.cancel();
    }
    if (lightLoggingSubscription != null) {
      lightLoggingSubscription.cancel();
    }
    if (moistureLoggingSubscription != null) {
      moistureLoggingSubscription.cancel();
    }
    // Then unsubscribe topics
    for (String topic in SubscribingTopics + PublishingTopics) {
      topicToClient[topic].unsubscribe(topic);
    }
    // Disconnect servers later
    topicToClient.forEach((topic, client) => client.disconnect());
  }

  // login to MQTT broker
  // @return  0: successful
  //          1: unable to connect
  //          2: remote authentication failure
  Future<List> _login(ServerRecord server) async {
    MqttServerClient client =
        MqttServerClient(server.address, 'GRASS_${server.username}');
    // Connection sample process (https://github.com/shamblett/mqtt_client/blob/master/example/mqtt_server_client.dart)
    // Turn on mqtt package's logging while in test.
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.keepAlivePeriod = 60;
    final MqttConnectMessage connMess = MqttConnectMessage()
        .authenticateAs(server.username, server.apikey)
        .withClientIdentifier('GRASS_${server.username}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    // Connection verification
    try {
      await client.connect();
    } on Exception catch (e) {
      return <dynamic>[client, 2];
    }

    /// Check if we are connected
    if (client.connectionStatus.state == MqttConnectionState.connected) {
    } else {
      /// Use status here rather than state if you also want the broker
      /// return code.
      client.disconnect();
      return [client, 1];
    }
    return [client, 0];
  }

  // Publish to a topic
  Future<String> publish(String topicURL, String value) async {
    // Connect to the client if we haven't already
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    String topic = topicURL.split('/').last;
    String jsonStr = jsonEncode({
      'id': deviceMap[topicURL]['id'],
      'name': deviceMap[topicURL]['name'],
      'data': value,
      'unit': deviceMap[topicURL]['unit']
    });
    builder.addString(jsonStr);
    MqttServerClient client = topicToClient[topic];
    try {
      client.publishMessage(
          client.connectionMessage.payload.username + topicURL,
          MqttQos.atMostOnce,
          builder.payload);
      return jsonStr;
    } catch (exception) {
      // Backlog this publish till the next time the client reconnects.
      topicBacklogs[topicURL] = value;
      return '{}';
    }
  }
}
