import 'package:flutter/material.dart';

import '../API/place_provider_api.dart';
import '../Models/suggestion_model.dart';


class AddressSearch extends SearchDelegate<Suggestion> {
  final PlaceApiProvider placeApiProvider = PlaceApiProvider();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Suggestion('', '')); // Return an empty suggestion on back press
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox(); // This can be modified based on how you want to display the selected result.
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isNotEmpty) {
      return FutureBuilder<List<Suggestion>>(
        future: placeApiProvider.fetchSuggestions(context, query), // Removed the context parameter
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemBuilder: (context, index) => ListTile(
                minLeadingWidth: 0,
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.blue,
                ),
                title: Text(
                  snapshot.data![index].description,
                ),
                onTap: () {
                  close(context, snapshot.data![index]); // Return the selected suggestion
                },
              ),
              itemCount: snapshot.data!.length,
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          // By default, show a loading spinner.
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    } else {
      // Show a message when the query is empty
      return Center(child: Text("Start typing to search..."));
    }
  }
}
