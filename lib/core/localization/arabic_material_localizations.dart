import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ArabicFullDaysMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const ArabicFullDaysMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final MaterialLocalizations inner = await GlobalMaterialLocalizations
        .delegate
        .load(locale);
    return _ArabicFullDaysMaterialLocalizations(inner);
  }

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => false;
}

class _ArabicFullDaysMaterialLocalizations extends MaterialLocalizations {
  final MaterialLocalizations inner;
  _ArabicFullDaysMaterialLocalizations(this.inner);

  @override
  List<String> get narrowWeekdays => [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  String get alertDialogLabel => inner.alertDialogLabel;
  @override
  String get anteMeridiemAbbreviation => inner.anteMeridiemAbbreviation;
  @override
  String get backButtonTooltip => inner.backButtonTooltip;
  @override
  String get calendarModeButtonLabel => inner.calendarModeButtonLabel;
  @override
  String get cancelButtonLabel => inner.cancelButtonLabel;
  @override
  String get closeButtonLabel => inner.closeButtonLabel;
  @override
  String get closeButtonTooltip => inner.closeButtonTooltip;
  @override
  String get collapsedIconTapHint => inner.collapsedIconTapHint;
  @override
  String get continueButtonLabel => inner.continueButtonLabel;
  @override
  String get copyButtonLabel => inner.copyButtonLabel;
  @override
  String get cutButtonLabel => inner.cutButtonLabel;
  @override
  String get dateHelpText => inner.dateHelpText;
  @override
  String get dateInputLabel => inner.dateInputLabel;
  @override
  String get dateOutOfRangeLabel => inner.dateOutOfRangeLabel;
  @override
  String get datePickerHelpText => inner.datePickerHelpText;
  @override
  String get dateSeparator => inner.dateSeparator;
  @override
  String get deleteButtonTooltip => inner.deleteButtonTooltip;
  @override
  String get dialModeButtonLabel => inner.dialModeButtonLabel;
  @override
  String get dialogLabel => inner.dialogLabel;
  @override
  String get drawerLabel => inner.drawerLabel;
  @override
  String get expandedIconTapHint => inner.expandedIconTapHint;
  @override
  String get firstPageTooltip => inner.firstPageTooltip;
  @override
  String get hideAccountsLabel => inner.hideAccountsLabel;
  @override
  String get lastPageTooltip => inner.lastPageTooltip;
  @override
  String get lookUpButtonLabel => inner.lookUpButtonLabel;
  @override
  String get menuBarMenuLabel => inner.menuBarMenuLabel;
  @override
  String get modalBarrierDismissLabel => inner.modalBarrierDismissLabel;
  @override
  String get moreButtonTooltip => inner.moreButtonTooltip;
  @override
  String get nextMonthTooltip => inner.nextMonthTooltip;
  @override
  String get nextPageTooltip => inner.nextPageTooltip;
  @override
  String get okButtonLabel => inner.okButtonLabel;
  @override
  String get openAppDrawerTooltip => inner.openAppDrawerTooltip;
  @override
  String get pasteButtonLabel => inner.pasteButtonLabel;
  @override
  String get postMeridiemAbbreviation => inner.postMeridiemAbbreviation;
  @override
  String get previousMonthTooltip => inner.previousMonthTooltip;
  @override
  String get previousPageTooltip => inner.previousPageTooltip;
  @override
  String get refreshIndicatorSemanticLabel =>
      inner.refreshIndicatorSemanticLabel;
  @override
  String get reorderItemDown => inner.reorderItemDown;
  @override
  String get reorderItemLeft => inner.reorderItemLeft;
  @override
  String get reorderItemRight => inner.reorderItemRight;
  @override
  String get reorderItemToEnd => inner.reorderItemToEnd;
  @override
  String get reorderItemToStart => inner.reorderItemToStart;
  @override
  String get reorderItemUp => inner.reorderItemUp;
  @override
  String get rowsPerPageTitle => inner.rowsPerPageTitle;
  @override
  String get saveButtonLabel => inner.saveButtonLabel;
  @override
  String get searchFieldLabel => inner.searchFieldLabel;
  @override
  String get searchWebButtonLabel => inner.searchWebButtonLabel;
  @override
  String get selectAllButtonLabel => inner.selectAllButtonLabel;
  @override
  String get selectYearSemanticsLabel => inner.selectYearSemanticsLabel;
  @override
  String get shareButtonLabel => inner.shareButtonLabel;
  @override
  String get showAccountsLabel => inner.showAccountsLabel;
  @override
  String get showMenuTooltip => inner.showMenuTooltip;
  @override
  String get signedInLabel => inner.signedInLabel;
  @override
  String get timePickerDialHelpText => inner.timePickerDialHelpText;
  @override
  String get timePickerHourLabel => inner.timePickerHourLabel;
  @override
  String get timePickerHourModeAnnouncement =>
      inner.timePickerHourModeAnnouncement;
  @override
  String get timePickerInputHelpText => inner.timePickerInputHelpText;
  @override
  String get timePickerMinuteLabel => inner.timePickerMinuteLabel;
  @override
  String get timePickerMinuteModeAnnouncement =>
      inner.timePickerMinuteModeAnnouncement;
  @override
  String get unspecifiedDate => inner.unspecifiedDate;
  @override
  String get unspecifiedDateRange => inner.unspecifiedDateRange;
  @override
  String get viewLicensesButtonLabel => inner.viewLicensesButtonLabel;
  @override
  String get currentDateLabel => inner.currentDateLabel;
  @override
  String get dateRangeEndLabel => inner.dateRangeEndLabel;
  @override
  String get dateRangeStartLabel => inner.dateRangeStartLabel;
  @override
  String get inputDateModeButtonLabel => inner.inputDateModeButtonLabel;
  @override
  String get inputTimeModeButtonLabel => inner.inputTimeModeButtonLabel;
  @override
  String get licensesPageTitle => inner.licensesPageTitle;
  @override
  String get menuDismissLabel => inner.menuDismissLabel;
  @override
  String get invalidDateFormatLabel => inner.invalidDateFormatLabel;
  @override
  String get invalidDateRangeLabel => inner.invalidDateRangeLabel;
  @override
  String get invalidTimeLabel => inner.invalidTimeLabel;
  @override
  String get keyboardKeyShift => inner.keyboardKeyShift;
  @override
  String get popupMenuLabel => inner.popupMenuLabel;
  @override
  String get scrimLabel => inner.scrimLabel;
  @override
  String get selectedDateLabel => inner.selectedDateLabel;

  @override
  String formatCompactDate(DateTime date) => inner.formatCompactDate(date);

  @override
  String formatDecimal(int number) => inner.formatDecimal(number);
  @override
  String formatFullDate(DateTime date) => inner.formatFullDate(date);
  @override
  String formatHour(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) =>
      inner.formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat);
  @override
  String formatMediumDate(DateTime date) => inner.formatMediumDate(date);
  @override
  String formatMinute(TimeOfDay timeOfDay) => inner.formatMinute(timeOfDay);
  @override
  String formatMonthYear(DateTime date) => inner.formatMonthYear(date);
  @override
  String formatShortDate(DateTime date) => inner.formatShortDate(date);
  @override
  String formatShortMonthDay(DateTime date) => inner.formatShortMonthDay(date);
  @override
  String formatTimeOfDay(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) => inner.formatTimeOfDay(
    timeOfDay,
    alwaysUse24HourFormat: alwaysUse24HourFormat,
  );
  @override
  String formatYear(DateTime date) => inner.formatYear(date);
  @override
  int get firstDayOfWeekIndex => inner.firstDayOfWeekIndex;

  @override
  String get keyboardKeyAlt => inner.keyboardKeyAlt;
  @override
  String get keyboardKeyAltGraph => inner.keyboardKeyAltGraph;
  @override
  String get keyboardKeyBackspace => inner.keyboardKeyBackspace;
  @override
  String get keyboardKeyCapsLock => inner.keyboardKeyCapsLock;
  @override
  String get keyboardKeyChannelDown => inner.keyboardKeyChannelDown;
  @override
  String get keyboardKeyChannelUp => inner.keyboardKeyChannelUp;
  @override
  String get keyboardKeyControl => inner.keyboardKeyControl;
  @override
  String get keyboardKeyDelete => inner.keyboardKeyDelete;
  @override
  String get keyboardKeyEject => inner.keyboardKeyEject;
  @override
  String get keyboardKeyEnd => inner.keyboardKeyEnd;
  @override
  String get keyboardKeyEscape => inner.keyboardKeyEscape;
  @override
  String get keyboardKeyFn => inner.keyboardKeyFn;
  @override
  String get keyboardKeyHome => inner.keyboardKeyHome;
  @override
  String get keyboardKeyInsert => inner.keyboardKeyInsert;
  @override
  String get keyboardKeyMeta => inner.keyboardKeyMeta;
  @override
  String get keyboardKeyMetaMacOs => inner.keyboardKeyMetaMacOs;
  @override
  String get keyboardKeyMetaWindows => inner.keyboardKeyMetaWindows;
  @override
  String get keyboardKeyNumLock => inner.keyboardKeyNumLock;
  @override
  String get keyboardKeyNumpad0 => inner.keyboardKeyNumpad0;
  @override
  String get keyboardKeyNumpad1 => inner.keyboardKeyNumpad1;
  @override
  String get keyboardKeyNumpad2 => inner.keyboardKeyNumpad2;
  @override
  String get keyboardKeyNumpad3 => inner.keyboardKeyNumpad3;
  @override
  String get keyboardKeyNumpad4 => inner.keyboardKeyNumpad4;
  @override
  String get keyboardKeyNumpad5 => inner.keyboardKeyNumpad5;
  @override
  String get keyboardKeyNumpad6 => inner.keyboardKeyNumpad6;
  @override
  String get keyboardKeyNumpad7 => inner.keyboardKeyNumpad7;
  @override
  String get keyboardKeyNumpad8 => inner.keyboardKeyNumpad8;
  @override
  String get keyboardKeyNumpad9 => inner.keyboardKeyNumpad9;
  @override
  String get keyboardKeyNumpadAdd => inner.keyboardKeyNumpadAdd;
  @override
  String get keyboardKeyNumpadComma => inner.keyboardKeyNumpadComma;
  @override
  String get keyboardKeyNumpadDecimal => inner.keyboardKeyNumpadDecimal;
  @override
  String get keyboardKeyNumpadDivide => inner.keyboardKeyNumpadDivide;
  @override
  String get keyboardKeyNumpadEnter => inner.keyboardKeyNumpadEnter;
  @override
  String get keyboardKeyNumpadEqual => inner.keyboardKeyNumpadEqual;
  @override
  String get keyboardKeyNumpadMultiply => inner.keyboardKeyNumpadMultiply;
  @override
  String get keyboardKeyNumpadParenLeft => inner.keyboardKeyNumpadParenLeft;
  @override
  String get keyboardKeyNumpadParenRight => inner.keyboardKeyNumpadParenRight;
  @override
  String get keyboardKeyNumpadSubtract => inner.keyboardKeyNumpadSubtract;
  @override
  String get keyboardKeyPageDown => inner.keyboardKeyPageDown;
  @override
  String get keyboardKeyPageUp => inner.keyboardKeyPageUp;
  @override
  String get keyboardKeyPower => inner.keyboardKeyPower;
  @override
  String get keyboardKeyPowerOff => inner.keyboardKeyPowerOff;
  @override
  String get keyboardKeyPrintScreen => inner.keyboardKeyPrintScreen;
  @override
  String get keyboardKeyScrollLock => inner.keyboardKeyScrollLock;
  @override
  String get keyboardKeySelect => inner.keyboardKeySelect;
  @override
  String get keyboardKeySpace => inner.keyboardKeySpace;

  @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) =>
      inner.timeOfDayFormat(alwaysUse24HourFormat: alwaysUse24HourFormat);

  @override
  ScriptCategory get scriptCategory => inner.scriptCategory;

  @override
  String get scanTextButtonLabel => inner.scanTextButtonLabel;

  @override
  String get bottomSheetLabel => inner.bottomSheetLabel;
  @override
  String get clearButtonTooltip => inner.clearButtonTooltip;

  @override
  DateTime? parseCompactDate(String? inputString) =>
      inner.parseCompactDate(inputString);

  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      inner.tabLabel(tabIndex: tabIndex, tabCount: tabCount);
  @override
  String selectedRowCountTitle(int selectedRowCount) =>
      inner.selectedRowCountTitle(selectedRowCount);
  @override
  String remainingTextFieldCharacterCount(int remainingCount) =>
      inner.remainingTextFieldCharacterCount(remainingCount);
  @override
  String licensesPackageDetailText(int licenseCount) =>
      inner.licensesPackageDetailText(licenseCount);
  @override
  String pageRowsInfoTitle(
    int firstRow,
    int lastRow,
    int rowCount,
    bool rowCountIsApproximate,
  ) => inner.pageRowsInfoTitle(
    firstRow,
    lastRow,
    rowCount,
    rowCountIsApproximate,
  );

  @override
  String aboutListTileTitle(String applicationName) =>
      inner.aboutListTileTitle(applicationName);
  @override
  String dateRangeEndDateSemanticLabel(String formattedDate) =>
      inner.dateRangeEndDateSemanticLabel(formattedDate);
  @override
  String dateRangeStartDateSemanticLabel(String formattedDate) =>
      inner.dateRangeStartDateSemanticLabel(formattedDate);
  @override
  String scrimOnTapHint(String modalBarrierDismissLabel) =>
      inner.scrimOnTapHint(modalBarrierDismissLabel);

  @override
  String get dateRangePickerHelpText => inner.dateRangePickerHelpText;
}
