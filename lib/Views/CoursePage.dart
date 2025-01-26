
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zainab7/Config/constants.dart';
import 'package:zainab7/Views/CourseDetailsPage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:zainab7/Controllers/HomeController.dart';
import 'package:zainab7/Models/CourseModel.dart';
import 'package:zainab7/Themes/Colors.dart';
import '../Controllers/CourseController.dart';
import '../Themes/Color.dart';

class CoursesPage extends StatelessWidget {
  final CourseController _controller = Get.put(CourseController());
  String? subjectId; // Make it a final field (not late)

  // Constructor to accept subjectId
  CoursesPage({Key? key, this.subjectId}) : super(key: key) {
    print("CoursesPage constructor - subjectId: $subjectId"); // Debug print
    if (subjectId == null) {
      final arguments = Get.arguments;
      print("Arguments: $arguments"); // Debug print
      subjectId = arguments != null ? arguments["subjectId"] : null;
      print("Retrieved subjectId from arguments: $subjectId"); // Debug print
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Courses",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 10,
        shadowColor: primaryColor.withOpacity(0.5),
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            topLeft: Radius.circular(30),
          ),
          color: Colors.black12,
        ),
        child: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }
          // Filter the course list based on the subject ID
          final filteredCourses = subjectId != null
              ? _controller.courseList
              .where((course) => course.subject == subjectId)
              .toList()
              : _controller.courseList;
          if (filteredCourses.isEmpty) {
            return const Center(
              child: Text(
                "No course available.",
                style: TextStyle(
                  fontSize: 18,
                  color: primaryColor,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger the refresh logic
              await _controller.getCourseList();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                return AnimatedOpacity(
                  opacity: _controller.isLoading.value ? 0 : 1,
                  duration: const Duration(milliseconds: 500),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        Get.to(CourseDetailsPage(course.id));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Material(
                              elevation: 10,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:CachedNetworkImage(
                                    imageUrl: "${baseURL + course.photo!}",
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                    height: 60,
                                    width: 60,
                                  )
                                // Image.network(
                                //   "${baseURL + course.photo!}",
                                //   width: 60,
                                //   height: 60,
                                //   fit: BoxFit.cover,
                                //   errorBuilder: (context, error, stackTrace) {
                                //     return Container(
                                //       width: 60,
                                //       height: 60,
                                //       decoration: BoxDecoration(
                                //         borderRadius: BorderRadius.circular(10),
                                //       ),
                                //       child: const Icon(
                                //         Icons.image_not_supported_rounded,
                                //         color: primaryColor,
                                //       ),
                                //     );
                                //   },
                                // ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "subject: ${course.subject}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    _showAddCourseDialog(course);
                                  },
                                  child: Icon(
                                    Icons.edit,
                                    color: secondaryColor,
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                InkWell(
                                  onTap: () {
                                    _showDeleteCourseDialog(course.id);
                                  },
                                  child: Icon(
                                    Icons.delete,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCourseDialog(null);
        },
        child: const Icon(Icons.add),
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 10,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showAddCourseDialog(CourseModel? course) {
    var subjects = Get.find<HomeController>().subjects;
    final _formKey = GlobalKey<FormState>();
    Rx<File?> courseImage = Rx<File?>(null);

    var titleController = TextEditingController();
    var overviewController = TextEditingController();
    String selectedSubject = subjects.first.slug;

    if (course != null) {
      titleController.text = course.title;
      overviewController.text = course.overview;
      selectedSubject = subjects
          .firstWhere((element) => element.title == course.subject)
          .slug;
    }

    Future<void> _pickImage() async {
      final pickedFile =
      await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        courseImage.value = File(pickedFile.path);
      }
    }

    Get.defaultDialog(
      title: 'New Course',
      backgroundColor: backgroundColor,
      content: Obx(() {
        return SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  items: subjects
                      .map((e) => DropdownMenuItem(
                    value: e.slug,
                    child: Text(e.title),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedSubject = value!;
                  },
                  decoration: InputDecoration(labelText: 'Select Subject'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a subject'
                      : null,
                ),
                TextFormField(
                  controller: titleController,
                  decoration: (course == null)
                      ? InputDecoration(labelText: 'Title')
                      : null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a course name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    titleController.text = value!;
                  },
                ),
                TextFormField(
                  controller: overviewController,
                  decoration: (course == null)
                      ? InputDecoration(labelText: 'Overview')
                      : null,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    overviewController.text = value!;
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text(
                      (course == null) ? 'Choose Course photo' : 'edit photo'),
                ),
                Obx(() {
                  return courseImage.value != null
                      ? Image.file(
                    courseImage.value!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  )
                      : course != null && course.photo != null
                      ? Image.network(
                    key: ValueKey(course.photo),
                    "${baseURL + course.photo!}",
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("No image available"),
                      );
                    },
                  )
                      : Text('No image selected');
                }),
              ],
            ),
          ),
        );
      }),
      textCancel: 'Cancel',
      textConfirm: (course == null) ? 'Add' : 'Update',
      onCancel: () {},
      onConfirm: () {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          if (selectedSubject == null) {
            Get.snackbar('Error', 'Please select a subject');
            return;
          }

          if (course == null) {
            _controller.addCourse(
              title: titleController.text,
              overview: overviewController.text,
              subject: selectedSubject,
              photo: courseImage.value,
            );
          } else {
            _controller.updateCourse(
              course.id,
              title: titleController.text,
              overview: overviewController.text,
              subject: selectedSubject,
              photo: courseImage.value,
            );
          }
          Get.back();
        }
      },
    );
  }

  void _showDeleteCourseDialog(int courseId) {
    Get.defaultDialog(
      title: 'Delete Course',
      content: Text('Are you sure you want to delete this course?'),
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      onCancel: () {},
      onConfirm: () {
        _controller.deleteCourse(courseId);
        Get.back();
      },
    );
  }
}
