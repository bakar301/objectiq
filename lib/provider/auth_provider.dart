// import 'package:flutter/foundation.dart';

// class AuthProvider with ChangeNotifier {
//   bool _isAuthenticated = false;
//   String? _userId;

//   bool get isAuthenticated => _isAuthenticated;
//   String? get userId => _userId;

//   void login(String email, String password) {
//     // Implement actual login logic
//     _isAuthenticated = true;
//     _userId = "user_${DateTime.now().millisecondsSinceEpoch}";
//     notifyListeners();
//   }

//   void signup(String email, String password) {
//     // Implement actual signup logic
//     _isAuthenticated = true;
//     _userId = "user_${DateTime.now().millisecondsSinceEpoch}";
//     notifyListeners();
//   }

//   void logout() {
//     _isAuthenticated = false;
//     _userId = null;
//     notifyListeners();
//   }
// }
