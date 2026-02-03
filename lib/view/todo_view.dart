import 'package:flutter/material.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/state_manager.dart';
import 'package:ofatodoapps/controller/todo_model_controller.dart';
import 'package:ofatodoapps/models/todo_model.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController controller = TextEditingController();
  final TodoModelController todoController = Get.put(TodoModelController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: todoController.logout, icon: Icon(Icons.logout)),title: Text("Offline-First ToDo"),centerTitle: true,),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: controller)),
                IconButton(
                  onPressed: () async {
                    todoController.todos.add(TodoModel(title: controller.text));
                    await todoController.addTodo(title: controller.text);
                    controller.clear();
                  },
                  icon: Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: todoController.todos.length,
                itemBuilder: (_, i) {
                  return ListTile(
                    title: Text(todoController.todos[i].title.toString()),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: (){
                        todoController.todos.removeAt(i);
                        todoController.deleteTodo(i);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
