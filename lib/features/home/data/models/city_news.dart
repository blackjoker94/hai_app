import 'package:equatable/equatable.dart';

class CityNews extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  const CityNews({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrl];
}