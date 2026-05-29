import 'package:equatable/equatable.dart';

class BottomNavigationState extends Equatable {
  final int currentIndex;

  const BottomNavigationState(this.currentIndex);

  @override
  List<Object> get props => [currentIndex];
}
