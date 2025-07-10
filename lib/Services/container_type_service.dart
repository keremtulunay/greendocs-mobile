  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import '../Models/container_type.dart';
  import 'package:flutter/foundation.dart';

import 'container_service.dart';
  class ContainerTypeService {
    final String baseUrl;
    final ContainerService _containerService = ContainerService();
    ContainerTypeService(this.baseUrl);

    Future<List<ContainerType>> getContainerTypes(String token) async {
      final response = await http.post(
        Uri.parse('$baseUrl/AjaxService.svc/GetContainerTypes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
        }),
      );
      var responsebody = response.body;
      print('Raw container types response: $responsebody');
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded['status'] == 'OK') {
          final List<dynamic> rawList = decoded['containerType'];

          for (var item in rawList) {
            if (item['Name'] == null || item['Width'] == null) {
              print('⚠️ Null row: $item');
            }
          }
          return rawList.map((item) => ContainerType.fromJson(item)).toList();
        } else {
          throw Exception('API returned error: ${decoded['status']}');
        }
        final data = decoded['d'] ?? decoded; // support for WCF-style wrapping

        return List<ContainerType>.from(
          data.map((e) => ContainerType.fromJson(e)),
        );
      } else {
        throw Exception('Failed to load container types: ${response.statusCode}');
      }
    }
    Future<bool> deleteContainerType(int id, String authToken) async {
      final url = Uri.parse('$baseUrl/AjaxService.svc/DestroyContainerType');

      final requestBody = {
        "id": id,
        "token": authToken,
      };

      debugPrint('Sending DestroyContainerType request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return true;
        } else {
          debugPrint('Delete failed: ${response.body}');
          return false;
        }
      } else {
        debugPrint('Delete request error: ${response.body}');
        return false;
      }
    }

    Future<bool> saveContainerType(ContainerType type, String authToken) async {
      final url = Uri.parse('$baseUrl/AjaxService.svc/SaveContainerType');

      final requestBody = {
        "containerType": {
          "ContainerTypeId": type.id ?? 0, // use 0 if null (for new types)
          "Name": type.name,
          "Width": type.width,
          "Height": type.height,
          "Length": type.depth, // must be 'Length'
        },
        "token": authToken,
      };

      debugPrint('Sending SaveContainerType request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'OK';
      } else {
        return false;
      }
    }
  }
