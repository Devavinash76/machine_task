import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../model/image_data.dart';

class DetailScreen extends StatefulWidget {
  final ImageData image;

  const DetailScreen({super.key, required this.image});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final RegExp _emailRegExp = RegExp(
    r'^[^@]+@[^@]+\.[^@]+$',
  );

  final RegExp _phoneRegExp = RegExp(
    r'^\d{10}$', // Ensure exactly 10 digits
  );

  final _isLoading = false.obs; // Using GetX to manage loading state

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() == true) {
      _isLoading.value = true; // Show loading indicator

      final uri =
          Uri.parse('http://dev3.xicomtechnologies.com/xttest/savedata.php');
      final request = http.MultipartRequest('POST', uri);

      request.fields['first_name'] = _firstNameController.text;
      request.fields['last_name'] = _lastNameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['phone'] = _phoneController.text;

      // Fetch the image from the network
      final response = await http.get(Uri.parse(widget.image.url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        request.files.add(
          http.MultipartFile.fromBytes(
            'user_image',
            bytes,
            filename: 'image_${widget.image.id}.jpg',
          ),
        );
      }

      final responseStream = await request.send();
      _isLoading.value = false; // Hide loading indicator

      if (responseStream.statusCode == 200) {
        // Clear all text fields
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();

        _showSnackBar("Data submitted successfully!", Colors.green);
      } else {
        _showSnackBar("Failed to submit data", Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Detail Screen")),
      body: Obx(
        () => Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: widget.image.url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: Image.asset(
                                'assets/placeholder.webp'), // Placeholder image
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
                    const SizedBox(height: 32),
                    _buildTextField("First Name", _firstNameController,
                        "Please enter your first name"),
                    const SizedBox(height: 16),
                    _buildTextField("Last Name", _lastNameController,
                        "Please enter your last name"),
                    const SizedBox(height: 16),
                    _buildTextField("Email", _emailController,
                        "Please enter a valid email address",
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      } else if (!_emailRegExp.hasMatch(value)) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    }),
                    const SizedBox(height: 16),
                    _buildTextField("Phone", _phoneController,
                        "Please enter a valid phone number (10 digits)",
                        keyboardType: TextInputType.phone,
                        maxLength: 10, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your phone number";
                      } else if (!_phoneRegExp.hasMatch(value)) {
                        return "Please enter a valid phone number (10 digits)";
                      }
                      return null;
                    }),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            " ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _submitForm,
                          borderRadius: BorderRadius.circular(
                              4.0), // Same radius as the container
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    Colors.black, // Black color for the border
                                width: 1.0, // Width of the border
                              ),
                              borderRadius: BorderRadius.circular(
                                  4.0), // Circular radius for the border
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                "Submit",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _isLoading.value
                ? Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String errorMessage,
      {TextInputType keyboardType = TextInputType.text,
      int? maxLength,
      String? Function(String?)? validator}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            keyboardType: keyboardType,
            maxLength:
                maxLength, // maxLength will only be applied if it's not null
            validator: validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return errorMessage;
                  }
                  return null;
                },
          ),
        )
      ],
    );
  }
}
