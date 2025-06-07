import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lnmq/firebase_options.dart';
import 'package:lnmq/screens/auth_screen.dart'; // Màn hình đăng nhập/đăng ký
import 'package:lnmq/screens/home_screen.dart'; // Màn hình chính sau khi đăng nhập
import 'package:lnmq/services/place_service.dart'; // Giữ nguyên nếu bạn dùng

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await PlaceService().addSamplePlaces(); // Uncomment nếu bạn muốn thêm dữ liệu mẫu khi chạy lần đầu
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App Vietnam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'BeVietnamPro',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Lắng nghe sự thay đổi trạng thái Auth
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Đang chờ kết nối hoặc kiểm tra trạng thái ban đầu
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Xử lý lỗi nếu có
            print('Lỗi trong StreamBuilder của main.dart: ${snapshot.error}');
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            final user = snapshot.data;
            // KIỂM TRA THÊM ĐIỀU KIỆN EMAIL ĐÃ ĐƯỢC XÁC MINH
            if (user != null && user.emailVerified) {
              // Nếu có người dùng và email đã được xác minh, điều hướng đến HomeScreen
              return const HomeScreen();
            } else if (user != null && !user.emailVerified) {
              // Nếu có người dùng nhưng email chưa được xác minh:
              // 1. Đăng xuất người dùng để đảm bảo họ không bị "mắc kẹt" trong trạng thái đăng nhập nhưng chưa xác minh.
              // 2. Hiển thị lại AuthScreen và thông báo cho họ xác minh email.
              // Lưu ý: Việc signOut() ở đây sẽ kích hoạt lại StreamBuilder,
              // và lần tới snapshot.hasData sẽ là false, dẫn đến return AuthScreen() ở cuối.
              // Tuy nhiên, để đảm bảo ngay lập tức quay lại AuthScreen, ta return AuthScreen() ở đây.
              Future.microtask(() => FirebaseAuth.instance.signOut()); // Đăng xuất bất đồng bộ
              return const AuthScreen(); // Trở lại màn hình đăng nhập
            }
          }
          // Nếu không có người dùng đăng nhập
          return const AuthScreen();
        },
      ),
    );
  }
}