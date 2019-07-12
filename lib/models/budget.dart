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
  num spent;
  List<dynamic> userDate;

  Budget({
    this.key,
    this.createdBy,
    this.hiddenFrom,
    this.history,
    this.isShared,
    this.left,
    this.name,
    this.setAmount,
    this.sharedWith,
    this.spent,
    this.userDate,
  });

  Budget.fromMap(Map map) {
    key = map["key"];
    createdBy = map["createdBy"];
    hiddenFrom = map["hiddenFrom"];
    history = map["history"];
    isShared = map["isShared"];
    left = map["left"];
    name = map["name"];
    setAmount = map["setAmount"];
    sharedWith = map["sharedWith"];
    spent = map["spent"];
    userDate = map["userDate"];
  }

  Budget.fromJson(Map<String, dynamic> json)
      : key = json['key'] as String,
        createdBy = json['createdBy'] as String,
        hiddenFrom = json['hiddenFrom'] as List<dynamic>,
        history = json['history'] as List<dynamic>,
        isShared = json['isShared'] as bool,
        left = json['left'] as num,
        name = json['name'] as String,
        setAmount = json['setAmount'] as num,
        sharedWith = json['sharedWith'] as List<dynamic>,
        spent = json['spent'] as num,
        userDate = json['userDate'] as List<dynamic>;

  Map toJson() {
    return {
      "key": key,
      "createdBy": createdBy,
      "hiddenFrom": hiddenFrom,
      "history": history,
      "isShared": isShared,
      "left": left,
      "name": name,
      "setAmount": setAmount,
      "sharedWith": sharedWith,
      "spent": spent,
      "userDate": userDate,
    };
  }

  String toString() {
    return "key: $key, name: $name, createdBy: $createdBy, left: $left, setAmount: $setAmount, spent: $spent";
  }
}
