import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/category_manager/features/category_picker/category_picker.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_layout.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/form_close_button.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/sidebar_controller.dart';
import 'package:hoplixi/features/password_manager/tags_manager/features/tags_picker/tags_picker.dart';
import 'package:hoplixi/main_store/models/enums/entity_types.dart';
import 'package:hoplixi/shared/ui/button.dart';
import 'package:hoplixi/shared/ui/text_field.dart';
import '../providers/bank_card_form_provider.dart';

/// Экран формы создания/редактирования банковской карты
class BankCardFormScreen extends ConsumerStatefulWidget {
  const BankCardFormScreen({super.key, this.bankCardId});

  /// ID банковской карты для редактирования (null = режим создания)
  final String? bankCardId;

  @override
  ConsumerState<BankCardFormScreen> createState() => _BankCardFormScreenState();
}

class _BankCardFormScreenState extends ConsumerState<BankCardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _cardholderNameController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryMonthController;
  late final TextEditingController _expiryYearController;
  late final TextEditingController _cvvController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _routingNumberController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  late final FocusNode _cvvFocusNode;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _cardholderNameController = TextEditingController();
    _cardNumberController = TextEditingController();
    _expiryMonthController = TextEditingController();
    _expiryYearController = TextEditingController();
    _cvvController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _routingNumberController = TextEditingController();
    _descriptionController = TextEditingController();
    _notesController = TextEditingController();

    _cvvFocusNode = FocusNode();
    _cvvFocusNode.addListener(_onCvvFocusChange);

    // Инициализация формы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(bankCardFormProvider.notifier);
      if (widget.bankCardId != null) {
        notifier.initForEdit(widget.bankCardId!);
      } else {
        notifier.initForCreate();
      }
    });
  }

  void _onCvvFocusChange() {
    ref
        .read(bankCardFormProvider.notifier)
        .setCvvFocused(_cvvFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();

    _cvvFocusNode.removeListener(_onCvvFocusChange);
    _cvvFocusNode.dispose();

    super.dispose();
  }

  void _handleSave() async {
    final notifier = ref.read(bankCardFormProvider.notifier);
    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      Toaster.success(
        title: widget.bankCardId != null ? 'Карта обновлена' : 'Карта создана',
        description: 'Изменения успешно сохранены',
      );
      context.pop(true);
    } else {
      Toaster.error(
        title: 'Ошибка сохранения',
        description: 'Не удалось сохранить карту',
      );
    }
  }

  /// Форматирование номера карты для отображения
  String _formatCardNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleanNumber[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(bankCardFormProvider);

    // Синхронизация контроллеров с состоянием при загрузке данных
    if (state.isEditMode && !state.isLoading) {
      if (_nameController.text != state.name) {
        _nameController.text = state.name;
      }
      if (_cardholderNameController.text != state.cardholderName) {
        _cardholderNameController.text = state.cardholderName;
      }
      if (_cardNumberController.text != state.cardNumber) {
        _cardNumberController.text = state.cardNumber;
      }
      if (_expiryMonthController.text != state.expiryMonth) {
        _expiryMonthController.text = state.expiryMonth;
      }
      if (_expiryYearController.text != state.expiryYear) {
        _expiryYearController.text = state.expiryYear;
      }
      if (_cvvController.text != state.cvv) {
        _cvvController.text = state.cvv;
      }
      if (_bankNameController.text != state.bankName) {
        _bankNameController.text = state.bankName;
      }
      if (_accountNumberController.text != state.accountNumber) {
        _accountNumberController.text = state.accountNumber;
      }
      if (_routingNumberController.text != state.routingNumber) {
        _routingNumberController.text = state.routingNumber;
      }
      if (_descriptionController.text != state.description) {
        _descriptionController.text = state.description;
      }
      if (_notesController.text != state.notes) {
        _notesController.text = state.notes;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bankCardId != null
              ? 'Редактировать карту'
              : 'Новая банковская карта',
        ),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
        leading: FormCloseButton(),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // Визуализация кредитной карты
                        CreditCardWidget(
                          cardNumber: _formatCardNumber(state.cardNumber),
                          expiryDate: state.formattedExpiryDate,
                          cardHolderName: state.cardholderName.isEmpty
                              ? 'CARD HOLDER'
                              : state.cardholderName.toUpperCase(),
                          cvvCode: state.cvv,
                          showBackView: state.isCvvFocused,
                          onCreditCardWidgetChange: (brand) {},
                          bankName: state.bankName.isEmpty
                              ? null
                              : state.bankName,
                          cardBgColor: colorScheme.primary,
                          obscureCardNumber: false,
                          obscureCardCvv: false,
                          labelCardHolder: 'CARD HOLDER',
                          labelValidThru: 'VALID\nTHRU',
                          isHolderNameVisible: true,
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          isChipVisible: true,
                          isSwipeGestureEnabled: true,
                          animationDuration: const Duration(milliseconds: 500),
                          frontCardBorder: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                          backCardBorder: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                          padding: 16,
                        ),

                        const SizedBox(height: 24),

                        // Название карты *
                        TextField(
                          controller: _nameController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Название карты *',
                            hintText: 'Например: Основная карта',
                            errorText: state.nameError,
                            prefixIcon: const Icon(Icons.label_outline),
                          ),
                          onChanged: (value) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setName(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Имя владельца *
                        TextField(
                          controller: _cardholderNameController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Имя владельца *',
                            hintText: 'Как на карте',
                            errorText: state.cardholderNameError,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setCardholderName(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Номер карты *
                        TextField(
                          controller: _cardNumberController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Номер карты *',
                            hintText: '0000 0000 0000 0000',
                            errorText: state.cardNumberError,
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(19),
                            _CardNumberInputFormatter(),
                          ],
                          onChanged: (value) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setCardNumber(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Срок действия
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _expiryMonthController,
                                decoration: primaryInputDecoration(
                                  context,
                                  labelText: 'Месяц *',
                                  hintText: 'MM',
                                  errorText: state.expiryMonthError,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                onChanged: (value) {
                                  ref
                                      .read(bankCardFormProvider.notifier)
                                      .setExpiryMonth(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _expiryYearController,
                                decoration: primaryInputDecoration(
                                  context,
                                  labelText: 'Год *',
                                  hintText: 'YYYY',
                                  errorText: state.expiryYearError,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onChanged: (value) {
                                  ref
                                      .read(bankCardFormProvider.notifier)
                                      .setExpiryYear(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _cvvController,
                                focusNode: _cvvFocusNode,
                                decoration: primaryInputDecoration(
                                  context,
                                  labelText: 'CVV',
                                  hintText: '***',
                                  errorText: state.cvvError,
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                onChanged: (value) {
                                  ref
                                      .read(bankCardFormProvider.notifier)
                                      .setCvv(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Тип карты и Сеть
                        Row(
                          children: [
                            Expanded(
                              child: _CardTypeDropdown(
                                value: state.cardType,
                                onChanged: (value) {
                                  ref
                                      .read(bankCardFormProvider.notifier)
                                      .setCardType(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CardNetworkDropdown(
                                value: state.cardNetwork,
                                onChanged: (value) {
                                  ref
                                      .read(bankCardFormProvider.notifier)
                                      .setCardNetwork(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Название банка
                        TextField(
                          controller: _bankNameController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Название банка',
                            hintText: 'Например: Сбербанк',
                            prefixIcon: const Icon(
                              Icons.account_balance_outlined,
                            ),
                          ),
                          onChanged: (value) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setBankName(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Номер счета и Routing number
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _accountNumberController,
                                decoration: primaryInputDecoration(
                                  context,
                                  labelText: 'Номер счета',
                                  hintText: 'Опционально',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  ref
                                      .read(bankCardFormProvider.notifier)
                                      .setAccountNumber(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _routingNumberController,
                                decoration: primaryInputDecoration(
                                  context,
                                  labelText: 'Routing Number',
                                  hintText: 'Опционально',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  ref
                                      .read(bankCardFormProvider.notifier)
                                      .setRoutingNumber(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Категория
                        CategoryPickerField(
                          selectedCategoryId: state.categoryId,
                          selectedCategoryName: state.categoryName,
                          label: 'Категория',
                          hintText: 'Выберите категорию',
                          filterByType: CategoryType.bankCard,
                          onCategorySelected: (categoryId, categoryName) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setCategory(categoryId, categoryName);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Теги
                        TagPickerField(
                          selectedTagIds: state.tagIds,
                          selectedTagNames: state.tagNames,
                          label: 'Теги',
                          hintText: 'Выберите теги',
                          filterByType: TagType.bankCard,
                          onTagsSelected: (tagIds, tagNames) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setTags(tagIds, tagNames);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Описание
                        TextField(
                          controller: _descriptionController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Описание',
                            hintText: 'Краткое описание',
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setDescription(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Заметки
                        TextField(
                          controller: _notesController,
                          decoration: primaryInputDecoration(
                            context,
                            labelText: 'Заметки',
                            hintText: 'Дополнительные заметки',
                          ),
                          maxLines: 4,
                          onChanged: (value) {
                            ref
                                .read(bankCardFormProvider.notifier)
                                .setNotes(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Закрепленные кнопки снизу
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: SmoothButton(
                            label: 'Отмена',
                            onPressed: state.isSaving
                                ? null
                                : () => context.pop(false),
                            type: SmoothButtonType.outlined,
                            variant: SmoothButtonVariant.normal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SmoothButton(
                            label: widget.bankCardId != null
                                ? 'Сохранить'
                                : 'Создать',
                            onPressed: state.isSaving ? null : _handleSave,
                            type: SmoothButtonType.filled,
                            variant: SmoothButtonVariant.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Форматтер для ввода номера карты
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Выпадающий список типа карты
class _CardTypeDropdown extends StatelessWidget {
  const _CardTypeDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: primaryInputDecoration(context, labelText: 'Тип карты'),
      items: const [
        DropdownMenuItem(value: null, child: Text('Не выбрано')),
        DropdownMenuItem(value: 'debit', child: Text('Дебетовая')),
        DropdownMenuItem(value: 'credit', child: Text('Кредитная')),
        DropdownMenuItem(value: 'prepaid', child: Text('Предоплаченная')),
        DropdownMenuItem(value: 'virtual', child: Text('Виртуальная')),
      ],
      onChanged: onChanged,
    );
  }
}

/// Выпадающий список платежной сети
class _CardNetworkDropdown extends StatelessWidget {
  const _CardNetworkDropdown({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: primaryInputDecoration(context, labelText: 'Платежная сеть'),
      items: const [
        DropdownMenuItem(value: null, child: Text('Не выбрано')),
        DropdownMenuItem(value: 'visa', child: Text('Visa')),
        DropdownMenuItem(value: 'mastercard', child: Text('Mastercard')),
        DropdownMenuItem(value: 'amex', child: Text('American Express')),
        DropdownMenuItem(value: 'discover', child: Text('Discover')),
        DropdownMenuItem(value: 'dinersclub', child: Text('Diners Club')),
        DropdownMenuItem(value: 'jcb', child: Text('JCB')),
        DropdownMenuItem(value: 'unionpay', child: Text('UnionPay')),
        DropdownMenuItem(value: 'other', child: Text('Другое')),
      ],
      onChanged: onChanged,
    );
  }
}
