import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(MaterialApp(
    home: ImageListScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class ImageData {
  final String url;
  final String id;

  ImageData({required this.url, required this.id});

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      url: json['xt_image'],
      id: json['id'],
    );
  }
}

class ImageListScreen extends StatefulWidget {
  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  int offset = 0;
  bool isLoading = false;
  bool hasMore = true;
  List<ImageData> images = [];

  @override
  void initState() {
    super.initState();
    fetchImages(offset);
  }

  Future<void> fetchImages(int offset) async {
    setState(() {
      isLoading = true;
    });

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

      setState(() {
        images.addAll(newImages);
        isLoading = false;
        if (newImages.isEmpty) {
          hasMore = false;
        }
      });
    } else {
      setState(() {
        isLoading = false;
        hasMore = false;
      });
      throw Exception('Failed to load images');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image List")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: images.length + 1,
              itemBuilder: (context, index) {
                if (index == images.length) {
                  return hasMore
                      ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isLoading) {
                          offset += 3;
                          fetchImages(offset);
                        }
                      },
                      child: isLoading
                          ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : Text("Click here to load more"),
                    ),
                  )
                      : Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Text("No more data!"),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(image: images[index]),
                        ),
                      );
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
                            imageUrl: images[index].url,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: Image.asset('assets/placeholder.webp'), // Placeholder image
                            ),
                            errorWidget: (context, url, error) => Center(
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
      ),
    );
  }
}
class DetailScreen extends StatefulWidget {
  final ImageData image;

  DetailScreen({required this.image});

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

  bool _isLoading = false; // Flag to manage loading state

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      final uri = Uri.parse('http://dev3.xicomtechnologies.com/xttest/savedata.php');
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
      setState(() {
        _isLoading = false; // Hide loading indicator
      });

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
      appBar: AppBar(centerTitle: true,title: Text("Detail Screen")),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
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
                          child: Image.asset('assets/placeholder.webp'), // Placeholder image
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("First Name", style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: "First Name",
                            border: OutlineInputBorder(), // Rectangle border
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your first name";
                            }
                            return null;
                          },
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Last Name", style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: "Last Name",
                            border: OutlineInputBorder(), // Rectangle border
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your last name";
                            }
                            return null;
                          },
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Email", style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(), // Rectangle border
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your email";
                            } else if (!_emailRegExp.hasMatch(value)) {
                              return "Please enter a valid email address";
                            }
                            return null;
                          },
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Phone", style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your phone number";
                            } else if (!_phoneRegExp.hasMatch(value)) {
                              return "Please enter a valid phone number (10 digits)";
                            }
                            return null;
                          },
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(" ", style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),),
                      ),
                      InkWell(
                        onTap: _submitForm,
                        borderRadius: BorderRadius.circular(4.0), // Same radius as the container
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black, // Black color for the border
                              width: 1.0, // Width of the border
                            ),
                            borderRadius: BorderRadius.circular(4.0), // Circular radius for the border
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
          Visibility(
            visible: _isLoading,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          )

        ],
      ),
    );
  }
}

