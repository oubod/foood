// lib/services/order_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/main.dart';
import 'package:audioplayers/audioplayers.dart';

class OrderService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeOrderId;
  String? _activeOrderStatus;
  StreamSubscription? _orderSubscription;

  String? get activeOrderId => _activeOrderId;
  String? get activeOrderStatus => _activeOrderStatus;
  bool get isTrackingOrder => _activeOrderId != null;

  void startTrackingOrder(String orderId) {
    // If we're already tracking an order, stop it first
    stopTracking();

    _activeOrderId = orderId;
    _orderSubscription = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen((data) {
          if (data.isNotEmpty) {
            final newStatus = data.first['status'];
            // Check if the status has actually changed before notifying
            if (newStatus != _activeOrderStatus) {
              _activeOrderStatus = newStatus;
              // Play sound on status change
              _audioPlayer.play(AssetSource('audio/notification.mp3'));
              print('Order status updated:  [32m$_activeOrderStatus [0m');
              notifyListeners(); // This will trigger UI updates
            }
          }
        });
  }

  void stopTracking() {
    _orderSubscription?.cancel();
    _activeOrderId = null;
    _activeOrderStatus = null;
    _orderSubscription = null;
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}