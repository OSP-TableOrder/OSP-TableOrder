import 'package:flutter/material.dart';
import 'package:table_order/widgets/role_box.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoleBox(
              title: "사장",
              color: Colors.orange.shade300,
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),

            const SizedBox(width: 20),

            RoleBox(
              title: "사용자",
              color: Colors.blue.shade300,
              onTap: () {
                Navigator.pushNamed(context, '/userHome');
              },
            ),
          ],
        ),
      ),
    );
  }
}
