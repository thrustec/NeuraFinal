import '../models/comparison_report.dart';

class ReportService {
  static final List<ComparisonReport> _reports = [];

  static void addReport(ComparisonReport report) {
    _reports.insert(0, report);
  }

  static List<ComparisonReport> getReports() {
    return _reports;
  }
}