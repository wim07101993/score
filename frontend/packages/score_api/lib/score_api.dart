// Generated code - do not modify by hand
// ignore_for_file: lines_longer_than_80_chars


/// Score API
/// Version 1.0.0
///
/// Security Schemes:
/// - OAuth2: An access token of the OIDC provider the server is configured against, sent as
/// `Authorization: Bearer {token}`.
/// 
///   Authorization URL: https://auth.wvl.app/oauth/authorize
///   Token URL: https://auth.wvl.app/oauth/token
///   Scopes: score_viewer, score_editor


library;

export 'src/api_client/collections_api.dart';
export 'src/api_client/health_api.dart';
export 'src/api_client/scores_api.dart';
export 'src/api_client/sets_api.dart';
export 'src/model/collection.dart';
export 'src/model/collection_entry.dart';
export 'src/model/deleted_resource.dart';
export 'src/model/entry_view.dart';
export 'src/model/get_collections_response.dart';
export 'src/model/get_scores_response.dart';
export 'src/model/get_sets_response.dart';
export 'src/model/listed_collection.dart';
export 'src/model/listed_set.dart';
export 'src/model/musicxml.dart';
export 'src/model/problem_details.dart';
export 'src/model/problem_details_error_code_model.dart';
export 'src/model/score.dart';
export 'src/model/score_creators_model.dart';
export 'src/model/score_movement_model.dart';
export 'src/model/score_work_model.dart';
export 'src/model/set.dart';
export 'src/model/set_entry.dart';
export 'src/model/write_collection.dart';
export 'src/model/write_collection_entry.dart';
export 'src/model/write_entry_view.dart';
export 'src/model/write_set.dart';
export 'src/model/write_set_entry.dart';
export 'src/request_body/scores_score_id_put_body_request_body.dart';
export 'src/response/scores_score_id_get200_response.dart';
export 'src/response_wrapper/delete_collection_entry_response.dart';
export 'src/response_wrapper/delete_collection_response.dart';
export 'src/response_wrapper/delete_set_entry_response.dart';
export 'src/response_wrapper/delete_set_response.dart';
export 'src/response_wrapper/get_collection_response.dart';
export 'src/response_wrapper/get_score_response.dart';
export 'src/response_wrapper/get_set_response.dart';
export 'src/response_wrapper/healthz_response.dart';
export 'src/response_wrapper/list_collections_response.dart';
export 'src/response_wrapper/list_scores_response.dart';
export 'src/response_wrapper/list_sets_response.dart';
export 'src/response_wrapper/put_collection_entry_response.dart';
export 'src/response_wrapper/put_collection_entry_view_response.dart';
export 'src/response_wrapper/put_collection_response.dart';
export 'src/response_wrapper/put_score_response.dart';
export 'src/response_wrapper/put_set_entry_response.dart';
export 'src/response_wrapper/put_set_entry_view_response.dart';
export 'src/response_wrapper/put_set_response.dart';
export 'src/server/server.dart';
