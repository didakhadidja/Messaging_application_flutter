import 'package:chatting_application2/Screens/ConversationScreen.dart';
import 'package:chatting_application2/Screens/ProfilScreen.dart';
import 'package:chatting_application2/Screens/SearchScreen.dart';
import 'package:chatting_application2/Services/Authenticate.dart';
import 'package:chatting_application2/Services/Database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChattRoomScreen extends StatefulWidget {
  @override
  _ChattRoomScreenState createState() => _ChattRoomScreenState();
}

class _ChattRoomScreenState extends State<ChattRoomScreen> {
  AuthMethods _authMethods=new AuthMethods();
  DatabaseMethods _databaseMethods= new DatabaseMethods();
  User? user=FirebaseAuth.instance.currentUser;
  String? username="";

  void getData()async{
    var _user=await FirebaseFirestore.instance.collection("users")
        .doc(user!.uid).get();
    if(_user.exists){
      Map<String,dynamic>? _userInfo=_user.data();
      String? aa=_userInfo?["username"].toString();
      print("trouvé $aa");
      setState(() {
        username=aa;
       // username=_databaseMethods.GetUsername(user!.uid);
      });
    }
  }


  GetMessage(String id)async{
    String msg="";
      await FirebaseFirestore.instance
          .collection('users')
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          print(doc["email"]);
          msg=doc["email"];
        });
      });
    return msg;
  }

  String TransformTime(Timestamp t){
    Timestamp y=t;
    DateTime d=y.toDate();
    return d.toString();
  }


  @override
  void initState()  {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff292F3F),
      appBar: AppBar(
        toolbarHeight: 75,
        leadingWidth: 60,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection("users").doc(user!.uid).snapshots(),
              builder: (context,snapshot){
              if(snapshot.hasData){
                if(snapshot.data!["image"]=="none"){
                  return CircleAvatar(
                    backgroundImage: AssetImage("assets/inconnu.png",),
                  );
                }else{
                  return CircleAvatar(
                    backgroundImage: NetworkImage(snapshot.data!["image"]),
                  );
                }
              }else{
                return CircleAvatar(
                  backgroundImage: AssetImage('assets/inconnu.png'),
                );
              }
        }
          ),
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfilScreen()));
              },
              icon: Icon(Icons.person),
          ),
        ],
        title: Text( username!,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9)
            ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10,),
             /*** Search TextField ***/
             Container(
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   /*** Search TextField ***/
                   SizedBox(
                     width: 295,
                     height: 50,
                     child: TextFormField(
                       decoration: InputDecoration(
                           filled: true,
                           fillColor: Color(0xff000000).withOpacity(0.25),
                           hintText: "Rechercher",
                           hintStyle: GoogleFonts.roboto(
                             color: Colors.white.withOpacity(0.6),
                           ),
                           enabledBorder: OutlineInputBorder(
                               borderRadius: BorderRadius.circular(10),
                               borderSide: BorderSide(
                                   width: 0,
                                   color: Colors.transparent
                               )
                           )
                       ),
                     ),
                   ),
                   /*** Search Button ***/
                   GestureDetector(
                     onTap: (){
                       Navigator.push(context, MaterialPageRoute(builder: (context)=>SearchScreen()));
                     },
                     child: Container(
                       height: 47,
                       width: 47,
                       decoration: BoxDecoration(
                         color: Color(0xff23C686),
                         borderRadius: BorderRadius.circular(10)
                       ),
                       child: Center(
                           child: Icon(Icons.search,color: Colors.white,)),
                     ),
                   )
                 ],
               ),
             ),
              SizedBox(height: 18,),
              /*** Text Favoris ***/
              Container(
                alignment: Alignment.centerLeft,
                child: Text("Favoris",
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 23
                ),
                ),
              ),
              SizedBox(height: 18,),
              /*** Liste des amies ***/
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("chatt_room").where("users",arrayContains: username!).where("messages",isNotEqualTo: null).snapshots(),
                  builder: (context, snapshot) {
                   if(snapshot.hasData){
                     return Flexible(
                       child: ListView(
                           shrinkWrap: true,
                           physics: NeverScrollableScrollPhysics(),
                           children: snapshot.data!.docs.map((doc) {
                             return  GestureDetector(
                               onTap: (){
                                 String name;
                                 if(doc.data()["users"][0]==username!){
                                   name=doc.data()["users"][1];
                                 }else{
                                   name=doc.data()["users"][0];
                                 }
                                 Navigator.push(context, MaterialPageRoute(builder: (context)=>ConversationScreen(
                                   chatt_room_id: _databaseMethods.GetCHattRoomId(username!,name),
                                   sender: username!,
                                   reciver: name,
                                 )));
                               },
                               child: Container(
                                 padding: EdgeInsets.all(10),
                                 margin: EdgeInsets.symmetric(vertical: 2),
                                 height: 80,
                                 width: MediaQuery.of(context).size.width,
                                 decoration: BoxDecoration(
                                     color: Colors.transparent
                                 ),
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Row(
                                       children: [
                                         /*** Photo de profil ***/
                                        StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance.collection("users")
                                              .where("username",isEqualTo: doc.data()["users"][0]==username!?doc.data()["users"][1]:doc.data()["users"][0])
                                              .snapshots(),
                                            builder: (context,snap){
                                            if(snap.hasData){
                                              if(snap.data!.docs.single.data()["image"]=="none"){
                                                return CircleAvatar(
                                                  backgroundImage: AssetImage("assets/inconnu.png"),
                                                  radius: 25,
                                                );
                                              }else{
                                                return CircleAvatar(
                                                  backgroundImage: NetworkImage(snap.data!.docs.single.data()["image"]),
                                                  radius: 25,
                                                );
                                              }
                                            }else{
                                              return Container();
                                            }
                                            }
                                        ),
                                         /*** Username + last message ***/
                                         Container(
                                           child: Column(
                                             children: [
                                               Text(doc.data()["users"][0]==username!?doc.data()["users"][1]:doc.data()["users"][0],
                                                 style: GoogleFonts.roboto(
                                                     fontSize: 17,
                                                     color: Colors.white.withOpacity(0.9)
                                                 ),
                                               ),
                                               StreamBuilder<QuerySnapshot>(
                                                 stream: FirebaseFirestore.instance.collection("chatt_room").doc(_databaseMethods.GetCHattRoomId(doc.data()["users"][0]==username?doc.data()["users"][1]:doc.data()["users"][0], username!)).collection("messages").orderBy("time",descending: true).limit(1).snapshots(),
                                                   builder: (context, snapshot1) {
                                                     if(snapshot1.hasData){
                                                       String f="";
                                                       final message=snapshot1.data!;
                                                       return Text(
                                                        message.docs.single.data()["type"]=="text"
                                                           ?  message.docs.single.data()["message"].length>25
                                                            ? message.docs.single.data()["sendBy"]==username? "vous : "+ message.docs.single.data()["message"].substring(0,24)+"..." : message.docs.single.data()["message"].substring(0,24)+"..."
                                                            : message.docs.single.data()["sendBy"]==username? "vous : "+ message.docs.single.data()["message"] : message.docs.single.data()["message"]
                                                          :
                                                             message.docs.single.data()["sendBy"]==username? "vous avez envoyé une photo " : message.docs.single.data()["sendBy"].substring(0,5) +" a envoyé une photo",
                                                            // message.docs.single.data()["sendBy"]==username? "vous : "+ message.docs.single.data()["message"] : message.docs.single.data()["message"],
                                                         style: GoogleFonts.roboto(
                                                             fontSize: 14,
                                                             color: Colors.white.withOpacity(0.7)
                                                         ),
                                                       );
                                                     }
                                                     else{
                                                       return Text("Aucun message",
                                                         style: GoogleFonts.roboto(
                                                             fontSize: 14,
                                                             color: Colors.white.withOpacity(0.7)
                                                         ),
                                                       );
                                                     }
                                                   }),
                                             ],
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                           ),
                                           padding: EdgeInsets.symmetric(horizontal: 20,vertical: 8),
                                         ),
                                       ],
                                     ),
                                     /*** date de dernier message ***/
                                     StreamBuilder<QuerySnapshot>(
                                       stream: FirebaseFirestore.instance.collection("chatt_room").doc(_databaseMethods.GetCHattRoomId(doc.data()["users"][0]==username?doc.data()["users"][1]:doc.data()["users"][0], username!)).collection("messages").orderBy("time",descending: true).limit(1).snapshots(),
                                         builder: (context,snapshot){
                                         if(snapshot.hasData){
                                           return Container(
                                             child: Text(DateFormat.MMMd().format(snapshot.data!.docs.single.data()["time"].toDate()),
                                               style: GoogleFonts.roboto(
                                                   fontSize: 16,
                                                   color: Colors.white.withOpacity(0.9)
                                               ),

                                             ),
                                           );
                                         }else{
                                           return Container(
                                             child: Text("Dim",
                                               style: GoogleFonts.roboto(
                                                   fontSize: 16,
                                                   color: Colors.white.withOpacity(0.9)
                                               ),

                                             ),
                                           );
                                         }
                                         }
                                     ),
                                   ],
                                 ),
                               ),
                             );
                           }).toList(),
                       ),
                     );
                   }else{
                     return Flexible(child: Center(child: CircularProgressIndicator()));
                    }
                  }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
