import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controller/image_controller.dart';
import 'detail_screen.dart';

class ImageListScreen extends StatelessWidget {
  final ImageController controller = Get.put(ImageController());

    ImageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image List")),
      body: Obx(() {
        if (controller.isLoading.value && controller.images.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: controller.images.length + 1,
                itemBuilder: (context, index) {
                  if (index == controller.images.length) {
                    return controller.hasMore.value
                        ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: controller.fetchImages,
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text("Load More"),
                      ),
                    )
                        : Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: const Text("No more data!"),
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () {
                        Get.to(() => DetailScreen(image: controller.images[index]));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: controller.images[index].url,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(
                                child: Image.asset('assets/placeholder.webp'),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
