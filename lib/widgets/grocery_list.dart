import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping/data/categories.dart';

import 'package:shopping/models/grocery_item.dart';
import 'package:shopping/widgets/new_item.dart';

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
    _loadItems();
    super.initState();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-a1fcf-default-rtdb.firebaseio.com', 'shopping.json');
    //try and catch syntax is used to handle errors.
    // Try: This is where you put the code that you think might cause an error
    try {
      //get gets the data from firebase DB
      //we are storing that future get value on response
      final response = await http.get(url);
      //throw exception will handle error if errors are not related to status code etc
      //like if you lost internet connection etc.
      // throw Exception('An error occured');
      //this if condition will run only if we got an error such as 404 etc,
      //error could be because of wrong url, database offline etc.
      //status code tells the number such as 200,404 etc
      //if its above 400 then there is an error because all these 400,s and 500s are error codes
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data, please try again later';
        });
      }
      //this if will run if there is no data in backend, so it will just show a loading spinner in our case
      //to avoid that, we need to check if there is a data or not in backend.
      //we are quoting null is '' because firebase return null as String if no data is there/
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      //json.decode will make the items fetched by firebase according to dart
      //in other words it will convert firebase data into dart data
      final Map<String, dynamic> listData = json.decode(response.body);
      //this loop will store all the value of map into items.
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            category: category,
            name: item.value['name'],
            quantity: item.value['quantity'],
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    }
    //  If an error occurs within the "try" block, Dart will jump to the "catch" block
    // instead of stopping the whole program. Here, you can handle the error gracefully,
    //like showing a message to the user. catch contains a variable provided by flutter
    //its the error itself, you can name it any thing
    catch (err) {
      setState(() {
        _error = 'Something went wrong, please try agian later';
      });
    }
  }

  //async and await will wait once a psuhing to the next screen mathod is complete
  //once it is complete, it will story a value(Grocery item in this case) provided by next screen(NewItem)
  //whenever next screen goes back using pop.
  void _addNewItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });

    _loadItems();

    //if new item got by form is null then return nothing
    //   if (_newItem == null) {
    //     return;
    //   }
    //   //if its not null then add that groceryitem in _groceryItems's list
    //   setState(() {
    //     _groceryItems.add(_newItem);
    //   });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    //we are going to use this url for deleting from backend whenever we swipe on ui
    //deleting requires a url, but not complete url, just a specific id of item
    //because we dont want to delete the complete folder, instead just an specific item.
    final url = Uri.https('flutter-prep-a1fcf-default-rtdb.firebaseio.com',
        'shopping/${item.id}.json');
    final response = await http.delete(url);
    //this block will undo deletion if error happens, such as item is deleted from
    //ui but not from backend
    if (response.statusCode >= 400) {
      setState(() {
        //insert will undo the item at exact same position again.
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet'),
    );
    if (_isLoading) {
      //CircularProgressIndicator creates a loading spinner
      content = const Center(child: CircularProgressIndicator());
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: ((context, index) {
          return Dismissible(
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            //the unique key can be id
            key: ValueKey(_groceryItems[index].id),
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                height: 24,
                width: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(
                _groceryItems[index].quantity.toString(),
              ),
            ),
          );
        }),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addNewItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: content);
  }
}
