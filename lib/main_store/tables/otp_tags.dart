import 'package:drift/drift.dart';
import 'otps.dart';
import 'tags.dart';

@DataClassName('OtpsTagsData')
class OtpsTags extends Table {
  TextColumn get otpId =>
      text().references(Otps, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {otpId, tagId};

  @override
  String get tableName => 'otp_tags';
}
