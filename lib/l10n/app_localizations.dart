import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NH Fitness'**
  String get appName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NH Fitness — Gym membership'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Train hard. Stay focused. Be strong.'**
  String get tagline;

  /// No description provided for @motto.
  ///
  /// In en, this message translates to:
  /// **'BE FIT. BE STRONG. BE YOU.'**
  String get motto;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get actionSaveChanges;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get actionBackToHome;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get actionLogOut;

  /// No description provided for @actionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get actionViewAll;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get actionPrevious;

  /// No description provided for @stateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get stateLoading;

  /// No description provided for @stateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get stateSaved;

  /// No description provided for @stateCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get stateCopiedToClipboard;

  /// No description provided for @stateComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get stateComingSoon;

  /// No description provided for @stateFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get stateFree;

  /// No description provided for @stateOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Some things may not be up to date.'**
  String get stateOffline;

  /// No description provided for @stateGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get stateGenericError;

  /// No description provided for @stateNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get stateNoInternet;

  /// No description provided for @stateNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateNothingHere;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get navPlans;

  /// No description provided for @navOnlineClasses.
  ///
  /// In en, this message translates to:
  /// **'Online classes'**
  String get navOnlineClasses;

  /// No description provided for @navSupplements.
  ///
  /// In en, this message translates to:
  /// **'Supplements'**
  String get navSupplements;

  /// No description provided for @navClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get navClothes;

  /// No description provided for @navSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get navSoon;

  /// No description provided for @navLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get navLogin;

  /// No description provided for @navRegisterNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get navRegisterNow;

  /// No description provided for @navMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get navMyAccount;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get navClasses;

  /// No description provided for @navMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @navBackToSite.
  ///
  /// In en, this message translates to:
  /// **'Back to site'**
  String get navBackToSite;

  /// No description provided for @homeHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'GYM MEMBERSHIP'**
  String get homeHeroLabel;

  /// No description provided for @homeHeroLine1.
  ///
  /// In en, this message translates to:
  /// **'STRONGER THAN'**
  String get homeHeroLine1;

  /// No description provided for @homeHeroLine2.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get homeHeroLine2;

  /// No description provided for @homeCtaStart.
  ///
  /// In en, this message translates to:
  /// **'Start your fitness journey'**
  String get homeCtaStart;

  /// No description provided for @homeOfferBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'7 days personal training FREE'**
  String get homeOfferBadgeTitle;

  /// No description provided for @homeOfferBadgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'With every new membership'**
  String get homeOfferBadgeSubtitle;

  /// No description provided for @homeTicker.
  ///
  /// In en, this message translates to:
  /// **'TRAIN HARD ✦ STAY FOCUSED ✦ BE STRONG ✦ BE FIT ✦ BE YOU'**
  String get homeTicker;

  /// No description provided for @homeWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'WHY NH FITNESS'**
  String get homeWhyTitle;

  /// No description provided for @homeWhyEquipment.
  ///
  /// In en, this message translates to:
  /// **'Modern equipment'**
  String get homeWhyEquipment;

  /// No description provided for @homeWhyEquipmentBody.
  ///
  /// In en, this message translates to:
  /// **'Machines and free weights kept in top condition.'**
  String get homeWhyEquipmentBody;

  /// No description provided for @homeWhyTrainers.
  ///
  /// In en, this message translates to:
  /// **'Expert trainers'**
  String get homeWhyTrainers;

  /// No description provided for @homeWhyTrainersBody.
  ///
  /// In en, this message translates to:
  /// **'Certified trainers who correct your form.'**
  String get homeWhyTrainersBody;

  /// No description provided for @homeWhyDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet consultation'**
  String get homeWhyDiet;

  /// No description provided for @homeWhyDietBody.
  ///
  /// In en, this message translates to:
  /// **'A simple eating plan that fits your day.'**
  String get homeWhyDietBody;

  /// No description provided for @homeWhyHygiene.
  ///
  /// In en, this message translates to:
  /// **'Clean and hygienic'**
  String get homeWhyHygiene;

  /// No description provided for @homeWhyHygieneBody.
  ///
  /// In en, this message translates to:
  /// **'Cleaned through the day, every day.'**
  String get homeWhyHygieneBody;

  /// No description provided for @homeMembershipTitle.
  ///
  /// In en, this message translates to:
  /// **'GYM MEMBERSHIP'**
  String get homeMembershipTitle;

  /// No description provided for @homePathTitle.
  ///
  /// In en, this message translates to:
  /// **'PICK YOUR PATH'**
  String get homePathTitle;

  /// No description provided for @homeOfferBandTitle.
  ///
  /// In en, this message translates to:
  /// **'7 DAYS PERSONAL TRAINING FREE!'**
  String get homeOfferBandTitle;

  /// No description provided for @homePricesError.
  ///
  /// In en, this message translates to:
  /// **'Prices could not load. Try again.'**
  String get homePricesError;

  /// No description provided for @homeNoPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans are available right now. Please call the gym.'**
  String get homeNoPlans;

  /// No description provided for @footerThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get footerThanks;

  /// No description provided for @footerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get footerAddress;

  /// No description provided for @footerTimings.
  ///
  /// In en, this message translates to:
  /// **'Timings'**
  String get footerTimings;

  /// No description provided for @footerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get footerPhone;

  /// No description provided for @footerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get footerEmail;

  /// No description provided for @footerInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get footerInstagram;

  /// No description provided for @footerLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get footerLinks;

  /// No description provided for @footerRights.
  ///
  /// In en, this message translates to:
  /// **'© {year} NH Fitness'**
  String footerRights(String year);

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'PICK YOUR PATH'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where you want to start.'**
  String get exploreSubtitle;

  /// No description provided for @exploreMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership plans'**
  String get exploreMembership;

  /// No description provided for @exploreMembershipFrom.
  ///
  /// In en, this message translates to:
  /// **'From {amount} a month'**
  String exploreMembershipFrom(String amount);

  /// No description provided for @explorePtFreeTag.
  ///
  /// In en, this message translates to:
  /// **'7 days PT free'**
  String get explorePtFreeTag;

  /// No description provided for @exploreClasses.
  ///
  /// In en, this message translates to:
  /// **'Online classes'**
  String get exploreClasses;

  /// No description provided for @exploreClassesBody.
  ///
  /// In en, this message translates to:
  /// **'Train with our trainers from home.'**
  String get exploreClassesBody;

  /// No description provided for @exploreSupplementsBody.
  ///
  /// In en, this message translates to:
  /// **'Protein, creatine and more at the gym counter.'**
  String get exploreSupplementsBody;

  /// No description provided for @exploreClothesBody.
  ///
  /// In en, this message translates to:
  /// **'NH Fitness tees, shorts and bags.'**
  String get exploreClothesBody;

  /// No description provided for @plansTitle.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE YOUR PLAN'**
  String get plansTitle;

  /// No description provided for @plansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. No hidden charges.'**
  String get plansSubtitle;

  /// No description provided for @plansBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get plansBestValue;

  /// No description provided for @plansChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose plan'**
  String get plansChoosePlan;

  /// No description provided for @plansPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String plansPerMonth(String amount);

  /// No description provided for @plansPayAsYouGo.
  ///
  /// In en, this message translates to:
  /// **'Pay as you go'**
  String get plansPayAsYouGo;

  /// No description provided for @plansMonthsOne.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get plansMonthsOne;

  /// No description provided for @plansMonthsOther.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String plansMonthsOther(String months);

  /// No description provided for @plansAddPtTitle.
  ///
  /// In en, this message translates to:
  /// **'Add personal training'**
  String get plansAddPtTitle;

  /// No description provided for @plansAddPtFreeDays.
  ///
  /// In en, this message translates to:
  /// **'First {days} days free'**
  String plansAddPtFreeDays(String days);

  /// No description provided for @plansOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get plansOrderSummary;

  /// No description provided for @plansSummaryPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plansSummaryPlan;

  /// No description provided for @plansSummaryRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration charge'**
  String get plansSummaryRegistration;

  /// No description provided for @plansSummaryPt.
  ///
  /// In en, this message translates to:
  /// **'Personal training'**
  String get plansSummaryPt;

  /// No description provided for @plansSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get plansSummaryTotal;

  /// No description provided for @plansRegistrationNote.
  ///
  /// In en, this message translates to:
  /// **'One-time, for new members'**
  String get plansRegistrationNote;

  /// No description provided for @plansPtFreeNote.
  ///
  /// In en, this message translates to:
  /// **'7 days personal training free'**
  String get plansPtFreeNote;

  /// No description provided for @plansPtFreeDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days personal training'**
  String plansPtFreeDaysLabel(String days);

  /// No description provided for @plansPtCharge.
  ///
  /// In en, this message translates to:
  /// **'Personal training charge'**
  String get plansPtCharge;

  /// No description provided for @plansContinueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get plansContinueToPayment;

  /// No description provided for @plansSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get plansSelected;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT'**
  String get checkoutTitle;

  /// No description provided for @checkoutPayingFor.
  ///
  /// In en, this message translates to:
  /// **'{planName} membership'**
  String checkoutPayingFor(String planName);

  /// No description provided for @checkoutMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to pay?'**
  String get checkoutMethodTitle;

  /// No description provided for @checkoutMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get checkoutMethodUpi;

  /// No description provided for @checkoutMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Pay at gym (cash)'**
  String get checkoutMethodCash;

  /// No description provided for @checkoutMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get checkoutMethodCard;

  /// No description provided for @checkoutMethodNetBanking.
  ///
  /// In en, this message translates to:
  /// **'Net banking'**
  String get checkoutMethodNetBanking;

  /// No description provided for @checkoutUpiScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code in any UPI app and pay {amount}.'**
  String checkoutUpiScanHint(String amount);

  /// No description provided for @checkoutUpiIdLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get checkoutUpiIdLabel;

  /// No description provided for @checkoutUpiIdCopied.
  ///
  /// In en, this message translates to:
  /// **'UPI ID copied'**
  String get checkoutUpiIdCopied;

  /// No description provided for @checkoutPayWithUpiApp.
  ///
  /// In en, this message translates to:
  /// **'Pay with UPI app'**
  String get checkoutPayWithUpiApp;

  /// No description provided for @checkoutUpiAppFailed.
  ///
  /// In en, this message translates to:
  /// **'No UPI app could be opened. Scan the QR code instead.'**
  String get checkoutUpiAppFailed;

  /// No description provided for @checkoutUtrLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI reference number (UTR)'**
  String get checkoutUtrLabel;

  /// No description provided for @checkoutUtrHelp.
  ///
  /// In en, this message translates to:
  /// **'12 digits. You will find it in your payment app next to the payment.'**
  String get checkoutUtrHelp;

  /// No description provided for @checkoutUtrError.
  ///
  /// In en, this message translates to:
  /// **'Enter the 12-digit UPI reference number from your payment app'**
  String get checkoutUtrError;

  /// No description provided for @checkoutIHavePaid.
  ///
  /// In en, this message translates to:
  /// **'I have paid {amount}'**
  String checkoutIHavePaid(String amount);

  /// No description provided for @checkoutCashText.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} at the gym reception. Your plan starts when the gym confirms payment.'**
  String checkoutCashText(String amount);

  /// No description provided for @checkoutSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get checkoutSubmitRequest;

  /// No description provided for @checkoutNoPinNote.
  ///
  /// In en, this message translates to:
  /// **'Sample payment flow: we never ask for your UPI PIN'**
  String get checkoutNoPinNote;

  /// No description provided for @checkoutUpiNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'The gym has not added its UPI ID yet. Please choose “Pay at gym” or call the gym.'**
  String get checkoutUpiNotSetUp;

  /// No description provided for @checkoutSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Your request could not be sent. Check your connection and try again.'**
  String get checkoutSubmitFailed;

  /// No description provided for @checkoutPendingExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a request waiting for approval'**
  String get checkoutPendingExists;

  /// No description provided for @checkoutPendingExistsBody.
  ///
  /// In en, this message translates to:
  /// **'The gym is checking your last payment. You can see it in your account.'**
  String get checkoutPendingExistsBody;

  /// No description provided for @submittedTitle.
  ///
  /// In en, this message translates to:
  /// **'REQUEST SENT'**
  String get submittedTitle;

  /// No description provided for @submittedBody.
  ///
  /// In en, this message translates to:
  /// **'The gym will check your payment and activate your plan. This usually takes {time}.'**
  String submittedBody(String time);

  /// No description provided for @submittedGoToAccount.
  ///
  /// In en, this message translates to:
  /// **'Go to my account'**
  String get submittedGoToAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account for the gym and the online classes.'**
  String get authRegisterSubtitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your membership.'**
  String get authLoginSubtitle;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'RESET PASSWORD'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will email you a link to set a new password.'**
  String get authForgotSubtitle;

  /// No description provided for @authFieldName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFieldName;

  /// No description provided for @authFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// No description provided for @authFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authFieldPhone;

  /// No description provided for @authFieldPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'10 digits. The gym uses it to reach you about your membership.'**
  String get authFieldPhoneHelp;

  /// No description provided for @authFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFieldPassword;

  /// No description provided for @authFieldPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authFieldPasswordHelp;

  /// No description provided for @authFieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authFieldConfirmPassword;

  /// No description provided for @authFieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get authFieldCurrentPassword;

  /// No description provided for @authFieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authFieldNewPassword;

  /// No description provided for @authAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms and Privacy Policy'**
  String get authAgreeTerms;

  /// No description provided for @authAgreeTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms and Privacy Policy to continue'**
  String get authAgreeTermsError;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogIn;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordLink;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// No description provided for @authResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset link to {email}. Check your inbox and spam folder.'**
  String authResetLinkSent(String email);

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to NH Fitness?'**
  String get authNoAccount;

  /// No description provided for @authOtpSoon.
  ///
  /// In en, this message translates to:
  /// **'Phone OTP login coming soon'**
  String get authOtpSoon;

  /// No description provided for @authChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get authChangePassword;

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed.'**
  String get authPasswordChanged;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Verifying keeps your account safe.'**
  String authVerifyEmailBody(String email);

  /// No description provided for @authVerifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get authVerifyEmailResend;

  /// No description provided for @authVerifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get authVerifyEmailSent;

  /// No description provided for @authErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authErrorNameRequired;

  /// No description provided for @authErrorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authErrorEmailRequired;

  /// No description provided for @authErrorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email like name@example.com'**
  String get authErrorEmailInvalid;

  /// No description provided for @authErrorPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get authErrorPasswordShort;

  /// No description provided for @authErrorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match'**
  String get authErrorPasswordMismatch;

  /// No description provided for @authErrorPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit phone number'**
  String get authErrorPhoneInvalid;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'That password is not right. Try again or reset it.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account uses this email. Create one instead.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Log in instead.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Pick a stronger password of at least 8 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a minute and try again.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get authErrorGoogleCancelled;

  /// No description provided for @authErrorSignInNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not switched on yet. Ask the gym to enable it in Firebase (Authentication → Sign-in method).'**
  String get authErrorSignInNotEnabled;

  /// No description provided for @authErrorDomainNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is blocked from this web address. Add it in Firebase under Authentication → Settings → Authorized domains.'**
  String get authErrorDomainNotAuthorized;

  /// No description provided for @authErrorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For safety, log in again before changing your password.'**
  String get authErrorRecentLogin;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'MY MEMBERSHIP'**
  String get accountTitle;

  /// No description provided for @accountGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {firstName}'**
  String accountGreeting(String firstName);

  /// No description provided for @accountMembershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get accountMembershipTitle;

  /// No description provided for @accountStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountStatusActive;

  /// No description provided for @accountStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get accountStatusPending;

  /// No description provided for @accountStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get accountStatusRejected;

  /// No description provided for @accountStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get accountStatusExpired;

  /// No description provided for @accountStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Starts soon'**
  String get accountStatusUpcoming;

  /// No description provided for @accountStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get accountStatusApproved;

  /// No description provided for @accountStartDate.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get accountStartDate;

  /// No description provided for @accountValidTill.
  ///
  /// In en, this message translates to:
  /// **'Valid till'**
  String get accountValidTill;

  /// No description provided for @accountDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String accountDaysLeft(String days);

  /// No description provided for @accountDaysLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get accountDaysLeftLabel;

  /// No description provided for @accountOneDayLeft.
  ///
  /// In en, this message translates to:
  /// **'Last day today'**
  String get accountOneDayLeft;

  /// No description provided for @accountRenewPlan.
  ///
  /// In en, this message translates to:
  /// **'Renew plan'**
  String get accountRenewPlan;

  /// No description provided for @accountNoPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'You don’t have a plan yet'**
  String get accountNoPlanTitle;

  /// No description provided for @accountNoPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a plan to start training and unlock the online classes.'**
  String get accountNoPlanBody;

  /// No description provided for @accountChoosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get accountChoosePlan;

  /// No description provided for @accountWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get accountWaitingTitle;

  /// No description provided for @accountWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The gym is checking your payment. This usually takes {time}.'**
  String accountWaitingBody(String time);

  /// No description provided for @accountRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not approved'**
  String get accountRejectedTitle;

  /// No description provided for @accountRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String accountRejectedReason(String reason);

  /// No description provided for @accountExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan ended on {date}'**
  String accountExpiredTitle(String date);

  /// No description provided for @accountExpiryBanner.
  ///
  /// In en, this message translates to:
  /// **'Your plan ends in {days} days. Renew now.'**
  String accountExpiryBanner(String days);

  /// No description provided for @accountExpiryBannerToday.
  ///
  /// In en, this message translates to:
  /// **'Your plan ends today. Renew now.'**
  String get accountExpiryBannerToday;

  /// No description provided for @accountUpcomingStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts on {date}'**
  String accountUpcomingStarts(String date);

  /// No description provided for @accountFreePtTitle.
  ///
  /// In en, this message translates to:
  /// **'Free personal training'**
  String get accountFreePtTitle;

  /// No description provided for @accountFreePtDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} of {total} free days left'**
  String accountFreePtDaysLeft(String left, String total);

  /// No description provided for @accountFreePtUsedUp.
  ///
  /// In en, this message translates to:
  /// **'You have used all {total} free days.'**
  String accountFreePtUsedUp(String total);

  /// No description provided for @accountClassesPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Online classes'**
  String get accountClassesPreviewTitle;

  /// No description provided for @accountPaymentsPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent payments'**
  String get accountPaymentsPreviewTitle;

  /// No description provided for @accountSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Sent on {date}'**
  String accountSubmittedOn(String date);

  /// No description provided for @accountSubmittedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent on'**
  String get accountSubmittedOnLabel;

  /// No description provided for @accountProgressUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} days used'**
  String accountProgressUsed(String used, String total);

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT HISTORY'**
  String get paymentsTitle;

  /// No description provided for @paymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not made any payments yet.'**
  String get paymentsEmpty;

  /// No description provided for @paymentsMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get paymentsMethodLabel;

  /// No description provided for @paymentsMethodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get paymentsMethodUpi;

  /// No description provided for @paymentsMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentsMethodCash;

  /// No description provided for @paymentsUtr.
  ///
  /// In en, this message translates to:
  /// **'UTR {ref}'**
  String paymentsUtr(String ref);

  /// No description provided for @paymentsPlanLine.
  ///
  /// In en, this message translates to:
  /// **'{planName} · {months}'**
  String paymentsPlanLine(String planName, String months);

  /// No description provided for @paymentsWithPt.
  ///
  /// In en, this message translates to:
  /// **'With personal training'**
  String get paymentsWithPt;

  /// No description provided for @paymentsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get paymentsLoadMore;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileTitle;

  /// No description provided for @profileEmailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed.'**
  String get profileEmailReadOnly;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been updated.'**
  String get profileSaved;

  /// No description provided for @profileGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'You log in with Google, so there is no password to change.'**
  String get profileGoogleAccount;

  /// No description provided for @profileDeleteDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Want your data deleted?'**
  String get profileDeleteDataTitle;

  /// No description provided for @profileDeleteDataBody.
  ///
  /// In en, this message translates to:
  /// **'Email {email} and the gym will remove your account.'**
  String profileDeleteDataBody(String email);

  /// No description provided for @classesTitle.
  ///
  /// In en, this message translates to:
  /// **'ONLINE CLASSES'**
  String get classesTitle;

  /// No description provided for @classesLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Online classes are for active members'**
  String get classesLockedTitle;

  /// No description provided for @classesLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a plan to unlock every class.'**
  String get classesLockedBody;

  /// No description provided for @classesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No classes have been added yet. Check back soon.'**
  String get classesEmpty;

  /// No description provided for @classesAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get classesAll;

  /// No description provided for @classesDuration.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String classesDuration(String minutes);

  /// No description provided for @classesLive.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get classesLive;

  /// No description provided for @classesNotFound.
  ///
  /// In en, this message translates to:
  /// **'This class is no longer available.'**
  String get classesNotFound;

  /// No description provided for @classesAbout.
  ///
  /// In en, this message translates to:
  /// **'About this class'**
  String get classesAbout;

  /// No description provided for @announcementDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss announcement'**
  String get announcementDismiss;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get adminTitle;

  /// No description provided for @adminNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminNavDashboard;

  /// No description provided for @adminNavPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending payments'**
  String get adminNavPayments;

  /// No description provided for @adminNavMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get adminNavMembers;

  /// No description provided for @adminNavPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans and prices'**
  String get adminNavPlans;

  /// No description provided for @adminNavClasses.
  ///
  /// In en, this message translates to:
  /// **'Online classes'**
  String get adminNavClasses;

  /// No description provided for @adminNavAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get adminNavAnnouncements;

  /// No description provided for @adminNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminNavSettings;

  /// No description provided for @adminNavStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff access'**
  String get adminNavStaff;

  /// No description provided for @adminStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'STAFF ACCESS'**
  String get adminStaffTitle;

  /// No description provided for @adminStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who can use the admin panel.'**
  String get adminStaffSubtitle;

  /// No description provided for @adminStaffOwnerOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Only an owner can change this'**
  String get adminStaffOwnerOnlyTitle;

  /// No description provided for @adminStaffOwnerOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the gym owner to add or remove staff.'**
  String get adminStaffOwnerOnlyBody;

  /// No description provided for @adminStaffOwnersSection.
  ///
  /// In en, this message translates to:
  /// **'Owners'**
  String get adminStaffOwnersSection;

  /// No description provided for @adminStaffStaffSection.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get adminStaffStaffSection;

  /// No description provided for @adminStaffOwnerNote.
  ///
  /// In en, this message translates to:
  /// **'Owners are set in the Firebase Console and cannot be changed here. An owner always keeps access, so staff can never lock you out.'**
  String get adminStaffOwnerNote;

  /// No description provided for @adminStaffOwnerBadge.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get adminStaffOwnerBadge;

  /// No description provided for @adminStaffNone.
  ///
  /// In en, this message translates to:
  /// **'No staff have been given access yet.'**
  String get adminStaffNone;

  /// No description provided for @adminStaffAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Give someone admin access'**
  String get adminStaffAddTitle;

  /// No description provided for @adminStaffAddHelp.
  ///
  /// In en, this message translates to:
  /// **'They must sign in to the app once before they appear here.'**
  String get adminStaffAddHelp;

  /// No description provided for @adminStaffSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get adminStaffSearchHint;

  /// No description provided for @adminStaffNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Nobody matches that. Check the spelling, or ask them to sign in to the app once.'**
  String get adminStaffNoMatches;

  /// No description provided for @adminStaffAdd.
  ///
  /// In en, this message translates to:
  /// **'Give access'**
  String get adminStaffAdd;

  /// No description provided for @adminStaffAlreadyHasAccess.
  ///
  /// In en, this message translates to:
  /// **'Already has access'**
  String get adminStaffAlreadyHasAccess;

  /// No description provided for @adminStaffAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} can now use the admin panel.'**
  String adminStaffAdded(String name);

  /// No description provided for @adminStaffRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminStaffRemove;

  /// No description provided for @adminStaffRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove admin access?'**
  String get adminStaffRemoveTitle;

  /// No description provided for @adminStaffRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will lose the admin panel. Their membership and payments are not affected.'**
  String adminStaffRemoveBody(String name);

  /// No description provided for @adminStaffRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} no longer has admin access.'**
  String adminStaffRemoved(String name);

  /// No description provided for @adminStaffAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String adminStaffAddedOn(String date);

  /// No description provided for @adminTileActiveMembers.
  ///
  /// In en, this message translates to:
  /// **'Active members'**
  String get adminTileActiveMembers;

  /// No description provided for @adminTileExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring in next 7 days'**
  String get adminTileExpiring;

  /// No description provided for @adminTilePending.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get adminTilePending;

  /// No description provided for @adminTileIncome.
  ///
  /// In en, this message translates to:
  /// **'Income this month'**
  String get adminTileIncome;

  /// No description provided for @adminPendingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending payments'**
  String get adminPendingListTitle;

  /// No description provided for @adminExpiringListTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiring in the next 7 days'**
  String get adminExpiringListTitle;

  /// No description provided for @adminNoPending.
  ///
  /// In en, this message translates to:
  /// **'No payments are waiting for approval.'**
  String get adminNoPending;

  /// No description provided for @adminNoExpiring.
  ///
  /// In en, this message translates to:
  /// **'No memberships end in the next 7 days.'**
  String get adminNoExpiring;

  /// No description provided for @adminPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'PAYMENTS'**
  String get adminPaymentsTitle;

  /// No description provided for @adminTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminTabPending;

  /// No description provided for @adminTabApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminTabApproved;

  /// No description provided for @adminTabRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminTabRejected;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminDuplicateUtr.
  ///
  /// In en, this message translates to:
  /// **'UTR already used'**
  String get adminDuplicateUtr;

  /// No description provided for @adminApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve payment'**
  String get adminApproveTitle;

  /// No description provided for @adminApproveBody.
  ///
  /// In en, this message translates to:
  /// **'{memberName} · {planName} · {amount}'**
  String adminApproveBody(String memberName, String planName, String amount);

  /// No description provided for @adminApproveStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get adminApproveStartDate;

  /// No description provided for @adminApproveEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get adminApproveEndDate;

  /// No description provided for @adminApproveRenewalNote.
  ///
  /// In en, this message translates to:
  /// **'This is a renewal, so it starts the day after the current plan ends.'**
  String get adminApproveRenewalNote;

  /// No description provided for @adminApproveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve and activate'**
  String get adminApproveConfirm;

  /// No description provided for @adminApproved.
  ///
  /// In en, this message translates to:
  /// **'Payment approved. The membership is active.'**
  String get adminApproved;

  /// No description provided for @adminRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject payment'**
  String get adminRejectTitle;

  /// No description provided for @adminRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (the member will see this)'**
  String get adminRejectReasonLabel;

  /// No description provided for @adminRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Payment not received'**
  String get adminRejectReasonHint;

  /// No description provided for @adminRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Write a short reason so the member knows what to do.'**
  String get adminRejectReasonRequired;

  /// No description provided for @adminRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject payment'**
  String get adminRejectConfirm;

  /// No description provided for @adminRejected.
  ///
  /// In en, this message translates to:
  /// **'Payment rejected.'**
  String get adminRejected;

  /// No description provided for @adminAlreadyReviewed.
  ///
  /// In en, this message translates to:
  /// **'This request has already been reviewed.'**
  String get adminAlreadyReviewed;

  /// No description provided for @adminMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get adminMembersTitle;

  /// No description provided for @adminMembersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or phone'**
  String get adminMembersSearchHint;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminFilterActive;

  /// No description provided for @adminFilterExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get adminFilterExpiring;

  /// No description provided for @adminFilterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get adminFilterExpired;

  /// No description provided for @adminFilterNeverJoined.
  ///
  /// In en, this message translates to:
  /// **'Never joined'**
  String get adminFilterNeverJoined;

  /// No description provided for @adminRecordCash.
  ///
  /// In en, this message translates to:
  /// **'Record cash payment'**
  String get adminRecordCash;

  /// No description provided for @adminRecordCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Record a cash payment'**
  String get adminRecordCashTitle;

  /// No description provided for @adminRecordCashMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get adminRecordCashMember;

  /// No description provided for @adminRecordCashDone.
  ///
  /// In en, this message translates to:
  /// **'Cash payment recorded. The membership is active.'**
  String get adminRecordCashDone;

  /// No description provided for @adminMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members match this filter.'**
  String get adminMembersEmpty;

  /// No description provided for @adminNoMembership.
  ///
  /// In en, this message translates to:
  /// **'No membership'**
  String get adminNoMembership;

  /// No description provided for @adminMemberDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get adminMemberDetailTitle;

  /// No description provided for @adminMemberProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get adminMemberProfile;

  /// No description provided for @adminMemberMemberships.
  ///
  /// In en, this message translates to:
  /// **'Memberships'**
  String get adminMemberMemberships;

  /// No description provided for @adminMemberRequests.
  ///
  /// In en, this message translates to:
  /// **'Payment requests'**
  String get adminMemberRequests;

  /// No description provided for @adminFreePtTitle.
  ///
  /// In en, this message translates to:
  /// **'Free personal training days'**
  String get adminFreePtTitle;

  /// No description provided for @adminFreePtUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used'**
  String adminFreePtUsed(String used, String total);

  /// No description provided for @adminFreePtAdd.
  ///
  /// In en, this message translates to:
  /// **'+1 day used'**
  String get adminFreePtAdd;

  /// No description provided for @adminFreePtRemove.
  ///
  /// In en, this message translates to:
  /// **'−1'**
  String get adminFreePtRemove;

  /// No description provided for @adminEditEndDate.
  ///
  /// In en, this message translates to:
  /// **'Edit end date'**
  String get adminEditEndDate;

  /// No description provided for @adminEditEndDateBody.
  ///
  /// In en, this message translates to:
  /// **'Only change this to correct a mistake. The member will see the new date straight away.'**
  String get adminEditEndDateBody;

  /// No description provided for @adminEndDateUpdated.
  ///
  /// In en, this message translates to:
  /// **'End date updated.'**
  String get adminEndDateUpdated;

  /// No description provided for @adminPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'PLANS AND PRICES'**
  String get adminPlansTitle;

  /// No description provided for @adminPlanName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get adminPlanName;

  /// No description provided for @adminPlanMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get adminPlanMonths;

  /// No description provided for @adminPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (₹)'**
  String get adminPlanPrice;

  /// No description provided for @adminPlanSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get adminPlanSortOrder;

  /// No description provided for @adminPlanBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get adminPlanBestValue;

  /// No description provided for @adminPlanActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminPlanActive;

  /// No description provided for @adminPlanAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a plan'**
  String get adminPlanAdd;

  /// No description provided for @adminPlanNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get adminPlanNewTitle;

  /// No description provided for @adminPlanEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get adminPlanEditTitle;

  /// No description provided for @adminPlanIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan ID'**
  String get adminPlanIdLabel;

  /// No description provided for @adminPlanIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, numbers and underscores. It cannot be changed later.'**
  String get adminPlanIdHelp;

  /// No description provided for @adminPlanIdTaken.
  ///
  /// In en, this message translates to:
  /// **'A plan with this ID already exists.'**
  String get adminPlanIdTaken;

  /// No description provided for @adminPlanNeverDeleted.
  ///
  /// In en, this message translates to:
  /// **'Plans are never deleted — turn one off instead, so old payment records keep working.'**
  String get adminPlanNeverDeleted;

  /// No description provided for @adminSeedPlans.
  ///
  /// In en, this message translates to:
  /// **'Create default plans'**
  String get adminSeedPlans;

  /// No description provided for @adminSeedPlansDone.
  ///
  /// In en, this message translates to:
  /// **'Default plans created.'**
  String get adminSeedPlansDone;

  /// No description provided for @adminNoPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans exist yet.'**
  String get adminNoPlans;

  /// No description provided for @adminClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'ONLINE CLASSES'**
  String get adminClassesTitle;

  /// No description provided for @adminClassTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminClassTitleField;

  /// No description provided for @adminClassDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminClassDescription;

  /// No description provided for @adminClassCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminClassCategory;

  /// No description provided for @adminClassDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get adminClassDuration;

  /// No description provided for @adminClassYoutubeUrl.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL'**
  String get adminClassYoutubeUrl;

  /// No description provided for @adminClassThumbnailUrl.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL'**
  String get adminClassThumbnailUrl;

  /// No description provided for @adminClassThumbnailHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the YouTube thumbnail.'**
  String get adminClassThumbnailHelp;

  /// No description provided for @adminClassPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminClassPublished;

  /// No description provided for @adminClassAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a class'**
  String get adminClassAdd;

  /// No description provided for @adminClassPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get adminClassPreview;

  /// No description provided for @adminClassUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Paste a YouTube link, for example https://youtu.be/xxxxxxxxxxx'**
  String get adminClassUrlInvalid;

  /// No description provided for @adminClassUnlistedNote.
  ///
  /// In en, this message translates to:
  /// **'Use unlisted YouTube videos. Anyone with the link can watch, so do not share it outside the app.'**
  String get adminClassUnlistedNote;

  /// No description provided for @adminAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'ANNOUNCEMENTS'**
  String get adminAnnouncementsTitle;

  /// No description provided for @adminAnnouncementTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminAnnouncementTitleField;

  /// No description provided for @adminAnnouncementMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get adminAnnouncementMessage;

  /// No description provided for @adminAnnouncementActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminAnnouncementActive;

  /// No description provided for @adminAnnouncementEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Hide after (optional)'**
  String get adminAnnouncementEndsAt;

  /// No description provided for @adminAnnouncementAdd.
  ///
  /// In en, this message translates to:
  /// **'Add an announcement'**
  String get adminAnnouncementAdd;

  /// No description provided for @adminSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'GYM SETTINGS'**
  String get adminSettingsTitle;

  /// No description provided for @adminSettingsMoneyGroup.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get adminSettingsMoneyGroup;

  /// No description provided for @adminSettingsUpiGroup.
  ///
  /// In en, this message translates to:
  /// **'UPI payment'**
  String get adminSettingsUpiGroup;

  /// No description provided for @adminSettingsContactGroup.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get adminSettingsContactGroup;

  /// No description provided for @adminSettingsStoreGroup.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get adminSettingsStoreGroup;

  /// No description provided for @adminSetRegistrationFee.
  ///
  /// In en, this message translates to:
  /// **'Registration fee (₹)'**
  String get adminSetRegistrationFee;

  /// No description provided for @adminSetPtFee.
  ///
  /// In en, this message translates to:
  /// **'Personal training fee (₹)'**
  String get adminSetPtFee;

  /// No description provided for @adminSetPtFreeDays.
  ///
  /// In en, this message translates to:
  /// **'Free personal training days'**
  String get adminSetPtFreeDays;

  /// No description provided for @adminSetUpiId.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get adminSetUpiId;

  /// No description provided for @adminSetUpiName.
  ///
  /// In en, this message translates to:
  /// **'Name shown in UPI apps'**
  String get adminSetUpiName;

  /// No description provided for @adminSetApprovalTime.
  ///
  /// In en, this message translates to:
  /// **'Approval time text'**
  String get adminSetApprovalTime;

  /// No description provided for @adminSetApprovalTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Members see: “This usually takes …”'**
  String get adminSetApprovalTimeHelp;

  /// No description provided for @adminSetAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get adminSetAddress;

  /// No description provided for @adminSetTimings.
  ///
  /// In en, this message translates to:
  /// **'Timings'**
  String get adminSetTimings;

  /// No description provided for @adminSetPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get adminSetPhone;

  /// No description provided for @adminSetEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminSetEmail;

  /// No description provided for @adminSetInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram URL'**
  String get adminSetInstagram;

  /// No description provided for @adminSetSupplementsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Supplements store live'**
  String get adminSetSupplementsEnabled;

  /// No description provided for @adminSetClothesEnabled.
  ///
  /// In en, this message translates to:
  /// **'Clothes store live'**
  String get adminSetClothesEnabled;

  /// No description provided for @adminErrorNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get adminErrorNumber;

  /// No description provided for @adminErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'This cannot be empty'**
  String get adminErrorRequired;

  /// No description provided for @adminWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'The change could not be saved. Check your connection and try again.'**
  String get adminWriteFailed;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY POLICY'**
  String get legalPrivacyTitle;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'TERMS OF USE'**
  String get legalTermsTitle;

  /// No description provided for @legalRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'REFUND POLICY'**
  String get legalRefundTitle;

  /// No description provided for @legalPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'[TO BE WRITTEN BY GYM]'**
  String get legalPlaceholder;

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String legalLastUpdated(String date);

  /// No description provided for @legalDataWeStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'What we store'**
  String get legalDataWeStoreTitle;

  /// No description provided for @legalDataWeStoreBody.
  ///
  /// In en, this message translates to:
  /// **'When you create an account we store your name, email address and (if you give it) your phone number. When you pay we store the plan you chose, the amount, the payment method, the UPI reference number you type in, and whether the gym approved it. We also store the start and end dates of your membership. We never store your UPI PIN, card number or bank password — the app never asks for them.'**
  String get legalDataWeStoreBody;

  /// No description provided for @legalDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data'**
  String get legalDeletionTitle;

  /// No description provided for @legalDeletionBody.
  ///
  /// In en, this message translates to:
  /// **'Email {email} from your registered address and ask for deletion. The gym removes your account and payment records within 30 days, except records it must keep for tax.'**
  String legalDeletionBody(String email);

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacy;

  /// No description provided for @legalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get legalTerms;

  /// No description provided for @legalRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund policy'**
  String get legalRefund;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'PAGE NOT FOUND'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The page you asked for does not exist. It may have moved.'**
  String get notFoundBody;

  /// No description provided for @guardAdminOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin only'**
  String get guardAdminOnlyTitle;

  /// No description provided for @guardAdminOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'This part of the app is for the gym’s staff.'**
  String get guardAdminOnlyBody;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
