import 'package:B2B/app/core/networking/api_constans.dart';
import 'package:B2B/app/features/auth/data/models/login_request_body.dart';
import 'package:B2B/app/features/auth/data/models/login_response.dart';
import 'package:B2B/app/features/catalog/data/models/catalog_response.dart';
import 'package:B2B/app/features/home/data/models/home_dashboard_response.dart';
import 'package:B2B/app/features/ledger/data/models/ledger_response.dart';
import 'package:B2B/app/features/offers/data/models/add_offer_models/add_offer_request_body.dart';
import 'package:B2B/app/features/offers/data/models/add_offer_models/add_offer_response.dart';
import 'package:B2B/app/features/offers/data/models/offers_response.dart';
import 'package:B2B/app/features/orders/data/models/create_order/create_order_response.dart';
import 'package:B2B/app/features/orders/data/models/get_active_offers/active_offers_response.dart';
import 'package:B2B/app/features/orders/data/models/get_orders/models/orders_response.dart';
import 'package:B2B/app/features/products/data/models/store_product_response.dart';
import 'package:B2B/app/features/profile/data/models/get_profile_response.dart';
import 'package:B2B/app/features/stock/data/models/add_stock/add_stock_response.dart';
import 'package:B2B/app/features/stock/data/models/get_stock/get_stock_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) =
      _ApiService;
  @POST(ApiConstants.catalog + '/{supplierProductId}')
  Future<AddOfferResponse> addOfferToCatalog(
    @Path('supplierProductId') int supplierProductId,
    @Body() AddOfferRequestBody body,
  );

  @POST('${ApiConstants.stock}/${ApiConstants.addStock}')
  Future<AddStockResponse> addStock(
    @Body() Map<String, dynamic> request,
  );
  @PUT('${ApiConstants.orders}/{orderId}/cancel')
  Future<void> cancelOrder(
    @Path('orderId') int orderId,
  );

  @POST(ApiConstants.orders)
  Future<CreateOrderResponse> createOrder(
    @Body() Map<String, dynamic> request,
  );

  @DELETE('${ApiConstants.catalog}/{catalogId}')
  Future<void> deleteCatalogItem(
    @Path('catalogId') int catalogId,
  );

  // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||

  //orders Endpoints
  @GET(ApiConstants.catalog + '?is_active=1&per_page=15')
  Future<ActiveOffersResponse> getActiveOffers();

  // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||

  // Catalog Endpoints
  @GET(ApiConstants.catalog)
  Future<CatalogResponse> getCatalog(
    @Query('page') int page,
    @Query('is_active') bool? isActive,
    @Query('per_page') int perPage,
    @Query('search') String search,
  );

  // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||

  // Home Endpoints
  @GET(ApiConstants.homeDashboard)
  Future<HomeDashboardResponse> getHomeDashboard();
  // ledger Endpoints
  @GET(ApiConstants.ledger)
  Future<LedgerResponse> getLedger(
    @Query('page') int page,
  );

  // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||

  // offers Endpoints
  @GET(ApiConstants.offers)
  Future<OffersResponse> getOffers(
      @Query('page') int page,
      @Query('category') int category,
      @Query('status') String status,
      @Query('search') String search);
  @GET(ApiConstants.orders)
  Future<OrdersResponse> getOrders(
    @Query('status') String status,
    @Query('per_page') int perPage,
  );

  // |||||||||||||||||||||||||||||||||||||||||||||||||||||||||

  //profile Endpoints

  @GET(ApiConstants.profile)
  Future<GetProfileResponse> getProfile();

  // stock Endpoints
  @GET(ApiConstants.stock)
  Future<GetStockResponse> getStock();

  @GET('${ApiConstants.products}/{id}')
  Future<StoreProductDetailResponse> getStoreProduct(
      @Path('id') int id);

  @GET(ApiConstants.products)
  Future<StoreProductsResponse> getStoreProducts(
      @Query('page') int page);

  // Auth Endpoints
  @POST(ApiConstants.login)
  Future<LoginResponse> login(
      @Body() LoginRequestBody request);

  @POST(ApiConstants.logout)
  Future<void> logout();

  @PATCH('${ApiConstants.catalog}/{catalogId}')
  Future<void> patchCatalogItem(
    @Path('catalogId') int catalogId,
    @Body() Map<String, dynamic> request,
  );
}
