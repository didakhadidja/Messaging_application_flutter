import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class EditImage extends StatefulWidget {
  @override
  _EditImageState createState() => _EditImageState();
}

class _EditImageState extends State<EditImage> {
  File? _photo;
  String? initImage;
  User? user=FirebaseAuth.instance.currentUser;
  String? url;

  Future GetImagePicked()async{
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


  Future uploadFile() async {
    if (_photo == null) return;
    final fileName = basename(_photo!.path);
    final destination = 'files/$fileName';

    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref(destination)
          .child('file/');
      await ref.putFile(_photo!);
    } catch (e) {
      print('error occured');
    }
  }

  void _updateImage()async{
    final ref = FirebaseStorage.instance
        .ref()
        .child('usersImages')
        .child(user!.uid + '.jpg');
    await ref.putFile(_photo!);
    url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update(
        {
          "image" : url
        }).then((value) {

    });
  }

  void _initiaiserImage()async{
    await FirebaseFirestore.instance.collection("users").doc(user!.uid)
        .get().then((value) {
          setState(() {
            initImage=value["image"];
            print(initImage);
          });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initiaiserImage();
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff292F3F),
      appBar: AppBar(
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*** Profile Image ***/
                  Container(
                    child: _photo==null
                    ?
                        initImage=="none"?CircleAvatar(
                          backgroundImage: AssetImage("assets/inconnu.png"),
                          radius: 50,
                        )
                            :CircleAvatar(
                          backgroundImage: NetworkImage(initImage!),

                          radius: 50,
                        )
                    :   CircleAvatar(
                      backgroundImage: Image.file(_photo!,fit: BoxFit.cover,).image,
                      radius: 50,
                    )
                  ),
                  /*** Text Edir profile ***/
                  SizedBox(height: 15,),
                  GestureDetector(
                    onTap: (){
                      GetImagePicked();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      child: Text("Editer image de profile",
                        style: GoogleFonts.roboto(
                          color: Color(0xff23C686),
                          fontSize: 22,
                          //fontWeight: FontWeight.w600
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40,),
            _photo==null
                ? Container()
                :GestureDetector(
              onTap: (){
                _updateImage();
                Navigator.pop(context);
              },
              child: Container(
                height: 45,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Color(0xff23C686),
                ),
                child: Center(
                  child: Text("Enregistrer",
                    style: GoogleFonts.roboto(color: Colors.white,fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
