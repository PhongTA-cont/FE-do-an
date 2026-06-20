import 'package:equatable/equatable.dart';

abstract class ObdDashboardEvent extends Equatable {
  const ObdDashboardEvent();

  @override
  List<Object?> get props => [];
}

class ObdDashboardStarted extends ObdDashboardEvent {
  const ObdDashboardStarted();
}

class ObdRequestOnePressed extends ObdDashboardEvent {
  const ObdRequestOnePressed(this.request);

  final String request;

  @override
  List<Object?> get props => [request];
}

class ObdRequestAllPressed extends ObdDashboardEvent {
  const ObdRequestAllPressed();
}

class ObdAutoPollingToggled extends ObdDashboardEvent {
  const ObdAutoPollingToggled();
}

class ObdRawResponseReceived extends ObdDashboardEvent {
  const ObdRawResponseReceived(this.raw);

  final String raw;

  @override
  List<Object?> get props => [raw];
}

class ObdLogsCleared extends ObdDashboardEvent {
  const ObdLogsCleared();
}
