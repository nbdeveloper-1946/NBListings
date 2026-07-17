import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class RequirementsService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getRequirements({
    String? search,
    String? configurationId,
    String? status,
    String? listingTypeId,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (configurationId != null && configurationId.isNotEmpty) {
        queryParameters['configurationId'] = configurationId;
      }
      if (status != null && status != 'All') {
        queryParameters['status'] = status;
      }
      if (listingTypeId != null && listingTypeId.isNotEmpty) {
        queryParameters['listingTypeId'] = listingTypeId;
      }

      final response = await _apiClient.get(
        '/requirements',
        queryParameters: queryParameters,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createRequirement(Map<String, dynamic> requirementData) async {
    try {
      final response = await _apiClient.post('/requirements', requirementData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateRequirement(String id, Map<String, dynamic> requirementData) async {
    try {
      final response = await _apiClient.put('/requirements/$id', requirementData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteRequirement(String id) async {
    try {
      final response = await _apiClient.delete('/requirements/$id');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
