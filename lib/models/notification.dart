class Notification {
  final String message;
  final String user;
  final String bill;
  final String time;

  Notification({
    required this.message,
    required this.user,
    required this.bill,
    required this.time,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      message: json['message'],
      user: json['user'],
      bill: json['bill'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user,
      'bill': bill,
      'time': time,
    };
  }
}