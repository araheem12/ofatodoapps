import 'package:hive/hive.dart';
part 'todo_model.g.dart';

@HiveType(typeId: 0)
class TodoModel extends HiveObject{
  @HiveField(0)
  final String? title;
  @HiveField(1)
  final bool? isDone;
  @HiveField(12)
  String? firebaseId;
  TodoModel({this.title, this.isDone = false, this.firebaseId });

}