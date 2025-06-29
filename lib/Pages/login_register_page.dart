import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_to_sip_app/Pages/auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController controllerEmail = TextEditingController();
  final TextEditingController controllerPassword = TextEditingController();
  final TextEditingController controllerFullName = TextEditingController();

  Future<void> signInWithEmailAndPassWord() async{
    try {
      await Auth().singInWithEmailAndPassword(
          email: controllerEmail.text,
          password: controllerPassword.text
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPasword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
          email: controllerEmail.text,
          password: controllerPassword.text,
          fullName: controllerFullName.text);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> sendPasswordResetEmail(String email, BuildContext context) async {
    try {
      await Auth().sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  Widget _title()
  {
    return const Text('Firebase Auth');
  }

  Widget _entryField(
      String title,
      TextEditingController controller,
      ) {
    return TextField(
      controller: controller,
      obscureText: title == 'Password' ? true : false,
      decoration: InputDecoration(
          labelText: title,
      ),
    );
  }

  Widget _errorMessage()
  {
    return Text(errorMessage == '' ? '' : 'Humm ? $errorMessage');
  }

  Widget _submitButton()
  {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6F4E37),
          foregroundColor: Colors.white
        ),
        onPressed: isLogin ?
        signInWithEmailAndPassWord :
        createUserWithEmailAndPasword,
        child: Text(isLogin ? 'Login' : 'Register',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w800
        )),
    );
  }

  Widget _loginOrRegisterButton(){
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: Color(0xFF6F4E37),
        foregroundColor: Colors.white
      ),
        onPressed: (){
          setState(() {
            isLogin = !isLogin;
          });
        },
      child: Text(isLogin ? 'Register instead' : 'Login instead',
          style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold
          )),
    );
  }

  Widget _forgotPasswordButton(BuildContext context)
  {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF6F4E37),
        foregroundColor: Colors.white
      ),
      onPressed: () => showForgotPasswordDialog(context),
      child: Text('Forgot Password?',
          style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800
          )),
    );
  }
/*  TextButton(
  onPressed: () {
  showForgotPasswordDialog(context);
  },
  child: const Text('Forgot Password?'),
  ),*/
/// MODIFY MBY THE CODE FOR THE IMAGE
  /// WHAT I HAVE NOW IS A BAD FIX??

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFffff08),
      ),
      body: Container(
        color: Color(0xFFffff08),
          height: double.infinity,
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Padding(padding: EdgeInsets.only(bottom: 400),
                child: Image.asset(
                  'assets/RTS_NBack_Logo.png',
                  height: 400, // or BoxFit.contain if needed
                ),
              ),
            ),
            Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _entryField('Email', controllerEmail),
                if (!isLogin) _entryField('Full Name', controllerFullName),
                _entryField('Password', controllerPassword),
                _errorMessage(),
                _submitButton(),
                SizedBox(height: 10),
                _loginOrRegisterButton(),
                SizedBox(height: 10),
                _forgotPasswordButton(context)
              ],
            ))
          ],
        )
      ),
    );
  }

  void showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password',
          style: TextStyle(
              fontFamily: 'Montserrat',
          )),
          backgroundColor: Color(0xFFffff08),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Enter your email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                  )),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6F4E37),
                foregroundColor: Colors.white
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an email',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                        ))),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.of(context).pop(); // Close dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset email sent to $email',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                        ))),
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.message}')),
                  );
                }
              },
              child: const Text('Send',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                  )),
            ),
          ],
        );
      },
    );
  }

}
