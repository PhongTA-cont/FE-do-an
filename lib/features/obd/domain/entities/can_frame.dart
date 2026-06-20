import 'package:equatable/equatable.dart';

class CanFrame extends Equatable {
  const CanFrame({required this.id, required this.data});

  final int id;
  final List<int> data;

  @override
  List<Object?> get props => [id, data];
}
