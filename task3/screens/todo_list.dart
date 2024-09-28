import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:todo_app_task3/screens/add_page.dart';
import 'package:todo_app_task3/services/todo_service.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool isloading = true;
  List items = [];

  @override
  void initState() {
    super.initState();
    fetchTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo list'),
      ),
      body: Visibility(
        visible: isloading,
        replacement: Center(
          child: CircularProgressIndicator(),
        ),
        child: Visibility(
          visible: items.isNotEmpty,
          replacement: Center(child: Text(
            'no todo item',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          ),
          child: RefreshIndicator(
            onRefresh: fetchTodo,
            child: ListView.builder(
              itemCount: items.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final item = items[index] as Map;
                final id = item['_id'];
          
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(item['title']),
                    subtitle: Text(item['description']),
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if(value == 'edit'){
                          //edi items
                          navigateToEditPage();
                            
                        }
                        else if (value == 'delete'){
                          //dlete and refesh
                          deleteById(id);
                            
                        }
                      },
                      itemBuilder: (context) {
                      return [
                        PopupMenuItem(child: Text('Edit')),
                        value: 'edit',
                        PopupMenuItem(child: Text('delete')),
                        value: 'delete',
                      ];
                    }
                    ),
                            
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text('Add Text'),
      ),
    );
  }

 Future <void> navigateToAddPage() async {
    final route = MaterialPageRoute(
      builder: (context) => AddTodoPage(),
    );
    Navigator.push(context, route);
    setState(() {
      isloading = true;
    });
    fetchTodo();
  }

  Future<void> deleteById(String id) async {
    final is_success = await TodoService.deleteById(id);
    if (is_success){
      //remove item from list
      final filtered = items.where((element) => element['_id'] != id).toList();
      setState() {
        items = filtered;
      };

    }
  }

  Future<void> navigateToEditPage(Map item) async {
    final route = MaterialPageRoute(
      builder: (context) => AddTodoPage(todo: item),
    );
    await Navigator.push(context, route);
    setState(() {
      isloading= true;
    });
    fetchTodo();
  }

  Future<void> fetchTodo() async {
    final response = TodoService.fetchTodos();
    

    if (response != null) {
      
      setState(() {
        items = response as List;
      });
    }

    setState(() {
      isloading = false;
    });
  }
    void showErrorMessage(String message) {
    // ignore: non_constant_identifier_names
    final SnackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(Colors.white),
      ),
      backgroundClor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSuccessbar(SnackBar);
  }

}

extension on ScaffoldMessengerState {
  void showSuccessbar(snackBar) {}
}

