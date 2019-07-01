import 'package:firebase_database/firebase_database.dart';

class Budget {
  String key;
  String createdBy;
  List<dynamic> hiddenFrom;
  List<dynamic> history;
  bool isShared;
  num left;
  String name;
  num setAmount;
  List<dynamic> sharedWith;
  String sharedName;
  num spent;
  List<dynamic> userDate;

  Budget({
    this.createdBy,
    this.hiddenFrom,
    this.history,
    this.isShared,
    this.left,
    this.name,
    this.setAmount,
    this.sharedWith,
    this.sharedName,
    this.spent,
    this.userDate,
  });

  Budget.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        createdBy = snapshot.value["createdBy"],
        hiddenFrom = snapshot.value["hiddenFrom"],
        history = snapshot.value["history"],
        isShared = snapshot.value["isShared"],
        left = snapshot.value["left"],
        name = snapshot.value["name"],
        setAmount = snapshot.value["setAmount"],
        sharedWith = snapshot.value["sharedWith"],
        sharedName = snapshot.value["sharedName"] ?? "none",
        spent = snapshot.value["spent"],
        userDate = snapshot.value["userDate"];

  toJson() {
    return {
      "createdBy": createdBy,
      "hiddenFrom": hiddenFrom,
      "history": history,
      "isShared": isShared,
      "left": left,
      "name": name,
      "setAmount": setAmount,
      "sharedWith": sharedWith,
      "sharedName": sharedName,
      "spent": spent,
      "userDate": userDate,
    };
  }
}
