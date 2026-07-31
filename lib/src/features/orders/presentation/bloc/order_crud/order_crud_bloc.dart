import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:medusa_admin/src/core/di/di.dart';
import 'package:medusa_admin/src/core/error/medusa_error.dart';
import 'package:medusa_admin/src/features/orders/domain/usecases/order/order_details_use_case.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';

part 'order_crud_event.dart';
part 'order_crud_state.dart';
part 'order_crud_bloc.freezed.dart';

@injectable
class OrderCrudBloc extends Bloc<OrderCrudEvent, OrderCrudState> {
  OrderCrudBloc(this.orderCrudUseCase) : super(const _Initial()) {
    on<_Load>(_load);
    on<_Update>(_update);
    on<_Cancel>(_cancel);
    on<_CreateFulfillment>(_createFulfillment);
    on<_CancelFulfillment>(_cancelFulfillment);
    on<_CapturePayment>(_capturePayment);
    on<_CreateShipment>(_createShipment);
  }
  Future<void> _load(_Load event, Emitter<OrderCrudState> emit) async {
    emit(const _Loading());
    final result = await orderCrudUseCase.retrieveOrder(
        id: event.id, queryParameters: event.queryParameters);
    result.when((order) => emit(_Order(order)), (error) => emit(_Error(error)));
  }

  Future<void> _update(_Update event, Emitter<OrderCrudState> emit) async {
    emit(const _Loading());
    final result = await orderCrudUseCase.updateOrder(
        id: event.id, payload: event.updateOrderReq);
    result.when((order) => emit(_Order(order)), (error) => emit(_Error(error)));
  }

  Future<void> _cancel(_Cancel event, Emitter<OrderCrudState> emit) async {
    emit(const _Loading());
    final result = await orderCrudUseCase.archiveOrder(id: event.id);
    result.when((order) => emit(_Order(order)), (error) => emit(_Error(error)));
  }

  Future<void> _createFulfillment(
      _CreateFulfillment event, Emitter<OrderCrudState> emit) async {
    emit(const _Loading());
    final result = await orderCrudUseCase.createFulfillment(
        orderId: event.orderId, payload: event.payload);
    result.when(
        (order) => emit(_Order(order)), (error) => emit(_Error(error)));
  }

  Future<void> _cancelFulfillment(
      _CancelFulfillment event, Emitter<OrderCrudState> emit) async {
    emit(const _Loading());
    final result = await orderCrudUseCase.cancelFulfillment(
        fulfillmentId: event.fulfillmentId);
    result.when(
        (fulfillment) => emit(_Fulfillment(fulfillment)), (error) => emit(_Error(error)));
  }

  Future<void> _capturePayment(
      _CapturePayment event, Emitter<OrderCrudState> emit) async {
    emit(const _Loading());
    final result = await orderCrudUseCase.capturePayment(paymentId: event.paymentId);
    result.when(
        (payment) => emit(const _PaymentCaptured()), (error) => emit(_Error(error)));
  }

  Future<void> _createShipment(
      _CreateShipment event, Emitter<OrderCrudState> emit) async {
    emit(const _Loading());
    final result = await orderCrudUseCase.createShipment(
        id: event.id, fulfillmentId: event.fulfillmentId);
    result.when(
        (order) => emit(const _ShipmentCreated()), (error) => emit(_Error(error)));
  }

  final OrderCrudUseCase orderCrudUseCase;
  static OrderCrudBloc get instance => getIt<OrderCrudBloc>();
}
