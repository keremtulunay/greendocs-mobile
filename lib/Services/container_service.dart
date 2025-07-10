import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/container_item.dart';
import 'package:flutter/foundation.dart';

class ContainerService {
  Future<List<ContainerItem>> getContainers(String token) async {
    final response = await http.post(
      Uri.parse('https://greendocsweb.koda.com.tr:444/AjaxService.svc/GetLocations'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final items = (json['location'] as List)
          .map((e) => ContainerItem.fromJson(e))
          .toList();
      return items;
    } else {
      throw Exception('Failed to load containers: ${response.body}');
    }
  }

  Future<bool> saveContainer(ContainerItem container, String token) async {
    final response = await http.post(
      Uri.parse('https://greendocsweb.koda.com.tr:444/AjaxService.svc/SaveLocation'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token,
        'location': {
          'LocationId': container.locationId, // 👈 required for updates
          'Code': container.code,
          'ContainerTypeId': container.containerTypeId,
          'ParentId': container.parentId,
        }
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['id'] != null) {
        debugPrint("Container saved with id: ${json['id']}");
        return true;
      }
    }

    debugPrint("Failed to save container: ${response.body}");
    return false;
  }

  Future<bool> deleteContainer(int locationId, String token) async {
    debugPrint('Attempting to delete container with ID: $locationId');

    final response = await http.post(
      Uri.parse('https://greendocsweb.koda.com.tr:444/AjaxService.svc/DestroyContainerType'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token,
        'id': locationId,
      }),
    );

    debugPrint('Delete response: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['success'] == true || json['result'] == true;
    } else {
      debugPrint('Failed to delete: ${response.statusCode}');
      return false;
    }
  }
}