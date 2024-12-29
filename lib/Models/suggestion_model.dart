class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  // Adding a named constructor that can create an instance of Suggestion from a JSON map.
  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      json['place_id'] as String,
      json['description'] as String,
    );
  }
}