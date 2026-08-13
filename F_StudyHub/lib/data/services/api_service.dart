import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../models/room_model.dart';

class ApiService {
  const ApiService();

  Future<Room> createRoom({required String name, required String hostId}) async {
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/api/rooms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'hostId': hostId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear la sala: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Room.fromJson(json);
  }

  Future<Room> getRoom(String roomId) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/api/rooms/${Uri.encodeComponent(roomId)}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener la sala: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Room.fromJson(json);
  }
}