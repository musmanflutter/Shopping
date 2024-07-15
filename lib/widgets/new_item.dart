import 'dart:convert';

import 'package:flutter/material.dart';
//http package is used to send , receive data to server
//as after package name tells dart that all items got by package should be bundled
//in this object named http. it could be anyname we want
import 'package:http/http.dart' as http;

import 'package:shopping/data/categories.dart';
import 'package:shopping/models/category.dart';
import 'package:shopping/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  //globalkey creates a global key object.
  //this globalkey will ensure whenevever this key is used,
  //it will keep that widget's state previos whenever build is called
  //means a widget wont rebuild if we are using this global key inside that.
  //since globalkey is generic, we tell that this will be used in formState.
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  //since backend doesnt happen instantly means it takes few seconds
  //for firebase to take, store data, we need to make sure we perform other
  //operation after it has been done succesfuly.
  //therefore we are using async await syntax,(in repalcement of .then method)
  //to make sure we do whatever(eg get data) after it has stored succesfully.
  void _saveItem() async {
    //we are able to the state of form key.
    //we tell dart that current state cant be null because we set
    // key:_formkey in form.
    //.validate goes to all textforms and runs all validate method
    //it checks if data is valid then this if will be executed
    if (_formKey.currentState!.validate()) {
      //.save() ensures to save the user input by onSaved in Form
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      //Uri provids many contructors for creating a url
      //.https constructor points https as backend
      //we removed https:// part from url because it will be added automatically
      //by .https method
      //https constructor takes two arguments, a url and a path
      //path is upto us, we can use any name for path
      //we need to add .json after path name when using it. its required by firebase not by flutter/dart
      final url = Uri.https(
          'flutter-prep-a1fcf-default-rtdb.firebaseio.com', 'shopping.json');
      //now we are using that object(http here)
      //.post is a method for pushing new data to the server
      //it takes a url and a named argument headers and a body.

      final response = await http.post(
        url,
        //headers are just some meta data that can be send
        headers: {'Content-type': 'application/json'},
        //body defines the data that should be attaached to ongoing requests.
        //body wants data that is formatted as json
        //.json formats data as json
        //encode: encodes the data to  json formatted data.
        //encode needs a data that can be converted
        body: json.encode(
          {
            //we are using_SelectedCategory with title because sending a map(_selectedCategory) might cause an error
            //we dont need to send id because firebase will create it for our selves.
            'category': _selectedCategory.title,
            'name': _enteredName,
            'quantity': _enteredQuantity,
          },
        ),
      );
      //since we used async/ await syntax, we got the future value(response) here.
      //we can use that future value now
      //same could be done using .then as well(it will give us future value too)
      //json.decode will decode data into dart

      final Map<String, dynamic> resData = json.decode(response.body);

      //we are using this logic so that we can use context in pop by recommended way
      //context shows location of a widget in widget tree
      //we are checking if a widget is mounted or not means either its part of widget tree or not
      //because in flutter life cycle, widgets often get removed from widget tree when performing opertaions
      //such as navigating to next screen, so previous screen gets removed from widget tree
      //also  performing opoeration on server, once its complete(data sent in this case) its not part of widget tree
      //so we cant use its context becuase its mounted
      if (!context.mounted) {
        return;
      }

      //its not recommend by flutter to use buildcontext is async as we are using in poping.
      //the reason is flutter doesnt know whether the context is still the same as before awaited
      //all geocery item datat will be passed to previous screen.(Grocery List screen in this case)
      if (!mounted) return;
      Navigator.of(context).pop(
        GroceryItem(
          id: resData['name'],
          category: _selectedCategory,
          name: _enteredName,
          quantity: _enteredQuantity,
        ),
      );
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
        //form is helpful for getting user inputs and provide alot of functionalities for that.
        //its not necessary to be used for getting user inputs as discussed in expanse list app
        //but this widget is helpful for creating more complex user input form.
        child: Form(
            //this ensures that validation method works well for all forms.
            key: _formKey,
            child: Column(
              children: [
                //TextFormField is just like textField widget but more suitable in Form widget.
                //because it allows to use more features of Form .
                TextFormField(
                  maxLength: 50,
                  decoration: const InputDecoration(
                    label: Text('Name'),
                  ),
                  //validator is used for showing some outputs based on userinput
                  ////like if a userinput is empt, it will show an error message
                  //it takes a String value (passed automatically by flutter) which is value in this case.
                  //and it returns a String passed by us(demo in this case)
                  validator: (value) {
                    //if value is invalid then it will return an error message
                    if (value == null ||
                        value.isEmpty ||
                        value.trim().length <= 1 ||
                        value.trim().length > 50) {
                      return 'Must be bewteen 1 and 50 characters';
                    }
                    //if value is valid then it will return null means we do have valid input
                    return null;
                  },
                  //onSaved saves the user input
                  //it takes a function, function takes a value(provided by flutter automatically)
                  //that value is user input(flutter pass that value here.)
                  onSaved: (newValue) {
                    //here the value will be stored in a variable _enteredName
                    _enteredName = newValue!;
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          label: Text('Quantity'),
                        ),
                        keyboardType: TextInputType.number,
                        //initialValue will be displayed on the text form field
                        initialValue: _enteredQuantity.toString(),
                        validator: (value) {
                          //if value is invalid then it will return an error message
                          if (value == null ||
                              value.isEmpty ||
                              //.tryparse returns nulll if it fails to convert String into int like 1f will return null
                              int.tryParse(value) == null ||
                              int.tryParse(value)! <= 0) {
                            return 'Must be a valid, positive number';
                          }
                          //if value is valid then it will return null means we do have valid input
                          return null;
                        },
                        onSaved: (newValue) {
                          _enteredQuantity = int.parse(newValue!);
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    //DropdownButtonFormField is just like normal dropdownbutton
                    //just a speciacl widget more suitable in Form.
                    Expanded(
                      child: DropdownButtonFormField(
                          value: _selectedCategory,
                          items: [
                            //.entries changes map into list(categories was maps.)
                            for (final category in categories.entries)
                              DropdownMenuItem(
                                  value: category.value,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        color: category.value.color,
                                      ),
                                      const SizedBox(width: 6),
                                      //.value means data in key
                                      //.key means keys
                                      //we are able to use key/value here because we converted map
                                      //into list, so we can get acces to those map's keys and values.
                                      //every category value contains 2 things, a title, and a color
                                      //so we used title here.
                                      Text(category.value.title),
                                    ],
                                  ))
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          }),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: _isSending
                            ? null
                            : () {
                                //reset will reset the current state of form(all values back to normal)
                                _formKey.currentState!.reset();
                              },
                        child: const Text('Reset')),
                    ElevatedButton(
                      onPressed: _isSending ? null : _saveItem,
                      child: _isSending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Add item'),
                    )
                  ],
                )
              ],
            )),
      ),
    );
  }
}
