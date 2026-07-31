part of 'order_crud_bloc.dart';

@freezed
sealed class OrderCrudEvent with _$OrderCrudEvent {
  const factory OrderCrudEvent.load(String id,
      {Map<String, dynamic>? queryParameters}) = _Load;
  const factory OrderCrudEvent.update(
      String id, PostOrdersOrderReq updateOrderReq) = _Update;
  const factory OrderCrudEvent.cancel(String id) = _Cancel;
  const factory OrderCrudEvent.createFulfillment(
      String orderId, PostOrdersFulfillmentsReq payload) = _CreateFulfillment;
  const factory OrderCrudEvent.cancelFulfillment(
      String id, String fulfillmentId) = _CancelFulfillment;
  const factory OrderCrudEvent.capturePayment(String paymentId) = _CapturePayment;
  const factory OrderCrudEvent.createShipment(String id, String fulfillmentId) = _CreateShipment;
}
