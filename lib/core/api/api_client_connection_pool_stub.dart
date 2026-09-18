import 'package:dio/dio.dart';

const kHttpPoolResumeRecycleMinAway = Duration(seconds: 5);
const kHttpPoolStaleAdapterCloseDelay = Duration(seconds: 5);

void configureHttpConnectionPool(Dio dio) {}

void recycleHttpConnectionPool(Dio dio) {}
