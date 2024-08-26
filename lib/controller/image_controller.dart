import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/image_data.dart';

class ImageController extends GetxController {
  var images = <ImageData>[].obs;
  var isLoading = false.obs;
  var hasMore = true.obs;
  var isSubmitting = false.obs;
  int offset = 0;

  @override
  void onInit() {
    fetchImages();
    super.onInit();
  }

  void fetchImages() async {
    if (!hasMore.value || isLoading.value) return;

    isLoading(true);

    final response = await http.post(
      Uri.parse('http://dev3.xicomtechnologies.com/xttest/getdata.php'),
      body: {
        'user_id': '108',
        'offset': offset.toString(),
        'type': 'popular',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['images'];
      List<ImageData> newImages = data.map((imageJson) {
        return ImageData.fromJson(imageJson);
      }).toList();

      images.addAll(newImages);
      isLoading(false);

      if (newImages.isEmpty) {
        hasMore(false);
      } else {
        offset += newImages.length;
      }
    } else {
      isLoading(false);
      hasMore(false);
    }
  }

  Future<void> submitForm({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required ImageData image,
  }) async {
    isSubmitting(true);

    final uri = Uri.parse('http://dev3.xicomtechnologies.com/xttest/savedata.php');
    final request = http.MultipartRequest('POST', uri);

    request.fields['first_name'] = firstName;
    request.fields['last_name'] = lastName;
    request.fields['email'] = email;
    request.fields['phone'] = phone;

    final response = await http.get(Uri.parse(image.url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      request.files.add(
        http.MultipartFile.fromBytes(
          'user_image',
          bytes,
          filename: 'image_${image.id}.jpg',
        ),
      );
    }

    final responseStream = await request.send();
    isSubmitting(false);

    if (responseStream.statusCode == 200) {
      Get.snackbar("Success", "Data submitted successfully!",
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar("Error", "Failed to submit data",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
