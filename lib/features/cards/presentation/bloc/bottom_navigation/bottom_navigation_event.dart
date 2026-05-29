import 'package:equatable/equatable.dart';

abstract class BottomNavigationEvent extends Equatable {
  const BottomNavigationEvent();

  @override
  List<Object> get props => [];
}

class ChangeTabEvent extends BottomNavigationEvent {
  final int index;

  const ChangeTabEvent(this.index);

  @override
  List<Object> get props => [index];
}
