class Transaction {
  String key;
  num amount;
  String location;
  String date;
  List<dynamic> categories;

  Transaction(
      {this.key, this.amount, this.location, this.date, this.categories});

  Transaction.fromMap(Map map) {
    key = map["key"];
    amount = map["amount"];
    location = map["location"];
    date = map["date"];
    categories = map["categories"];
  }

  toJson() {
    return {
      "amount": amount,
      "location": location,
      "date": date,
      "categories": categories
    };
  }

  String toString() {
    return "amount: $amount, location: $location, date: $date, categories: $categories";
  }
}
