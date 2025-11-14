import 'package:drift/drift.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/models/base_main_entity_dao.dart';
import 'package:hoplixi/main_store/models/dto/bank_card_dto.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/bank_cards.dart';

part 'bank_card_dao.g.dart';

@DriftAccessor(tables: [BankCards])
class BankCardDao extends DatabaseAccessor<MainStore>
    with _$BankCardDaoMixin
    implements BaseMainEntityDao {
  BankCardDao(super.db);

  /// Получить все банковские карты
  Future<List<BankCardsData>> getAllBankCards() {
    return select(bankCards).get();
  }

  /// Получить карту по ID
  Future<BankCardsData?> getBankCardById(String id) {
    return (select(
      bankCards,
    )..where((bc) => bc.id.equals(id))).getSingleOrNull();
  }

  /// Получить карты в виде карточек
  Future<List<BankCardCardDto>> getAllBankCardCards() {
    return (select(bankCards)
          ..orderBy([(bc) => OrderingTerm.desc(bc.modifiedAt)]))
        .map(
          (bc) => BankCardCardDto(
            id: bc.id,
            name: bc.name,
            cardholderName: bc.cardholderName,
            cardType: bc.cardType?.value,
            cardNetwork: bc.cardNetwork?.value,
            bankName: bc.bankName,
            categoryName: null, // TODO: join with categories
            isFavorite: bc.isFavorite,
            isPinned: bc.isPinned,
            usedCount: bc.usedCount,
            modifiedAt: bc.modifiedAt,
          ),
        )
        .get();
  }

  /// Переключить избранное
  @override
  Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final result = await (update(bankCards)..where((b) => b.id.equals(id)))
        .write(BankCardsCompanion(isFavorite: Value(isFavorite)));

    return result > 0;
  }

  /// Переключить закрепление
  @override
  Future<bool> togglePin(String id, bool isPinned) async {
    final result = await (update(bankCards)..where((b) => b.id.equals(id)))
        .write(BankCardsCompanion(isPinned: Value(isPinned)));

    return result > 0;
  }

  /// Смотреть все карты с автообновлением
  Stream<List<BankCardsData>> watchAllBankCards() {
    return (select(
      bankCards,
    )..orderBy([(bc) => OrderingTerm.desc(bc.modifiedAt)])).watch();
  }

  /// Смотреть карты карточки с автообновлением
  Stream<List<BankCardCardDto>> watchBankCardCards() {
    return (select(
      bankCards,
    )..orderBy([(bc) => OrderingTerm.desc(bc.modifiedAt)])).watch().map(
      (bankCards) => bankCards
          .map(
            (bc) => BankCardCardDto(
              id: bc.id,
              name: bc.name,
              cardholderName: bc.cardholderName,
              cardType: bc.cardType?.value,
              cardNetwork: bc.cardNetwork?.value,
              bankName: bc.bankName,
              categoryName: null,
              isFavorite: bc.isFavorite,
              isPinned: bc.isPinned,
              usedCount: bc.usedCount,
              modifiedAt: bc.modifiedAt,
            ),
          )
          .toList(),
    );
  }

  /// Создать новую карту
  Future<String> createBankCard(CreateBankCardDto dto) {
    final companion = BankCardsCompanion.insert(
      name: dto.name,
      cardholderName: dto.cardholderName,
      cardNumber: dto.cardNumber,
      expiryMonth: dto.expiryMonth,
      expiryYear: dto.expiryYear,
      cardType: dto.cardType != null
          ? Value(CardTypeX.fromString(dto.cardType!))
          : const Value.absent(),
      cardNetwork: dto.cardNetwork != null
          ? Value(CardNetworkX.fromString(dto.cardNetwork!))
          : const Value.absent(),
      cvv: Value(dto.cvv),
      bankName: Value(dto.bankName),
      accountNumber: Value(dto.accountNumber),
      routingNumber: Value(dto.routingNumber),
      description: Value(dto.description),
      notes: Value(dto.notes),
      categoryId: Value(dto.categoryId),
    );
    return into(bankCards).insert(companion).then((id) {
      return (select(bankCards)..where((bc) => bc.id.equals(id.toString())))
          .map((bc) => bc.id)
          .getSingle();
    });
  }

  /// Обновить карту
  Future<bool> updateBankCard(String id, UpdateBankCardDto dto) async {
    final companion = BankCardsCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      cardholderName: dto.cardholderName != null
          ? Value(dto.cardholderName!)
          : const Value.absent(),
      cardNumber: dto.cardNumber != null
          ? Value(dto.cardNumber!)
          : const Value.absent(),
      expiryMonth: dto.expiryMonth != null
          ? Value(dto.expiryMonth!)
          : const Value.absent(),
      expiryYear: dto.expiryYear != null
          ? Value(dto.expiryYear!)
          : const Value.absent(),
      cardType: dto.cardType != null
          ? Value(CardTypeX.fromString(dto.cardType!))
          : const Value.absent(),
      cardNetwork: dto.cardNetwork != null
          ? Value(CardNetworkX.fromString(dto.cardNetwork!))
          : const Value.absent(),
      cvv: dto.cvv != null ? Value(dto.cvv) : const Value.absent(),
      bankName: dto.bankName != null
          ? Value(dto.bankName)
          : const Value.absent(),
      accountNumber: dto.accountNumber != null
          ? Value(dto.accountNumber)
          : const Value.absent(),
      routingNumber: dto.routingNumber != null
          ? Value(dto.routingNumber)
          : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      notes: dto.notes != null ? Value(dto.notes) : const Value.absent(),
      categoryId: dto.categoryId != null
          ? Value(dto.categoryId)
          : const Value.absent(),
      isFavorite: dto.isFavorite != null
          ? Value(dto.isFavorite!)
          : const Value.absent(),
      isArchived: dto.isArchived != null
          ? Value(dto.isArchived!)
          : const Value.absent(),
      isPinned: dto.isPinned != null
          ? Value(dto.isPinned!)
          : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await (update(
      bankCards,
    )..where((bc) => bc.id.equals(id))).write(companion);

    return rowsAffected > 0;
  }

  /// Мягкое удаление карты
  @override
  Future<bool> softDelete(String id) async {
    final rowsAffected =
        await (update(bankCards)..where((bc) => bc.id.equals(id))).write(
          const BankCardsCompanion(isDeleted: Value(true)),
        );
    return rowsAffected > 0;
  }

  /// Восстановить банковскую карту из удалённых
  @override
  Future<bool> restoreFromDeleted(String id) async {
    final rowsAffected =
        await (update(bankCards)..where((bc) => bc.id.equals(id))).write(
          const BankCardsCompanion(isDeleted: Value(false)),
        );
    return rowsAffected > 0;
  }

  /// Полное удаление банковскую карту
  @override
  Future<bool> permanentDelete(String id) async {
    final rowsAffected = await (delete(
      bankCards,
    )..where((bc) => bc.id.equals(id))).go();
    return rowsAffected > 0;
  }
}
