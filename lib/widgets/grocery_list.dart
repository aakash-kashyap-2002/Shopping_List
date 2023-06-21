import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
//import 'package:shopping_list/models/category.dart';
//import 'package:shopping_list/data/daummy_items.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'first-3c35f-default-rtdb.firebaseio.com', 'shopping-list.json');
    try {
      final response = await http.get(url);
      print(response.statusCode);
      //if status code >> 400+ then these are errors...
      if (response.statusCode > 400) {
        setState(() {
          _error = 'Failed to fetch data... Try again later.';
        });
      }
      print(response);
      print(response.body);

      //fetching data from database in this list
      final List<GroceryItem> loadedItems = [];
      //fetching code:-
      //if databse is empty we receive string 'null' in response.body which can't be decoded
      print(response.body);
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
      }

      //if successfully fetched response.body from database
      final Map<String, dynamic> listData = json.decode(response.body);
      for (final item in listData.entries) {
        final _category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;

        loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: _category,
        ));
      }

      //assigning this loaded list from database to groceryitem list to be displayed on 1st screen
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong! Please try again later.';
      });
    }
  }

  //method for + button to display add item form
  //also add submitted item into grocery items list
  void _addItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (context) => const NewItem(),
    ));

    //BEFORE USING DATABASE && Saving extra http request:-
    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  //method to remove any item swiped away from screen
  //also delete it from grocery item list
  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('first-3c35f-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode > 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet!'));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.add)),
        ],
      ),
      body: content,
    );
  }
}
