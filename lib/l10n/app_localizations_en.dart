// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NH Fitness';

  @override
  String get appTitle => 'NH Fitness — Gym membership';

  @override
  String get tagline => 'Train hard. Stay focused. Be strong.';

  @override
  String get motto => 'BE FIT. BE STRONG. BE YOU.';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaveChanges => 'Save changes';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionBackToHome => 'Back to home';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionLogOut => 'Log out';

  @override
  String get actionViewAll => 'View all';

  @override
  String get actionNext => 'Next';

  @override
  String get actionPrevious => 'Previous';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateSaved => 'Saved';

  @override
  String get stateCopiedToClipboard => 'Copied';

  @override
  String get stateComingSoon => 'Coming soon';

  @override
  String get stateFree => 'FREE';

  @override
  String get stateOffline =>
      'You are offline. Some things may not be up to date.';

  @override
  String get stateGenericError => 'Something went wrong. Please try again.';

  @override
  String get stateNoInternet =>
      'No internet connection. Check your network and try again.';

  @override
  String get stateNothingHere => 'Nothing here yet';

  @override
  String get navHome => 'Home';

  @override
  String get navPlans => 'Plans';

  @override
  String get navOnlineClasses => 'Online classes';

  @override
  String get navSupplements => 'Supplements';

  @override
  String get navClothes => 'Clothes';

  @override
  String get navSoon => 'Soon';

  @override
  String get navLogin => 'Login';

  @override
  String get navRegisterNow => 'Register now';

  @override
  String get navMyAccount => 'My account';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navProfile => 'Profile';

  @override
  String get navClasses => 'Classes';

  @override
  String get navMenu => 'Menu';

  @override
  String get navBackToSite => 'Back to site';

  @override
  String get homeHeroLabel => 'GYM MEMBERSHIP';

  @override
  String get homeHeroLine1 => 'STRONGER THAN';

  @override
  String get homeHeroLine2 => 'YESTERDAY';

  @override
  String get homeCtaStart => 'Start your fitness journey';

  @override
  String get homeOfferBadgeTitle => '7 days personal training FREE';

  @override
  String get homeOfferBadgeSubtitle => 'With every new membership';

  @override
  String get homeTicker =>
      'TRAIN HARD ✦ STAY FOCUSED ✦ BE STRONG ✦ BE FIT ✦ BE YOU';

  @override
  String get homeWhyTitle => 'WHY NH FITNESS';

  @override
  String get homeWhyEquipment => 'Modern equipment';

  @override
  String get homeWhyEquipmentBody =>
      'Machines and free weights kept in top condition.';

  @override
  String get homeWhyTrainers => 'Expert trainers';

  @override
  String get homeWhyTrainersBody => 'Certified trainers who correct your form.';

  @override
  String get homeWhyDiet => 'Diet consultation';

  @override
  String get homeWhyDietBody => 'A simple eating plan that fits your day.';

  @override
  String get homeWhyHygiene => 'Clean and hygienic';

  @override
  String get homeWhyHygieneBody => 'Cleaned through the day, every day.';

  @override
  String get homeMembershipTitle => 'GYM MEMBERSHIP';

  @override
  String get homePathTitle => 'PICK YOUR PATH';

  @override
  String get homeOfferBandTitle => '7 DAYS PERSONAL TRAINING FREE!';

  @override
  String get homePricesError => 'Prices could not load. Try again.';

  @override
  String get homeNoPlans =>
      'No plans are available right now. Please call the gym.';

  @override
  String get footerThanks => 'Thank you!';

  @override
  String get footerAddress => 'Address';

  @override
  String get footerTimings => 'Timings';

  @override
  String get footerPhone => 'Phone';

  @override
  String get footerEmail => 'Email';

  @override
  String get footerInstagram => 'Instagram';

  @override
  String get footerLinks => 'Links';

  @override
  String footerRights(String year) {
    return '© $year NH Fitness';
  }

  @override
  String get exploreTitle => 'PICK YOUR PATH';

  @override
  String get exploreSubtitle => 'Choose where you want to start.';

  @override
  String get exploreMembership => 'Membership plans';

  @override
  String exploreMembershipFrom(String amount) {
    return 'From $amount a month';
  }

  @override
  String get explorePtFreeTag => '7 days PT free';

  @override
  String get exploreClasses => 'Online classes';

  @override
  String get exploreClassesBody => 'Train with our trainers from home.';

  @override
  String get exploreSupplementsBody =>
      'Protein, creatine and more at the gym counter.';

  @override
  String get exploreClothesBody => 'NH Fitness tees, shorts and bags.';

  @override
  String get plansTitle => 'CHOOSE YOUR PLAN';

  @override
  String get plansSubtitle => 'Cancel anytime. No hidden charges.';

  @override
  String get plansBestValue => 'Best value';

  @override
  String get plansChoosePlan => 'Choose plan';

  @override
  String plansPerMonth(String amount) {
    return '$amount / month';
  }

  @override
  String get plansPayAsYouGo => 'Pay as you go';

  @override
  String get plansMonthsOne => '1 month';

  @override
  String plansMonthsOther(String months) {
    return '$months months';
  }

  @override
  String get plansAddPtTitle => 'Add personal training';

  @override
  String plansAddPtFreeDays(String days) {
    return 'First $days days free';
  }

  @override
  String get plansOrderSummary => 'Order summary';

  @override
  String get plansSummaryPlan => 'Plan';

  @override
  String get plansSummaryRegistration => 'Registration charge';

  @override
  String get plansSummaryPt => 'Personal training';

  @override
  String get plansSummaryTotal => 'Total';

  @override
  String get plansRegistrationNote => 'One-time, for new members';

  @override
  String get plansPtFreeNote => '7 days personal training free';

  @override
  String plansPtFreeDaysLabel(String days) {
    return '$days days personal training';
  }

  @override
  String get plansPtCharge => 'Personal training charge';

  @override
  String get plansContinueToPayment => 'Continue to payment';

  @override
  String get plansSelected => 'Selected';

  @override
  String get checkoutTitle => 'PAYMENT';

  @override
  String checkoutPayingFor(String planName) {
    return '$planName membership';
  }

  @override
  String get checkoutMethodTitle => 'How do you want to pay?';

  @override
  String get checkoutMethodUpi => 'UPI';

  @override
  String get checkoutMethodCash => 'Pay at gym (cash)';

  @override
  String get checkoutMethodCard => 'Card';

  @override
  String get checkoutMethodNetBanking => 'Net banking';

  @override
  String checkoutUpiScanHint(String amount) {
    return 'Scan this QR code in any UPI app and pay $amount.';
  }

  @override
  String get checkoutUpiIdLabel => 'UPI ID';

  @override
  String get checkoutUpiIdCopied => 'UPI ID copied';

  @override
  String get checkoutPayWithUpiApp => 'Pay with UPI app';

  @override
  String get checkoutUpiAppFailed =>
      'No UPI app could be opened. Scan the QR code instead.';

  @override
  String get checkoutUtrLabel => 'UPI reference number (UTR)';

  @override
  String get checkoutUtrHelp =>
      '12 digits. You will find it in your payment app next to the payment.';

  @override
  String get checkoutUtrError =>
      'Enter the 12-digit UPI reference number from your payment app';

  @override
  String checkoutIHavePaid(String amount) {
    return 'I have paid $amount';
  }

  @override
  String checkoutCashText(String amount) {
    return 'Pay $amount at the gym reception. Your plan starts when the gym confirms payment.';
  }

  @override
  String get checkoutSubmitRequest => 'Submit request';

  @override
  String get checkoutNoPinNote =>
      'Sample payment flow: we never ask for your UPI PIN';

  @override
  String get checkoutUpiNotSetUp =>
      'The gym has not added its UPI ID yet. Please choose “Pay at gym” or call the gym.';

  @override
  String get checkoutSubmitFailed =>
      'Your request could not be sent. Check your connection and try again.';

  @override
  String get checkoutPendingExists =>
      'You already have a request waiting for approval';

  @override
  String get checkoutPendingExistsBody =>
      'The gym is checking your last payment. You can see it in your account.';

  @override
  String get submittedTitle => 'REQUEST SENT';

  @override
  String submittedBody(String time) {
    return 'The gym will check your payment and activate your plan. This usually takes $time.';
  }

  @override
  String get submittedGoToAccount => 'Go to my account';

  @override
  String get authRegisterTitle => 'CREATE ACCOUNT';

  @override
  String get authRegisterSubtitle =>
      'One account for the gym and the online classes.';

  @override
  String get authLoginTitle => 'WELCOME BACK';

  @override
  String get authLoginSubtitle => 'Log in to see your membership.';

  @override
  String get authForgotTitle => 'RESET PASSWORD';

  @override
  String get authForgotSubtitle =>
      'We will email you a link to set a new password.';

  @override
  String get authFieldName => 'Full name';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldPhone => 'Phone number';

  @override
  String get authFieldPhoneHelp =>
      '10 digits. The gym uses it to reach you about your membership.';

  @override
  String get authFieldPassword => 'Password';

  @override
  String get authFieldPasswordHelp => 'At least 8 characters';

  @override
  String get authFieldConfirmPassword => 'Confirm password';

  @override
  String get authFieldCurrentPassword => 'Current password';

  @override
  String get authFieldNewPassword => 'New password';

  @override
  String get authAgreeTerms => 'I agree to the Terms and Privacy Policy';

  @override
  String get authAgreeTermsError =>
      'Please accept the Terms and Privacy Policy to continue';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authLogIn => 'Log in';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authOr => 'or';

  @override
  String get authForgotPasswordLink => 'Forgot password?';

  @override
  String get authSendResetLink => 'Send reset link';

  @override
  String authResetLinkSent(String email) {
    return 'We sent a reset link to $email. Check your inbox and spam folder.';
  }

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authNoAccount => 'New to NH Fitness?';

  @override
  String get authOtpSoon => 'Phone OTP login coming soon';

  @override
  String get authChangePassword => 'Change password';

  @override
  String get authPasswordChanged => 'Your password has been changed.';

  @override
  String get authVerifyEmailTitle => 'Verify your email';

  @override
  String authVerifyEmailBody(String email) {
    return 'We sent a link to $email. Verifying keeps your account safe.';
  }

  @override
  String get authVerifyEmailResend => 'Send again';

  @override
  String get authVerifyEmailSent => 'Verification email sent.';

  @override
  String get authErrorNameRequired => 'Enter your name';

  @override
  String get authErrorEmailRequired => 'Enter your email';

  @override
  String get authErrorEmailInvalid =>
      'Enter a valid email like name@example.com';

  @override
  String get authErrorPasswordShort => 'Use at least 8 characters';

  @override
  String get authErrorPasswordMismatch => 'The two passwords do not match';

  @override
  String get authErrorPhoneInvalid => 'Enter a 10-digit phone number';

  @override
  String get authErrorWrongPassword =>
      'That password is not right. Try again or reset it.';

  @override
  String get authErrorUserNotFound =>
      'No account uses this email. Create one instead.';

  @override
  String get authErrorEmailInUse =>
      'This email already has an account. Log in instead.';

  @override
  String get authErrorWeakPassword =>
      'Pick a stronger password of at least 8 characters.';

  @override
  String get authErrorTooManyRequests =>
      'Too many tries. Wait a minute and try again.';

  @override
  String get authErrorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get authErrorGoogleCancelled => 'Google sign-in was cancelled.';

  @override
  String get authErrorSignInNotEnabled =>
      'This sign-in method is not switched on yet. Ask the gym to enable it in Firebase (Authentication → Sign-in method).';

  @override
  String get authErrorDomainNotAuthorized =>
      'Sign-in is blocked from this web address. Add it in Firebase under Authentication → Settings → Authorized domains.';

  @override
  String get authErrorRecentLogin =>
      'For safety, log in again before changing your password.';

  @override
  String get accountTitle => 'MY MEMBERSHIP';

  @override
  String accountGreeting(String firstName) {
    return 'Hi, $firstName';
  }

  @override
  String get accountMembershipTitle => 'Membership';

  @override
  String get accountStatusActive => 'Active';

  @override
  String get accountStatusPending => 'Pending';

  @override
  String get accountStatusRejected => 'Rejected';

  @override
  String get accountStatusExpired => 'Expired';

  @override
  String get accountStatusUpcoming => 'Starts soon';

  @override
  String get accountStatusApproved => 'Approved';

  @override
  String get accountStartDate => 'Started';

  @override
  String get accountValidTill => 'Valid till';

  @override
  String accountDaysLeft(String days) {
    return '$days days left';
  }

  @override
  String get accountDaysLeftLabel => 'days left';

  @override
  String get accountOneDayLeft => 'Last day today';

  @override
  String get accountRenewPlan => 'Renew plan';

  @override
  String get accountNoPlanTitle => 'You don’t have a plan yet';

  @override
  String get accountNoPlanBody =>
      'Pick a plan to start training and unlock the online classes.';

  @override
  String get accountChoosePlan => 'Choose a plan';

  @override
  String get accountWaitingTitle => 'Waiting for approval';

  @override
  String accountWaitingBody(String time) {
    return 'The gym is checking your payment. This usually takes $time.';
  }

  @override
  String get accountRejectedTitle => 'Payment not approved';

  @override
  String accountRejectedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String accountExpiredTitle(String date) {
    return 'Your plan ended on $date';
  }

  @override
  String accountExpiryBanner(String days) {
    return 'Your plan ends in $days days. Renew now.';
  }

  @override
  String get accountExpiryBannerToday => 'Your plan ends today. Renew now.';

  @override
  String accountUpcomingStarts(String date) {
    return 'Starts on $date';
  }

  @override
  String get accountFreePtTitle => 'Free personal training';

  @override
  String accountFreePtDaysLeft(String left, String total) {
    return '$left of $total free days left';
  }

  @override
  String accountFreePtUsedUp(String total) {
    return 'You have used all $total free days.';
  }

  @override
  String get accountClassesPreviewTitle => 'Online classes';

  @override
  String get accountPaymentsPreviewTitle => 'Recent payments';

  @override
  String accountSubmittedOn(String date) {
    return 'Sent on $date';
  }

  @override
  String get accountSubmittedOnLabel => 'Sent on';

  @override
  String accountProgressUsed(String used, String total) {
    return '$used of $total days used';
  }

  @override
  String get paymentsTitle => 'PAYMENT HISTORY';

  @override
  String get paymentsEmpty => 'You have not made any payments yet.';

  @override
  String get paymentsMethodLabel => 'Method';

  @override
  String get paymentsMethodUpi => 'UPI';

  @override
  String get paymentsMethodCash => 'Cash';

  @override
  String paymentsUtr(String ref) {
    return 'UTR $ref';
  }

  @override
  String paymentsPlanLine(String planName, String months) {
    return '$planName · $months';
  }

  @override
  String get paymentsWithPt => 'With personal training';

  @override
  String get paymentsLoadMore => 'Load more';

  @override
  String get profileTitle => 'PROFILE';

  @override
  String get profileEmailReadOnly => 'Email cannot be changed.';

  @override
  String get profileSaved => 'Your profile has been updated.';

  @override
  String get profileGoogleAccount =>
      'You log in with Google, so there is no password to change.';

  @override
  String get profileDeleteDataTitle => 'Want your data deleted?';

  @override
  String profileDeleteDataBody(String email) {
    return 'Email $email and the gym will remove your account.';
  }

  @override
  String get classesTitle => 'ONLINE CLASSES';

  @override
  String get classesLockedTitle => 'Online classes are for active members';

  @override
  String get classesLockedBody => 'Pick a plan to unlock every class.';

  @override
  String get classesEmpty => 'No classes have been added yet. Check back soon.';

  @override
  String get classesAll => 'All';

  @override
  String classesDuration(String minutes) {
    return '$minutes min';
  }

  @override
  String get classesLive => 'Online';

  @override
  String get classesNotFound => 'This class is no longer available.';

  @override
  String get classesAbout => 'About this class';

  @override
  String get announcementDismiss => 'Dismiss announcement';

  @override
  String get adminTitle => 'ADMIN';

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavPayments => 'Pending payments';

  @override
  String get adminNavMembers => 'Members';

  @override
  String get adminNavPlans => 'Plans and prices';

  @override
  String get adminNavClasses => 'Online classes';

  @override
  String get adminNavAnnouncements => 'Announcements';

  @override
  String get adminNavSettings => 'Settings';

  @override
  String get adminNavStaff => 'Staff access';

  @override
  String get adminStaffTitle => 'STAFF ACCESS';

  @override
  String get adminStaffSubtitle => 'Who can use the admin panel.';

  @override
  String get adminStaffOwnerOnlyTitle => 'Only an owner can change this';

  @override
  String get adminStaffOwnerOnlyBody =>
      'Ask the gym owner to add or remove staff.';

  @override
  String get adminStaffOwnersSection => 'Owners';

  @override
  String get adminStaffStaffSection => 'Staff';

  @override
  String get adminStaffOwnerNote =>
      'Owners are set in the Firebase Console and cannot be changed here. An owner always keeps access, so staff can never lock you out.';

  @override
  String get adminStaffOwnerBadge => 'Owner';

  @override
  String get adminStaffNone => 'No staff have been given access yet.';

  @override
  String get adminStaffAddTitle => 'Give someone admin access';

  @override
  String get adminStaffAddHelp =>
      'They must sign in to the app once before they appear here.';

  @override
  String get adminStaffSearchHint => 'Search by name or email';

  @override
  String get adminStaffNoMatches =>
      'Nobody matches that. Check the spelling, or ask them to sign in to the app once.';

  @override
  String get adminStaffAdd => 'Give access';

  @override
  String get adminStaffAlreadyHasAccess => 'Already has access';

  @override
  String adminStaffAdded(String name) {
    return '$name can now use the admin panel.';
  }

  @override
  String get adminStaffRemove => 'Remove';

  @override
  String get adminStaffRemoveTitle => 'Remove admin access?';

  @override
  String adminStaffRemoveBody(String name) {
    return '$name will lose the admin panel. Their membership and payments are not affected.';
  }

  @override
  String adminStaffRemoved(String name) {
    return '$name no longer has admin access.';
  }

  @override
  String adminStaffAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String get adminTileActiveMembers => 'Active members';

  @override
  String get adminTileExpiring => 'Expiring in next 7 days';

  @override
  String get adminTilePending => 'Pending approvals';

  @override
  String get adminTileIncome => 'Income this month';

  @override
  String get adminPendingListTitle => 'Pending payments';

  @override
  String get adminExpiringListTitle => 'Expiring in the next 7 days';

  @override
  String get adminNoPending => 'No payments are waiting for approval.';

  @override
  String get adminNoExpiring => 'No memberships end in the next 7 days.';

  @override
  String get adminPaymentsTitle => 'PAYMENTS';

  @override
  String get adminTabPending => 'Pending';

  @override
  String get adminTabApproved => 'Approved';

  @override
  String get adminTabRejected => 'Rejected';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminDuplicateUtr => 'UTR already used';

  @override
  String get adminApproveTitle => 'Approve payment';

  @override
  String adminApproveBody(String memberName, String planName, String amount) {
    return '$memberName · $planName · $amount';
  }

  @override
  String get adminApproveStartDate => 'Start date';

  @override
  String get adminApproveEndDate => 'End date';

  @override
  String get adminApproveRenewalNote =>
      'This is a renewal, so it starts the day after the current plan ends.';

  @override
  String get adminApproveConfirm => 'Approve and activate';

  @override
  String get adminApproved => 'Payment approved. The membership is active.';

  @override
  String get adminRejectTitle => 'Reject payment';

  @override
  String get adminRejectReasonLabel => 'Reason (the member will see this)';

  @override
  String get adminRejectReasonHint => 'Payment not received';

  @override
  String get adminRejectReasonRequired =>
      'Write a short reason so the member knows what to do.';

  @override
  String get adminRejectConfirm => 'Reject payment';

  @override
  String get adminRejected => 'Payment rejected.';

  @override
  String get adminAlreadyReviewed => 'This request has already been reviewed.';

  @override
  String get adminMembersTitle => 'MEMBERS';

  @override
  String get adminMembersSearchHint => 'Search by name, email or phone';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterActive => 'Active';

  @override
  String get adminFilterExpiring => 'Expiring soon';

  @override
  String get adminFilterExpired => 'Expired';

  @override
  String get adminFilterNeverJoined => 'Never joined';

  @override
  String get adminRecordCash => 'Record cash payment';

  @override
  String get adminRecordCashTitle => 'Record a cash payment';

  @override
  String get adminRecordCashMember => 'Member';

  @override
  String get adminRecordCashDone =>
      'Cash payment recorded. The membership is active.';

  @override
  String get adminMembersEmpty => 'No members match this filter.';

  @override
  String get adminNoMembership => 'No membership';

  @override
  String get adminMemberDetailTitle => 'Member';

  @override
  String get adminMemberProfile => 'Profile';

  @override
  String get adminMemberMemberships => 'Memberships';

  @override
  String get adminMemberRequests => 'Payment requests';

  @override
  String get adminFreePtTitle => 'Free personal training days';

  @override
  String adminFreePtUsed(String used, String total) {
    return '$used of $total used';
  }

  @override
  String get adminFreePtAdd => '+1 day used';

  @override
  String get adminFreePtRemove => '−1';

  @override
  String get adminEditEndDate => 'Edit end date';

  @override
  String get adminEditEndDateBody =>
      'Only change this to correct a mistake. The member will see the new date straight away.';

  @override
  String get adminEndDateUpdated => 'End date updated.';

  @override
  String get adminPlansTitle => 'PLANS AND PRICES';

  @override
  String get adminPlanName => 'Plan name';

  @override
  String get adminPlanMonths => 'Months';

  @override
  String get adminPlanPrice => 'Price (₹)';

  @override
  String get adminPlanSortOrder => 'Sort order';

  @override
  String get adminPlanBestValue => 'Best value';

  @override
  String get adminPlanActive => 'Active';

  @override
  String get adminPlanAdd => 'Add a plan';

  @override
  String get adminPlanNewTitle => 'New plan';

  @override
  String get adminPlanEditTitle => 'Edit plan';

  @override
  String get adminPlanIdLabel => 'Plan ID';

  @override
  String get adminPlanIdHelp =>
      'Lowercase letters, numbers and underscores. It cannot be changed later.';

  @override
  String get adminPlanIdTaken => 'A plan with this ID already exists.';

  @override
  String get adminPlanNeverDeleted =>
      'Plans are never deleted — turn one off instead, so old payment records keep working.';

  @override
  String get adminSeedPlans => 'Create default plans';

  @override
  String get adminSeedPlansDone => 'Default plans created.';

  @override
  String get adminNoPlans => 'No plans exist yet.';

  @override
  String get adminClassesTitle => 'ONLINE CLASSES';

  @override
  String get adminClassTitleField => 'Title';

  @override
  String get adminClassDescription => 'Description';

  @override
  String get adminClassCategory => 'Category';

  @override
  String get adminClassDuration => 'Duration (minutes)';

  @override
  String get adminClassYoutubeUrl => 'YouTube URL';

  @override
  String get adminClassThumbnailUrl => 'Thumbnail URL';

  @override
  String get adminClassThumbnailHelp =>
      'Leave empty to use the YouTube thumbnail.';

  @override
  String get adminClassPublished => 'Published';

  @override
  String get adminClassAdd => 'Add a class';

  @override
  String get adminClassPreview => 'Preview';

  @override
  String get adminClassUrlInvalid =>
      'Paste a YouTube link, for example https://youtu.be/xxxxxxxxxxx';

  @override
  String get adminClassUnlistedNote =>
      'Use unlisted YouTube videos. Anyone with the link can watch, so do not share it outside the app.';

  @override
  String get adminAnnouncementsTitle => 'ANNOUNCEMENTS';

  @override
  String get adminAnnouncementTitleField => 'Title';

  @override
  String get adminAnnouncementMessage => 'Message';

  @override
  String get adminAnnouncementActive => 'Active';

  @override
  String get adminAnnouncementEndsAt => 'Hide after (optional)';

  @override
  String get adminAnnouncementAdd => 'Add an announcement';

  @override
  String get adminSettingsTitle => 'GYM SETTINGS';

  @override
  String get adminSettingsMoneyGroup => 'Prices';

  @override
  String get adminSettingsUpiGroup => 'UPI payment';

  @override
  String get adminSettingsContactGroup => 'Contact details';

  @override
  String get adminSettingsStoreGroup => 'Store';

  @override
  String get adminSetRegistrationFee => 'Registration fee (₹)';

  @override
  String get adminSetPtFee => 'Personal training fee (₹)';

  @override
  String get adminSetPtFreeDays => 'Free personal training days';

  @override
  String get adminSetUpiId => 'UPI ID';

  @override
  String get adminSetUpiName => 'Name shown in UPI apps';

  @override
  String get adminSetApprovalTime => 'Approval time text';

  @override
  String get adminSetApprovalTimeHelp => 'Members see: “This usually takes …”';

  @override
  String get adminSetAddress => 'Address';

  @override
  String get adminSetTimings => 'Timings';

  @override
  String get adminSetPhone => 'Phone';

  @override
  String get adminSetEmail => 'Email';

  @override
  String get adminSetInstagram => 'Instagram URL';

  @override
  String get adminSetSupplementsEnabled => 'Supplements store live';

  @override
  String get adminSetClothesEnabled => 'Clothes store live';

  @override
  String get adminErrorNumber => 'Enter a whole number';

  @override
  String get adminErrorRequired => 'This cannot be empty';

  @override
  String get adminWriteFailed =>
      'The change could not be saved. Check your connection and try again.';

  @override
  String get legalPrivacyTitle => 'PRIVACY POLICY';

  @override
  String get legalTermsTitle => 'TERMS OF USE';

  @override
  String get legalRefundTitle => 'REFUND POLICY';

  @override
  String get legalPlaceholder => '[TO BE WRITTEN BY GYM]';

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get legalDataWeStoreTitle => 'What we store';

  @override
  String get legalDataWeStoreBody =>
      'When you create an account we store your name, email address and (if you give it) your phone number. When you pay we store the plan you chose, the amount, the payment method, the UPI reference number you type in, and whether the gym approved it. We also store the start and end dates of your membership. We never store your UPI PIN, card number or bank password — the app never asks for them.';

  @override
  String get legalDeletionTitle => 'Deleting your data';

  @override
  String legalDeletionBody(String email) {
    return 'Email $email from your registered address and ask for deletion. The gym removes your account and payment records within 30 days, except records it must keep for tax.';
  }

  @override
  String get legalPrivacy => 'Privacy Policy';

  @override
  String get legalTerms => 'Terms';

  @override
  String get legalRefund => 'Refund policy';

  @override
  String get notFoundTitle => 'PAGE NOT FOUND';

  @override
  String get notFoundBody =>
      'The page you asked for does not exist. It may have moved.';

  @override
  String get guardAdminOnlyTitle => 'Admin only';

  @override
  String get guardAdminOnlyBody =>
      'This part of the app is for the gym’s staff.';
}
