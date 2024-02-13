import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loveat',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: FoodViewerPage(),
    );
  }
}

class FoodViewerPage extends StatefulWidget {
  const FoodViewerPage({Key? key}) : super(key: key);

  @override
  _FoodViewerPageState createState() => _FoodViewerPageState();
}

class _FoodViewerPageState extends State<FoodViewerPage> {
  late List<Food> _foods;
  int _currentIdx = 0;
  List<Food> _favoriteFoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFoods();
  }

  Future<void> _fetchFoods() async {
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s='));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final meals = data['meals'] as List<dynamic>;
      setState(() {
        _foods = meals.map((meal) => Food.fromJson(meal)).toList();
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load foods');
    }
  }

  void _nextFood() {
    setState(() {
      _currentIdx = (_currentIdx + 1) % _foods.length;
    });
  }

  void _addFavorite(Food food) {
    setState(() {
      _currentIdx = (_currentIdx + 1) % _foods.length;
      _favoriteFoods.add(food);
    });
  }

  void _removeFavorite(Food food) {
    setState(() {
      _favoriteFoods.remove(food);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Center(child: Text('Loveat',style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),)),
      ),
      body: Container(
        color: Color(0xFFE1BEE7), // Fondo morado suave
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: Container(
                          color: Color(0xFFCE93D8), // Color de fondo para destacar
                          child: Center(
                            child: Text(
                              'Name: ${_foods[_currentIdx].name}',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: Image.network(_foods[_currentIdx].imageUrl),
                      ),
                      SizedBox(
                        height: 20,
                        child: Container(
                          color: Color(0xFFCE93D8), // Color de fondo para destacar
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _nextFood,
                          child: Text('Next'),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        height:60  ,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _addFavorite(_foods[_currentIdx]);
                          },
                          icon: Icon(Icons.favorite),
                          label: Text('Add to Favorites'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoriteFoodsPage(favoriteFoods: _favoriteFoods, removeFavorite: _removeFavorite)),
              );
            },
            tooltip: 'Favorite Foods',
            child: Icon(Icons.favorite),
            backgroundColor: Colors.purple,
          ),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FoodViewerPage()),
              );
            },
            tooltip: 'Refresh',
            child: Icon(Icons.refresh),
            backgroundColor: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class FavoriteFoodsPage extends StatefulWidget {
  final List<Food> favoriteFoods;
  final void Function(Food) removeFavorite;

  const FavoriteFoodsPage({Key? key, required this.favoriteFoods, required this.removeFavorite}) : super(key: key);

  @override
  _FavoriteFoodsPageState createState() => _FavoriteFoodsPageState();
}

class _FavoriteFoodsPageState extends State<FavoriteFoodsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Center(child: Text('Favorite Foods')),
      ),
      body: Container(
        color: Color(0xFFE1BEE7), // Fondo morado suave
        child: ListView.builder(
          itemCount: widget.favoriteFoods.length,
          itemBuilder: (context, index) {
            final food = widget.favoriteFoods[index];
            return ListTile(
              leading: Image.network(food.imageUrl),
              title: Text(food.name),
              subtitle: Text(food.ingredients),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    widget.removeFavorite(food);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Food removed from favorites'),
                  ));
                },
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        tooltip: 'Home',
        child: Icon(Icons.home),
        backgroundColor: Colors.purple,
      ),
    );
  }
}

class Food {
  final String name;
  final String imageUrl;
  final String ingredients;

  Food({required this.name, required this.imageUrl, required this.ingredients});

  factory Food.fromJson(Map<String, dynamic> json) {
    String formattedIngredients = '';
    for (int i = 1; i <= 20; i++) {
      if (json['strIngredient$i'] != null && json['strIngredient$i'] != '') {
        formattedIngredients += '${json['strIngredient$i']} - ${json['strMeasure$i']}\n';
      }
    }
    return Food(
      name: json['strMeal'],
      imageUrl: json['strMealThumb'],
      ingredients: formattedIngredients,
    );
  }
}







