import 'dart:async';
import 'dart:convert' show Encoding, json;
import 'package:http/http.dart' as http;

class SendNotification {
  final postUrl = 'https://fcm.googleapis.com/fcm/send';

  Map<String, Object> createData(
      String title, String body, Object data, String token) {
    return {
      "notification": {"body": body, "title": title},
      "priority": "high",
      "data": data,
      "to": token
    };
  }

  Future<bool> send(Map<String, Object> data) async {
    final headers = {
      'content-type': 'application/json',
      'Authorization':
          'key=AAAAZAGsFXg:APA91bFTL-deIC251Af7ksScVQ38EiUJjG9C-LtAm0FUtUTTnzYs_zVv_ZCb12fmQ3It5yhUtZSmxkPoz3OnJmL2DBgGzdaA8weJidxzY7XUcSZoISSQW3GLEo6c68MfC9vAjU5-kfj5znMlKi-0meR1tiC7Pye2Rg'
    };

    final response = await http.post(postUrl,
        body: json.encode(data),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
