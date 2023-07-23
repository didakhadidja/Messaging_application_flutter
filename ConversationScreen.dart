import 'dart:io';

import 'package:chatting_application2/Widgets/Widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../Services/Database.dart';

class ConversationScreen extends StatefulWidget {
  final String reciver;
  final String sender;
  final String chatt_room_id;

  const ConversationScreen({super.key, required this.reciver,required this.sender,required this.chatt_room_id});
  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  List<bool> _is=[true,true,false,false,true,false,true,false,true,true,false,false,false,true];

  TextEditingController _messageController=TextEditingController();
  DatabaseMethods _databaseMethods = new DatabaseMethods();
  User? user=FirebaseAuth.instance.currentUser;
  File? _photo;
  String? url;
  ScrollController _controller=ScrollController();

  SendMessage(){
    if(_messageController.text.isNotEmpty){
      _databaseMethods.SendMessageToDatabase(_messageController.text.trim(), widget.chatt_room_id, widget.sender,"text" ).then((val){
        print("message envoyé");
        setState(() {
          _messageController.text="";
        });
      });
    }
  }

  void SendImage()async{
    if(_photo!=null){
      final ref=FirebaseStorage.instance.ref().child("ImagesMessages")
          .child(DateTime.now().microsecondsSinceEpoch.toString()+".jpg");
     await ref.putFile(_photo!);
       url= await ref.getDownloadURL();

     _databaseMethods.SendMessageToDatabase(url!, widget.chatt_room_id, widget.sender,"image" ).then((val){
       setState(() {
         _photo=null;
       });
     });

    }
  }

 Future GetImage()async{
    try{
      final im=await ImagePicker().pickImage(source: ImageSource.gallery);
      if(im==null) return;
      final imageTemp=File(im.path);
      setState(() {
        this._photo=imageTemp;
      });
    }on PlatformException catch(e){
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff292F3F),
      appBar: AppBar(
        toolbarHeight: 75,
        leadingWidth: 100,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back)
            ),
            Flexible(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("users").where("username",isEqualTo: widget.reciver).snapshots(),
                  builder: (context,snapshot){
                  if(snapshot.hasData){
                    if(snapshot.data!.docs.single.data()["image"]!="none"){
                      return CircleAvatar(
                        backgroundImage: NetworkImage(snapshot.data!.docs.single.data()["image"],),
                      );
                    }else{
                      return CircleAvatar(
                        backgroundImage: AssetImage("assets/inconnu.png"),
                      );
                    }
                  }else{
                    return CircleAvatar(
                      backgroundImage: AssetImage("assets/profil.jpg"),
                    );
                  }
                  }
              ),
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.reciver,
              style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.9)
              ),
            ),
            SizedBox(height: 5,),
            Text("En ligne",
              style: GoogleFonts.roboto(
                fontSize: 13,
                  color: Colors.white.withOpacity(0.9)
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 68),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("chatt_room")
                  .doc(widget.chatt_room_id).collection("messages").orderBy("time",descending: false).snapshots(),
                builder: (context, snapshot) {
                  if(snapshot.hasData){
                    return ListView(
                      controller: _controller,
                      //reverse: true,
                      children: snapshot.data!.docs.map((doc){
                        return MessageTile(
                          doc.data()["message"],
                          doc.data()["sendBy"]==widget.sender?true:false,
                          doc.data()["type"]
                        );
                      }).toList(),
                    );
                  }
                  else{
                    return Center(child: CircularProgressIndicator());
                  }
                }
            ),
          ),
          Container(
            //color: Color(0xff292F3F),
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15,vertical: 8),
                  height: 66,
                  decoration: BoxDecoration(
                    color: Color(0xff292F3F),
                  ),
                  child: Row(
                    children: [
                      /*** Camera icon ***/
                      GestureDetector(
                        child: Container(
                          child: Icon(Icons.camera_enhance_outlined,color: Color(0xff23C686),size: 28,),
                          padding: EdgeInsets.only(right: 10),
                        ),
                      ),
                      /*** Gallery icon ***/
                      GestureDetector(
                        onTap: (){
                          GetImage();
                        },
                        child: Container(
                          child: Icon(Icons.image_outlined,color: Color(0xff23C686),size: 28,),
                          padding: EdgeInsets.only(right: 10),
                        ),
                      ),
                      /*** Message TextField ***/
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.25),
                            hintText: "Message...",
                            hintStyle: GoogleFonts.roboto(color: Colors.white.withOpacity(0.6)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                width: 0,
                                color: Colors.transparent,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                width: 0,
                                color: Colors.transparent,
                              ),
                            ),

                          ),
                          controller: _messageController,
                          style: GoogleFonts.roboto(color: Colors.white),
                        ),
                      ),
                      /*** Send Icon ***/
                      GestureDetector(
                        onTap: (){
                          SendMessage();
                        },
                        child: Container(
                          // height: 50,
                            margin: EdgeInsets.only(left: 10),
                            child: Icon(Icons.send,color: Color(0xff23C686),size: 30,)
                        ),
                      ),
                    ],
                  ),
                ),
                /*** Liste des image a envoyé ***/
                _photo != null
                    ? Container(
                  decoration: BoxDecoration(
                    color: Color(0xff292F3F),
                  ),
                  //  color: Colors.red,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /*** Liste des photo ***/
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 1.5,color: Color(0xff23C686)),
                            image: DecorationImage(
                                image: FileImage(_photo!),
                                fit: BoxFit.cover
                            ),
                          ),
                        ),
                        /*** Boutton annuler l'envoi des photos ***/
                       Row(
                         children: [
                           GestureDetector(
                             onTap: (){
                               setState(() {
                                 _photo=null;
                               });
                             },
                             child: Container(
                               height: 40,
                               width: 110,
                               decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(15),
                                   color: Colors.white,
                               ),
                               child: Center(
                                 child: Text("Annuler",
                                   style: GoogleFonts.roboto(color: Colors.black,fontSize: 17),
                                 ),
                               ),
                             ),
                           ),
                           SizedBox(width: 8,),
                           GestureDetector(
                             onTap: (){
                               SendImage();
                             },
                             child: Container(
                               height: 40,
                               width: 110,
                               decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(15),
                                   color: Color(0xff23C686)
                               ),
                               child: Center(
                                 child: Text("Envoyer",
                                   style: GoogleFonts.roboto(color: Colors.white,fontSize: 17),
                                 ),
                               ),
                             ),
                           ),
                         ],
                       )

                      ],
                    )
                )
                    : Container(),
              ],
            )
          ),
        ],
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool isSendByMe;
  final String type;
  MessageTile(this.message, this.isSendByMe,this.type);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: isSendByMe ? 20:70, left: isSendByMe ? 70:20),
      width: MediaQuery.of(context).size.width,
      alignment: isSendByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: type=="text"
          ?Container(
        margin: EdgeInsets.symmetric(vertical: 7),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSendByMe ? [
                const Color(0xff23C686),
                const Color(0xff23C686),
              ]: [
                const Color(0xff373E4E),
                const Color(0xff373E4E),
              ],

            ),
            borderRadius: isSendByMe ?
            BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23), bottomLeft: Radius.circular(23) ):
            BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23), bottomRight: Radius.circular(23) )
        ),
        child: Text(message,style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 17)),
      )
          : Container(
        height: 200,
        width: 200,
        margin: EdgeInsets.symmetric(vertical: 7),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSendByMe ? [
                const Color(0xff23C686),
                const Color(0xff23C686),
              ]: [
                const Color(0xff373E4E),
                const Color(0xff373E4E),
              ],
            ),
            border: Border.all(width: 3,color: isSendByMe?Color(0xff23C686):Color(0xff373E4E)),
            borderRadius: isSendByMe ?
            BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23), bottomLeft: Radius.circular(23) ):
            BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23), bottomRight: Radius.circular(23) ),
          image: DecorationImage(
            image: NetworkImage(message),
            fit: BoxFit.cover
          )
        ),
      ),
    );
  }
}



