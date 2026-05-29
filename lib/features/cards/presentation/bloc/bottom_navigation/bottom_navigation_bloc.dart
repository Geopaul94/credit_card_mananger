import 'package:flutter_bloc/flutter_bloc.dart';
import 'bottom_navigation_event.dart';
import 'bottom_navigation_state.dart';

class BottomNavigationBloc
    extends Bloc<BottomNavigationEvent, BottomNavigationState> {
  BottomNavigationBloc() : super(const BottomNavigationState(0)) {
    on<ChangeTabEvent>((event, emit) {
      emit(BottomNavigationState(event.index));
    });
  }
}
