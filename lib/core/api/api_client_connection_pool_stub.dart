import 'package:dio/dio.dart';

const kHttpPoolResumeRecycleMinAway = Duration(seconds: 8);

void configureHttpConnectionPool(Dio dio) {}

void recycleHttpConnectionPool(Dio dio) {}
