import 'package:dio/dio.dart';
import 'package:zainab7/Config/constants.dart';
import 'package:zainab7/Controllers/HomeController.dart';
import 'package:zainab7/Views/LoginPage.dart';
import 'package:get/get.dart';

import '../APIServices/DioClient.dart';
import '../Helpers/TokenStorage.dart';
import '../Models/LoginResponeMode.dart';
import '../Models/LoginResponeModel.dart';
import '../Models/SubjectModels.dart';
import '../Views/HomePage.dart';


class LoginController extends GetxController {
  String? accessToken;
  String? refreshedToken;

  final DioClient _dioClient = DioClient();
  @override
  void onInit() async {

    super.onInit();
    // Load tokens from storage when the app starts
    accessToken = await TokenStorage.getAccessToken();
    refreshedToken = await TokenStorage.getRefreshToken();
    if (accessToken != null) {

      Get.offAll(() => HomePage()); // Navigate to HomePage

    }
  }

  Future<void> login(String email, String password) async {
    final url = baseAPIURLV1+loginAPI; // Replace with your API login endpoint

    try {
      final response = await _dioClient.dio.post(
        url,
        options: Options(contentType:"application/json"),
        data: {
          "email": email,
          "password": password,
        },
      );
      //print("qqqqqqqqqqqqqqq${response}");
      if (response.statusCode == 200) {
        final loginResponse = LoginResponseModel.fromJson(response.data);
        accessToken = loginResponse.accessToken;
        refreshedToken = loginResponse.refreshToken;

        // Save tokens to storage
        await TokenStorage.saveTokens(accessToken!, refreshedToken!);


        Get.snackbar("Success", "Login successful",
            snackPosition: SnackPosition.BOTTOM);
        Get.offAll(() => HomePage());

      } else {
        Get.snackbar("Error", "Invalid credentials",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      print(e);
      Get.snackbar("Error", "Failed to login",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Observable for password visibility
  var isPasswordVisible = false.obs;

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  Future<void> logout() async {
    // Clear tokens from memory and storage
    accessToken = null;
    refreshedToken = null;
    await TokenStorage.clearTokens();
    Get.snackbar("Success", "Logged out successfully",
        snackPosition: SnackPosition.BOTTOM);
    Get.offAll(()=>LoginPage());
  }

}