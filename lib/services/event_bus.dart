import 'dart:async';
import '../models/order_model.dart';

/// A simple publish-subscribe Event Bus for decoupling modules.
class EventBus {
  EventBus._();
  static final EventBus instance = EventBus._();

  final _streamController = StreamController<dynamic>.broadcast();

  /// Listen for events of type [T].
  Stream<T> on<T>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  /// Fire an event to all active listeners.
  void fire(dynamic event) {
    _streamController.add(event);
  }
}

// --- Specific Application Events ---

class OrderPlacedEvent {
  final OrderModel order;
  OrderPlacedEvent(this.order);
}

class OrderStatusChangedEvent {
  final String orderId;
  final String status;
  OrderStatusChangedEvent(this.orderId, this.status);
}

class SecurityAlertEvent {
  final String message;
  SecurityAlertEvent(this.message);
}

class ReportReadyEvent {
  final String filePath;
  ReportReadyEvent(this.filePath);
}

class ProductPriceDropEvent {
  final String productName;
  final double originalPrice;
  final double newPrice;
  ProductPriceDropEvent(this.productName, this.originalPrice, this.newPrice);
}
