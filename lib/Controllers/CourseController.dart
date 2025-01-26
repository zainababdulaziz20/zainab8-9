
import 'dart:io';
import 'package:zainab7/Config/constants.dart';
import 'package:get/get.dart';

import '../Helpers/SQliteDbHelper.dart';
import '../Models/CourseModel.dart';
import 'package:zainab7/Helpers/NetworkHelper.dart';
import 'package:zainab7/APIServices/DioClient.dart';
import 'package:zainab7/APIServices/DynamicApiServices.dart';

class CourseController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  var courseList = <CourseModel>[].obs;
  CourseModel? courseDetail;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    getCourseList();
  }

  Future<void> getCourseList() async {
    try {
      isLoading(true);


      // Fetch data from the local database
      final localCourses = await _databaseHelper.getCourses();
      courseList.value = localCourses;
      Get.snackbar("Info", "No internet connection. Showing local data.",
          snackPosition: SnackPosition.BOTTOM);

    } catch (e) {
      Get.snackbar("Error", "Failed to fetch courses: $e",
          snackPosition: SnackPosition.BOTTOM);
      print(e);
    } finally {
      isLoading(false);
    }
  }

  Future<void> getCourseDetails(int courseId) async {
    try {
      isLoading(true);


      // Fetch data from the local database
      final localCourses = await _databaseHelper.getCourses();
      courseDetail = localCourses.firstWhere((course) => course.id == courseId);

    } catch (e) {
      Get.snackbar("Error", "Failed to fetch course details: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  void addCourse({
    required String title,
    required String overview,
    required String subject,
    File? photo,
  }) async {

    try {
      isLoading(true);

      // Add to local database first
      final newCourse = CourseModel(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        title: title,
        subject: subject,
        overview: overview,
        photo: photo?.path ?? '',
        createdAt: DateTime.now().toIso8601String(), // Add current timestamp
      );
      await _databaseHelper.insertCourse(newCourse);
      if (await isConnected()) {
        await _addCourseToApi(newCourse);
      } else {



        Get.snackbar('Info', 'Course saved locally. Sync with API when online.',
            snackPosition: SnackPosition.BOTTOM);}

    } catch (e) {
      Get.snackbar('Error', 'Failed to add course: $e');
    } finally {
      isLoading(false);
    }

    getCourseList();
  }

  void updateCourse(
      int courseId, {
        required String title,
        required String overview,
        required String subject,
        File? photo,
      }) async {

    try {
      isLoading(true);

      // Update local database first
      final updatedCourse = CourseModel(
        id: courseId,
        title: title,
        subject: subject,
        overview: overview,
        photo: photo?.path ?? '',
        createdAt: DateTime.now().toIso8601String(), // Update timestamp
      );
      await _databaseHelper.updateCourse(updatedCourse);
      if (await isConnected()) {
        await _updateCourseOnApi(updatedCourse);
      } else {


        Get.snackbar('Info', 'Course updated locally. Sync with API when online.',
            snackPosition: SnackPosition.BOTTOM);}

    } catch (e) {
      Get.snackbar('Error', 'Failed to update course: $e');
    } finally {
      isLoading(false);
    }

    getCourseList();
  }
  Future<void> _updateCourseOnApi(CourseModel course) async {
    try {
      DioClient _client = DioClient();
      final response = await _client.dio.put(
        updateAPI,  // Assuming the API supports PUT for update with course ID
        data: course.toJson(),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Info", "Course synced with API.");
      } else {
        Get.snackbar("Error", "Failed to sync with API.");
      }
    } catch (e) {
      Get.snackbar("Error", "Error during sync: $e");
    }
  }

  void deleteCourse(int courseId) async {
    try {
      isLoading(true);

      // Delete from local database first
      await _databaseHelper.deleteCourse(courseId);
      if (await isConnected()) {
        await _deleteCourseFromApi(courseId);
      } else {



        // Check internet connectivity

        Get.snackbar('Info', 'Course deleted locally. Sync with API when online.',
            snackPosition: SnackPosition.BOTTOM);}

    } catch (e) {
      Get.snackbar('Error', 'Failed to delete course: $e');
    } finally {
      isLoading(false);
    }
    getCourseList();
  }
}
Future<void> _deleteCourseFromApi(int courseId) async {
  try {
    DioClient _client = DioClient();
    final response = await _client.dio.delete(
      deleteAPI,  // Assuming the API supports DELETE with course ID
    );

    if (response.statusCode == 200) {
      Get.snackbar("Info", "Course deleted from API.");
    } else {
      Get.snackbar("Error", "Failed to sync deletion with API.");
    }
  } catch (e) {
    Get.snackbar("Error", "Error during sync: $e");
  }
}
Future<void> _addCourseToApi(CourseModel course) async {
  try {
    DioClient _client = DioClient();
    final response = await _client.dio.post(
      teachersAPI, // استبدل بـ URL الخاص بك
      data: course.toJson(),
    );

    if (response.statusCode == 200) {
      Get.snackbar("Info", "Course synced with API.");
    } else {
      Get.snackbar("Error", "Failed to sync with API.");
    }
  } catch (e) {
    Get.snackbar("Error", "Error during sync: $e");
  }
}
/* Future<void> _addCourseToApi(CourseModel course) async {
    try {
      final response = await http.post(
        Uri.parse("https://example.com/api/courses"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(course.toJson()),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Info", "Course synced with API.");
      } else {
        Get.snackbar("Error", "Failed to sync with API.");
      }
    } catch (e) {
      Get.snackbar("Error", "Error during sync: $e");
    }
  }

Future<bool> isConnected() async {
  try {
    final result = await InternetAddress.lookup('example.com'); // تحقق من الاتصال
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;  // في حالة عدم وجود اتصال بالإنترنت
  }
}*/
Future<bool> isConnected() async {
  try {
    final result = await InternetAddress.lookup(''); // تحقق من الاتصال
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;  // في حالة عدم وجود اتصال بالإنترنت
  }
}
