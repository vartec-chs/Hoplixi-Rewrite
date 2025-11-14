import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/otp_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/otps.dart';

part 'otp_dao.g.dart';

@DriftAccessor(tables: [Otps])
class OtpDao extends DatabaseAccessor<MainStore>
    with _$OtpDaoMixin
    implements BaseMainEntityDao {
  OtpDao(super.db);

  /// Получить все OTP
  Future<List<OtpsData>> getAllOtps() {
    return select(otps).get();
  }

  /// Получить OTP по ID
  Future<OtpsData?> getOtpById(String id) {
    return (select(otps)..where((o) => o.id.equals(id))).getSingleOrNull();
  }

  /// Получить OTP в виде карточек
  Future<List<OtpCardDto>> getAllOtpCards() {
    return (select(otps)..orderBy([(o) => OrderingTerm.desc(o.modifiedAt)]))
        .map(
          (o) => OtpCardDto(
            id: o.id,
            issuer: o.issuer,
            accountName: o.accountName,
            type: o.type.value,
            digits: o.digits,
            period: o.period,
            categoryName: null, // TODO: join with categories
            isFavorite: o.isFavorite,
            isPinned: o.isPinned,
            usedCount: o.usedCount,
            modifiedAt: o.modifiedAt,
          ),
        )
        .get();
  }

  // toggle favorite
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      OtpsCompanion(isFavorite: Value(isFavorite)),
    );

    return result > 0;
  }

  // toggle pin
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      OtpsCompanion(isPinned: Value(isPinned)),
    );

    return result > 0;
  }

  // toggle archive
  @override
  Future<bool> toggleArchive(String id, bool isArchived) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      OtpsCompanion(isArchived: Value(isArchived)),
    );

    return result > 0;
  }

  /// Смотреть все OTP с автообновлением
  Stream<List<OtpsData>> watchAllOtps() {
    return (select(
      otps,
    )..orderBy([(o) => OrderingTerm.desc(o.modifiedAt)])).watch();
  }

  /// Смотреть OTP карточки с автообновлением
  Stream<List<OtpCardDto>> watchOtpCards() {
    return (select(
      otps,
    )..orderBy([(o) => OrderingTerm.desc(o.modifiedAt)])).watch().map(
      (otps) => otps
          .map(
            (o) => OtpCardDto(
              id: o.id,
              issuer: o.issuer,
              accountName: o.accountName,
              type: o.type.value,
              digits: o.digits,
              period: o.period,
              categoryName: null,
              isFavorite: o.isFavorite,
              isPinned: o.isPinned,
              usedCount: o.usedCount,
              modifiedAt: o.modifiedAt,
            ),
          )
          .toList(),
    );
  }

  /// Удалить OTP (мягкое удаление)
  @override
  Future<bool> softDelete(String id) async {
    final result = await (update(otps)..where((o) => o.id.equals(id))).write(
      const OtpsCompanion(isDeleted: Value(true)),
    );
    return result > 0;
  }

  /// Восстановить OTP из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected = await (update(otps)..where((o) => o.id.equals(id)))
        .write(const OtpsCompanion(isDeleted: Value(false)));
    return rowsAffected > 0;
  }

  /// Полное удаление OTP
  @override
  Future<bool> permanentDelete(String id) async {
    final rowsAffected = await (delete(
      otps,
    )..where((o) => o.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Создать новый OTP
  Future<String> createOtp(CreateOtpDto dto) {
    final companion = OtpsCompanion.insert(
      type: Value(OtpTypeX.fromString(dto.type)),
      secret: Uint8List.fromList(dto.secret),
      secretEncoding: Value(SecretEncodingX.fromString(dto.secretEncoding)),
      issuer: Value(dto.issuer),
      accountName: Value(dto.accountName),
      notes: Value(dto.notes),
      algorithm: Value(AlgorithmOtpX.fromString(dto.algorithm ?? 'SHA1')),
      digits: Value(dto.digits ?? 6),
      period: Value(dto.period ?? 30),
      counter: Value(dto.counter),
      categoryId: Value(dto.categoryId),
      passwordId: Value(dto.passwordId),
    );
    return into(otps).insert(companion).then((id) {
      return (select(
        otps,
      )..where((o) => o.id.equals(id.toString()))).map((o) => o.id).getSingle();
    });
  }

  /// Обновить OTP
  Future<bool> updateOtp(String id, UpdateOtpDto dto) {
    final companion = OtpsCompanion(
      issuer: dto.issuer != null ? Value(dto.issuer) : const Value.absent(),
      accountName: dto.accountName != null
          ? Value(dto.accountName)
          : const Value.absent(),
      notes: dto.notes != null ? Value(dto.notes) : const Value.absent(),
      algorithm: dto.algorithm != null
          ? Value(AlgorithmOtpX.fromString(dto.algorithm!))
          : const Value.absent(),
      digits: dto.digits != null ? Value(dto.digits!) : const Value.absent(),
      period: dto.period != null ? Value(dto.period!) : const Value.absent(),
      counter: dto.counter != null ? Value(dto.counter) : const Value.absent(),
      categoryId: dto.categoryId != null
          ? Value(dto.categoryId)
          : const Value.absent(),
      passwordId: dto.passwordId != null
          ? Value(dto.passwordId)
          : const Value.absent(),
      isFavorite: dto.isFavorite != null
          ? Value(dto.isFavorite!)
          : const Value.absent(),
      isPinned: dto.isPinned != null
          ? Value(dto.isPinned!)
          : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );
    return (update(otps)..where((o) => o.id.equals(id)))
        .write(companion)
        .then((count) => count > 0);
  }
}
