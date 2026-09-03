import 'package:flutter_test/flutter_test.dart';
import 'package:hai_app/features/home/data/models/report_model.dart';

void main() {
  group('Report model tests', () {
    test('isCompleted returns true when status is تم التصليح (Dashboard status)', () {
      const report = Report(
        id: 'rep_123',
        rawTitle: 'trash',
        imageUrl: 'https://example.com/img.jpg',
        status: 'تم التصليح',
        createdAt: '2026-09-01T12:00:00Z',
      );

      expect(report.isCompleted, isTrue);
    });

    test('isCompleted returns true when status is legacy تم حل المشكلة يا بطل', () {
      const report = Report(
        id: 'rep_124',
        rawTitle: 'flood',
        imageUrl: 'https://example.com/img.jpg',
        status: 'تم حل المشكلة يا بطل',
        createdAt: '2026-09-01T12:00:00Z',
      );

      expect(report.isCompleted, isTrue);
    });

    test('isCompleted returns false when status is قيد المراجعه', () {
      const report = Report(
        id: 'rep_125',
        rawTitle: 'road',
        imageUrl: 'https://example.com/img.jpg',
        status: 'قيد المراجعه',
        createdAt: '2026-09-01T12:00:00Z',
      );

      expect(report.isCompleted, isFalse);
    });

    test('isCompleted returns false when status is تحت التصليح', () {
      const report = Report(
        id: 'rep_126',
        rawTitle: 'road',
        imageUrl: 'https://example.com/img.jpg',
        status: 'تحت التصليح',
        createdAt: '2026-09-01T12:00:00Z',
      );

      expect(report.isCompleted, isFalse);
    });
  });
}
