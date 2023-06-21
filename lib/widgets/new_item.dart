import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
//import 'package:shopping_list/models/grocery_item.dart';

import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  void _submitPressed() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });

      //after submiting saving data to database
      final url = Uri.https(
          'first-3c35f-default-rtdb.firebaseio.com', 'shopping-list.json');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _enteredName,
          'quantity': _enteredQuantity,
          'category': _selectedCategory.title,
        }),
      );

      print(response.body);
      print(response.statusCode);
      if (!context.mounted) {
        return;
      }

      final newAddedIteResponseData = json.decode(response.body);
      Navigator.of(context).pop(GroceryItem(
        id: newAddedIteResponseData['name'],
        name: _enteredName,
        quantity: _enteredQuantity,
        category: _selectedCategory,
      ));

      //when we have no database:-
      //" Navigator.of(context).pop(GroceryItem(
      //   id: DateTime.now().toString(),
      //   name: _enteredName,
      //   quantity: _enteredQuantity,
      //   category: _selectedCategory,
      // ));"
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //column: 1st member
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Text must be between 1-50 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ), //instead of textfield

              //column: 2nd member
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  //row: 1st element
                  Expanded(
                    child: TextFormField(
                      //maxLength: 5,
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Quantity must be a valid, poitive number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),

                  //row: 2nd element
                  const SizedBox(width: 30),

                  //row: 3rd element
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: category.value.color,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              //column: 3rd member
              const SizedBox(height: 12),

              //column 4th member
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending? null : () {
                      _formKey.currentState!.reset();
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending? null : _submitPressed,
                    child: _isSending? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator()) : const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
