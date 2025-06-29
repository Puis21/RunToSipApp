import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:run_to_sip_app/Pages/home.dart';

AppBar buildBaseAppBar(BuildContext context, title) {
  return AppBar(
    backgroundColor: Color(0xFFffff00),
    elevation: 5.0,
    shadowColor: Colors.black,
    centerTitle: true,

    leading: Container(
      margin: const EdgeInsets.all(8.0),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage())
          );
        },
        child: Transform.translate(
          offset: const Offset(10, 0), // Your right shift
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // Adjust radius as needed
            child: Transform.scale(
              scale: 1.8, // Your scale value
              child: SvgPicture.asset(
                'assets/RTS_Normal_Logo.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    ),
    title: Text(
      title.toString(),
      style: TextStyle(
        fontFamily: 'RacingSansOne',
        fontSize: 30,
        color: Colors.black,
      ),
    ),

    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 20),
        child:  Builder( builder: (context) => IconButton(
          icon: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/RTSLog.png'), // temporary base image
            backgroundColor: Colors.grey[300],
          ),
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
        ),),
      ),
    ],
  );
}