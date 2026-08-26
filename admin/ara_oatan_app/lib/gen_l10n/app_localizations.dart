import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('ru'),
    Locale('ky'),
    Locale('fr'),
    Locale('ur'),
    Locale('pt')
  ];

  /// UI string (source key: 1)
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get n1;

  /// UI string (source key: 2)
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get n2;

  /// UI string (source key: 4)
  ///
  /// In en, this message translates to:
  /// **'4'**
  String get n4;

  /// UI string (source key: 5)
  ///
  /// In en, this message translates to:
  /// **'5'**
  String get n5;

  /// UI string (source key: 6)
  ///
  /// In en, this message translates to:
  /// **'6'**
  String get n6;

  /// UI string (source key: 7)
  ///
  /// In en, this message translates to:
  /// **'7'**
  String get n7;

  /// UI string (source key: 8)
  ///
  /// In en, this message translates to:
  /// **'8'**
  String get n8;

  /// UI string (source key: 9)
  ///
  /// In en, this message translates to:
  /// **'9'**
  String get n9;

  /// UI string (source key: 10)
  ///
  /// In en, this message translates to:
  /// **'10'**
  String get n10;

  /// UI string (source key: 11)
  ///
  /// In en, this message translates to:
  /// **'11'**
  String get n11;

  /// UI string (source key: 15)
  ///
  /// In en, this message translates to:
  /// **'15'**
  String get n15;

  /// UI string (source key: 24)
  ///
  /// In en, this message translates to:
  /// **'24'**
  String get n24;

  /// UI string (source key: 25)
  ///
  /// In en, this message translates to:
  /// **'25'**
  String get n25;

  /// UI string (source key: 26)
  ///
  /// In en, this message translates to:
  /// **'26'**
  String get n26;

  /// UI string (source key: 27)
  ///
  /// In en, this message translates to:
  /// **'27'**
  String get n27;

  /// UI string (source key: 28)
  ///
  /// In en, this message translates to:
  /// **'28'**
  String get n28;

  /// UI string (source key: 29)
  ///
  /// In en, this message translates to:
  /// **'29'**
  String get n29;

  /// UI string (source key: 30)
  ///
  /// In en, this message translates to:
  /// **'30'**
  String get n30;

  /// UI string (source key: 31)
  ///
  /// In en, this message translates to:
  /// **'31'**
  String get n31;

  /// UI string (source key: 32)
  ///
  /// In en, this message translates to:
  /// **'32'**
  String get n32;

  /// UI string (source key: 33)
  ///
  /// In en, this message translates to:
  /// **'33'**
  String get n33;

  /// UI string (source key: 34)
  ///
  /// In en, this message translates to:
  /// **'34'**
  String get n34;

  /// UI string (source key: 45)
  ///
  /// In en, this message translates to:
  /// **'45'**
  String get n45;

  /// UI string (source key: 123)
  ///
  /// In en, this message translates to:
  /// **'123'**
  String get n123;

  /// UI string (source key: 561790844)
  ///
  /// In en, this message translates to:
  /// **'561790844'**
  String get n561790844;

  /// UI string (source key: Login)
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// UI string (source key: Email Address)
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email_Address;

  /// UI string (source key: Create Account )
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get create_Account;

  /// UI string (source key: Enter your email...)
  ///
  /// In en, this message translates to:
  /// **'Enter your email...'**
  String get enter_your_email;

  /// UI string (source key: Password)
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// UI string (source key: Enter your password...)
  ///
  /// In en, this message translates to:
  /// **'Enter your password...'**
  String get enter_your_password;

  /// UI string (source key: Select the app language)
  ///
  /// In en, this message translates to:
  /// **'Select the app language'**
  String get select_the_app_language;

  /// UI string (source key: Login with Google)
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get login_with_Google;

  /// UI string (source key: auth_google_pick_title)
  ///
  /// In en, this message translates to:
  /// **'Choose a Google account'**
  String get auth_google_pick_title;

  /// UI string (source key: auth_google_pick_sub)
  ///
  /// In en, this message translates to:
  /// **'Accounts linked to this device'**
  String get auth_google_pick_sub;

  /// UI string (source key: auth_google_recent_account)
  ///
  /// In en, this message translates to:
  /// **'Last used account'**
  String get auth_google_recent_account;

  /// UI string (source key: auth_google_show_accounts)
  ///
  /// In en, this message translates to:
  /// **'Show Google accounts on this device'**
  String get auth_google_show_accounts;

  /// UI string (source key: auth_google_other_account)
  ///
  /// In en, this message translates to:
  /// **'Choose another account'**
  String get auth_google_other_account;

  /// UI string (source key: auth_google_failed)
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get auth_google_failed;

  /// UI string (source key: auth_google_developer_error)
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured. Add your Android SHA-1 in Firebase Console, enable Google in Authentication, and download a new google-services.json.'**
  String get auth_google_developer_error;

  /// UI string (source key: auth_google_not_enabled)
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is disabled in Firebase. Enable it under Authentication → Sign-in method.'**
  String get auth_google_not_enabled;

  /// UI string (source key: auth_google_account_conflict)
  ///
  /// In en, this message translates to:
  /// **'This email is linked to another sign-in method. Use email and password.'**
  String get auth_google_account_conflict;

  /// UI string (source key: auth_google_or)
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get auth_google_or;

  /// UI string (source key: Forgot Password ?)
  ///
  /// In en, this message translates to:
  /// **'Forgot Password ?'**
  String get forgot_Password;

  /// UI string (source key: Register)
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// UI string (source key: Create an account with Google)
  ///
  /// In en, this message translates to:
  /// **'Create an account with Google'**
  String get create_an_account_with_Google;

  /// UI string (source key: Please fill in all fields to register)
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields to register'**
  String get please_fill_in_all_fields_to_register;

  /// UI string (source key: Full Name)
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_Name;

  /// UI string (source key: Confirm Password)
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_Password;

  /// UI string (source key: Read the Terms of Service and Privacy Policy)
  ///
  /// In en, this message translates to:
  /// **'Read the Terms of Service and Privacy Policy'**
  String get read_the_Terms_of_Service_and_Privacy_Policy;

  /// UI string (source key: I agree to the Terms & Conditions)
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions'**
  String get i_agree_to_the_Terms_Conditions;

  /// UI string (source key: Full Name is required)
  ///
  /// In en, this message translates to:
  /// **'Full Name is required'**
  String get full_Name_is_required;

  /// UI string (source key: Please choose an option from the dropdown)
  ///
  /// In en, this message translates to:
  /// **'Please choose an option from the dropdown'**
  String get please_choose_an_option_from_the_dropdown;

  /// UI string (source key: Email Address is required)
  ///
  /// In en, this message translates to:
  /// **'Email Address is required'**
  String get email_Address_is_required;

  /// UI string (source key: Mobile Number is required)
  ///
  /// In en, this message translates to:
  /// **'Mobile Number is required'**
  String get mobile_Number_is_required;

  /// UI string (source key: Password is required)
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get password_is_required;

  /// UI string (source key: Confirm Password is required)
  ///
  /// In en, this message translates to:
  /// **'Confirm Password is required'**
  String get confirm_Password_is_required;

  /// UI string (source key: Already have an account?)
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get already_have_an_account;

  /// UI string (source key: Sign In)
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_In;

  /// UI string (source key: Success Partner Registration)
  ///
  /// In en, this message translates to:
  /// **'Success Partner Registration'**
  String get success_Partner_Registration;

  /// UI string (source key: Welcome to Become a Success Partner)
  ///
  /// In en, this message translates to:
  /// **'Welcome to Become a Success Partner'**
  String get welcome_to_Become_a_Success_Partner;

  /// UI string (source key: Join us as a Success Partner to enhance our service quality and accelerate outreach, whether you are a government entity, a company, or an individual.)
  ///
  /// In en, this message translates to:
  /// **'Join us as a Success Partner to enhance our service quality and accelerate outreach, whether you are a government entity, a company, or an individual.'**
  String
      get join_us_as_a_Success_Partner_to_enhance_our_service_quality_and_accelerate_outre;

  /// UI string (source key: Register Now)
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get register_Now;

  /// UI string (source key: Home)
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// UI string (source key: The Qibla for Islam and Muslims)
  ///
  /// In en, this message translates to:
  /// **'The Qibla for Islam and Muslims'**
  String get the_Qibla_for_Islam_and_Muslims;

  /// UI string (source key: List of regions)
  ///
  /// In en, this message translates to:
  /// **'List of regions'**
  String get list_of_regions;

  /// UI string (source key: Number of destinations: )
  ///
  /// In en, this message translates to:
  /// **'Number of destinations: '**
  String get number_of_destinations;

  /// UI string (source key: Specify the region)
  ///
  /// In en, this message translates to:
  /// **'Specify the region'**
  String get specify_the_region;

  /// UI string (source key: saudi)
  ///
  /// In en, this message translates to:
  /// **'saudi'**
  String get saudi;

  /// UI string (source key: Select region / city)
  ///
  /// In en, this message translates to:
  /// **'Select region / city'**
  String get select_region_city;

  /// UI string (source key: Cities/provinces)
  ///
  /// In en, this message translates to:
  /// **'Cities/provinces'**
  String get cities_provinces;

  /// UI string (source key: Browse cities/counties in)
  ///
  /// In en, this message translates to:
  /// **'Browse cities/counties in'**
  String get browse_cities_counties_in;

  /// UI string (source key: Change)
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// UI string (source key: View Now)
  ///
  /// In en, this message translates to:
  /// **'View Now'**
  String get view_Now;

  /// UI string (source key: Devils Cove)
  ///
  /// In en, this message translates to:
  /// **'Devils Cove'**
  String get devils_Cove;

  /// UI string (source key: 4.7 Stars)
  ///
  /// In en, this message translates to:
  /// **'4.7 Stars'**
  String get n4_7_Stars;

  /// UI string (source key: Juniper Beach)
  ///
  /// In en, this message translates to:
  /// **'Juniper Beach'**
  String get juniper_Beach;

  /// UI string (source key: 4.5 Stars)
  ///
  /// In en, this message translates to:
  /// **'4.5 Stars'**
  String get n4_5_Stars;

  /// UI string (source key: YOU ARE BROWSING NOW)
  ///
  /// In en, this message translates to:
  /// **'YOU ARE BROWSING NOW'**
  String get yOU_ARE_BROWSING_NOW;

  /// UI string (source key: Change country)
  ///
  /// In en, this message translates to:
  /// **'Change country'**
  String get change_country;

  /// UI string (source key: Change region)
  ///
  /// In en, this message translates to:
  /// **'Change region'**
  String get change_region;

  /// UI string (source key: Added destinations)
  ///
  /// In en, this message translates to:
  /// **'Added destinations'**
  String get added_destinations;

  /// UI string (source key: Suggest a Place)
  ///
  /// In en, this message translates to:
  /// **'Suggest a Place'**
  String get suggest_a_Place;

  /// UI string (source key: Add a Special Place)
  ///
  /// In en, this message translates to:
  /// **'Add a Special Place'**
  String get add_a_Special_Place;

  /// UI string (source key: Settings)
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// UI string (source key: Help)
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// UI string (source key: Log Out)
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get log_Out;

  /// UI string (source key: Browse)
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// UI string (source key: Prayer room)
  ///
  /// In en, this message translates to:
  /// **'Prayer room'**
  String get prayer_room;

  /// UI string (source key: Restroom)
  ///
  /// In en, this message translates to:
  /// **'Restroom'**
  String get restroom;

  /// UI string (source key: Restaurant)
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// UI string (source key: Add)
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// UI string (source key: Description)
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// UI string (source key: Enable notifications)
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enable_notifications;

  /// UI string (source key: Edit Profile)
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_Profile;

  /// UI string (source key: Add your phone number)
  ///
  /// In en, this message translates to:
  /// **'Add your phone number'**
  String get add_your_phone_number;

  /// UI string (source key: Address list)
  ///
  /// In en, this message translates to:
  /// **'Address list'**
  String get address_list;

  /// UI string (source key: Support & Customer Service)
  ///
  /// In en, this message translates to:
  /// **'Support & Customer Service'**
  String get support_Customer_Service;

  /// UI string (source key: Electronic Payment History)
  ///
  /// In en, this message translates to:
  /// **'Electronic Payment History'**
  String get electronic_Payment_History;

  /// UI string (source key: Night mode)
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get night_mode;

  /// UI string (source key: Dark  mode)
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get dark_mode;

  /// UI string (source key: Request to delete the account.)
  ///
  /// In en, this message translates to:
  /// **'Request to delete the account.'**
  String get request_to_delete_the_account;

  /// UI string (source key: My account)
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get my_account;

  /// UI string (source key: Name)
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// UI string (source key: Enter your full name)
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enter_your_full_name;

  /// UI string (source key: Phone Number)
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_Number;

  /// UI string (source key: Enter your mobile number)
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enter_your_mobile_number;

  /// UI string (source key: Email)
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// UI string (source key: Outside your city prices are agreed upon with the captain)
  ///
  /// In en, this message translates to:
  /// **'Outside your city prices are agreed upon with the captain'**
  String get outside_your_city_prices_are_agreed_upon_with_the_captain;

  /// UI string (source key: Update Profile)
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get update_Profile;

  /// UI string (source key: Welcome to the Arra Watan app)
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Touri Taxi app'**
  String get welcome_to_the_Arra_Watan_app;

  /// UI string (source key: first global saudi tourist taxi app)
  ///
  /// In en, this message translates to:
  /// **'first global saudi tourist taxi app'**
  String get first_global_saudi_tourist_taxi_app;

  /// UI string (source key: Select the country)
  ///
  /// In en, this message translates to:
  /// **'Select the country'**
  String get select_the_country;

  /// UI string (source key: Start)
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// UI string (source key: Credit Card)
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get credit_Card;

  /// UI string (source key: Your Name)
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get your_Name;

  /// UI string (source key: Example 2026)
  ///
  /// In en, this message translates to:
  /// **'Example 2026'**
  String get example_2026;

  /// UI string (source key: Example 11)
  ///
  /// In en, this message translates to:
  /// **'Example 11'**
  String get example_11;

  /// UI string (source key: CCV)
  ///
  /// In en, this message translates to:
  /// **'CCV'**
  String get cCV;

  /// UI string (source key: Your Name is required)
  ///
  /// In en, this message translates to:
  /// **'Your Name is required'**
  String get your_Name_is_required;

  /// UI string (source key: رقم البطاقة is required)
  ///
  /// In en, this message translates to:
  /// **'رقم البطاقة is required'**
  String get is_required;

  /// UI string (source key: سنة الإنتهاء is required)
  ///
  /// In en, this message translates to:
  /// **'سنة الإنتهاء is required'**
  String get is_required2;

  /// UI string (source key: شهر الإنتهاء is required)
  ///
  /// In en, this message translates to:
  /// **'شهر الإنتهاء is required'**
  String get is_required3;

  /// UI string (source key: CCV is required)
  ///
  /// In en, this message translates to:
  /// **'CCV is required'**
  String get cCV_is_required;

  /// UI string (source key: STC pay)
  ///
  /// In en, this message translates to:
  /// **'STC pay'**
  String get sTC_pay;

  /// UI string (source key: Apple Pay)
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get apple_Pay;

  /// UI string (source key: Cash)
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// UI string (source key: Subscription)
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// UI string (source key: View my trip list map)
  ///
  /// In en, this message translates to:
  /// **'View my trip list map'**
  String get view_my_trip_list_map;

  /// UI string (source key: Trip scheduling)
  ///
  /// In en, this message translates to:
  /// **'Trip scheduling'**
  String get trip_scheduling;

  /// UI string (source key: Payment method.)
  ///
  /// In en, this message translates to:
  /// **'Payment method.'**
  String get payment_method;

  /// UI string (source key: wrong payment method)
  ///
  /// In en, this message translates to:
  /// **'wrong payment method'**
  String get wrong_payment_method;

  /// UI string (source key: Payment details are incorrect. Please check with your bank)
  ///
  /// In en, this message translates to:
  /// **'Payment details are incorrect. Please check with your bank'**
  String get payment_details_are_incorrect_Please_check_with_your_bank;

  /// UI string (source key: Agreed)
  ///
  /// In en, this message translates to:
  /// **'Agreed'**
  String get agreed;

  /// UI string (source key: general tips when visiting this city today:)
  ///
  /// In en, this message translates to:
  /// **'general tips when visiting this city today:'**
  String get general_tips_when_visiting_this_city_today;

  /// UI string (source key: Need extra hours?)
  ///
  /// In en, this message translates to:
  /// **'Need extra hours?'**
  String get need_extra_hours;

  /// UI string (source key: Planning for a longer trip? Add more hours and enjoy the ride!)
  ///
  /// In en, this message translates to:
  /// **'Planning for a longer trip? Add more hours and enjoy the ride!'**
  String get planning_for_a_longer_trip_Add_more_hours_and_enjoy_the_ride;

  /// UI string (source key: Current Hours)
  ///
  /// In en, this message translates to:
  /// **'Current Hours'**
  String get current_Hours;

  /// UI string (source key: Additional Hours?)
  ///
  /// In en, this message translates to:
  /// **'Additional Hours?'**
  String get additional_Hours;

  /// UI string (source key: List of added locations.)
  ///
  /// In en, this message translates to:
  /// **'List of added locations.'**
  String get list_of_added_locations;

  /// UI string (source key: No tours have been added!)
  ///
  /// In en, this message translates to:
  /// **'No tours have been added!'**
  String get no_tours_have_been_added;

  /// UI string (source key: The driver has been assigned,
  ///  and he will be your tour guide based on his knowledge of the places.)
  ///
  /// In en, this message translates to:
  /// **'The driver has been assigned,\n and he will be your tour guide based on his knowledge of the places.'**
  String
      get the_driver_has_been_assigned_and_he_will_be_your_tour_guide_based_on_his_knowled;

  /// UI string (source key: Select the car type)
  ///
  /// In en, this message translates to:
  /// **'Select the car type'**
  String get select_the_car_type;

  /// UI string (source key: TextField)
  ///
  /// In en, this message translates to:
  /// **'TextField'**
  String get textField;

  /// UI string (source key:  Price Summary)
  ///
  /// In en, this message translates to:
  /// **' Price Summary'**
  String get price_Summary;

  /// UI string (source key: Total Booking Hours:)
  ///
  /// In en, this message translates to:
  /// **'Total Booking Hours:'**
  String get total_Booking_Hours;

  /// UI string (source key: Driver Fee:)
  ///
  /// In en, this message translates to:
  /// **'Driver Fee:'**
  String get driver_Fee;

  /// UI string (source key: App Fee  (15%):)
  ///
  /// In en, this message translates to:
  /// **'App Fee  (15%):'**
  String get app_Fee_15;

  /// UI string (source key: Total Deductions:)
  ///
  /// In en, this message translates to:
  /// **'Total Deductions:'**
  String get total_Deductions;

  /// UI string (source key: Total Amount:)
  ///
  /// In en, this message translates to:
  /// **'Total Amount:'**
  String get total_Amount;

  /// UI string (source key: Pay Now)
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get pay_Now;

  /// UI string (source key: Book now)
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get book_now;

  /// UI string (source key: You are currently browsing.)
  ///
  /// In en, this message translates to:
  /// **'You are currently browsing.'**
  String get you_are_currently_browsing;

  /// UI string (source key: Go now.)
  ///
  /// In en, this message translates to:
  /// **'Go now.'**
  String get go_now;

  /// UI string (source key: Booking list.)
  ///
  /// In en, this message translates to:
  /// **'Booking list.'**
  String get booking_list;

  /// UI string (source key: My trip list)
  ///
  /// In en, this message translates to:
  /// **'My trip list'**
  String get my_trip_list;

  /// UI string (source key: Show the interactive map)
  ///
  /// In en, this message translates to:
  /// **'Show the interactive map'**
  String get show_the_interactive_map;

  /// UI string (source key: Select your favorite car.)
  ///
  /// In en, this message translates to:
  /// **'Select your favorite car.'**
  String get select_your_favorite_car;

  /// UI string (source key: Total amount:)
  ///
  /// In en, this message translates to:
  /// **'Total amount:'**
  String get total_amount;

  /// UI string (source key: ر.س )
  ///
  /// In en, this message translates to:
  /// **'ر.س '**
  String get k4b0ced258d;

  /// UI string (source key: You are currently browsing:)
  ///
  /// In en, this message translates to:
  /// **'You are currently browsing:'**
  String get you_are_currently_browsing2;

  /// UI string (source key: Browse the map)
  ///
  /// In en, this message translates to:
  /// **'Browse the map'**
  String get browse_the_map;

  /// UI string (source key: View list)
  ///
  /// In en, this message translates to:
  /// **'View list'**
  String get view_list;

  /// UI string (source key: Add a place from the map.)
  ///
  /// In en, this message translates to:
  /// **'Add a place from the map.'**
  String get add_a_place_from_the_map;

  /// UI string (source key: general information)
  ///
  /// In en, this message translates to:
  /// **'general information'**
  String get general_information;

  /// UI string (source key: Feedback)
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// UI string (source key: Specify the location on the map.)
  ///
  /// In en, this message translates to:
  /// **'Specify the location on the map.'**
  String get specify_the_location_on_the_map;

  /// UI string (source key: Select Location)
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get select_Location;

  /// UI string (source key: Add the specific location.)
  ///
  /// In en, this message translates to:
  /// **'Add the specific location.'**
  String get add_the_specific_location;

  /// UI string (source key: Try to zoom the map to the last point to get an accurate location)
  ///
  /// In en, this message translates to:
  /// **'Try to zoom the map to the last point to get an accurate location'**
  String get try_to_zoom_the_map_to_the_last_point_to_get_an_accurate_location;

  /// UI string (source key: Search)
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// UI string (source key: Show the list of added trips.)
  ///
  /// In en, this message translates to:
  /// **'Show the list of added trips.'**
  String get show_the_list_of_added_trips;

  /// UI string (source key: Manage your team below.)
  ///
  /// In en, this message translates to:
  /// **'Manage your team below.'**
  String get manage_your_team_below;

  /// UI string (source key: Random Name)
  ///
  /// In en, this message translates to:
  /// **'Random Name'**
  String get random_Name;

  /// UI string (source key: user@randomname.com)
  ///
  /// In en, this message translates to:
  /// **'user@randomname.com'**
  String get user_randomname_com;

  /// UI string (source key: Current city of residence)
  ///
  /// In en, this message translates to:
  /// **'Current city of residence'**
  String get current_city_of_residence;

  /// UI string (source key: Please select the city you are currently in)
  ///
  /// In en, this message translates to:
  /// **'Please select the city you are currently in'**
  String get please_select_the_city_you_are_currently_in;

  /// UI string (source key: Additional hours)
  ///
  /// In en, this message translates to:
  /// **'Additional hours'**
  String get additional_hours;

  /// UI string (source key: Total number of hours: )
  ///
  /// In en, this message translates to:
  /// **'Total number of hours: '**
  String get total_number_of_hours;

  /// UI string (source key:   Hours  )
  ///
  /// In en, this message translates to:
  /// **'  Hours  '**
  String get hours;

  /// UI string (source key: Total price:)
  ///
  /// In en, this message translates to:
  /// **'Total price:'**
  String get total_price;

  /// UI string (source key: R.S)
  ///
  /// In en, this message translates to:
  /// **'R.S'**
  String get r_S;

  /// UI string (source key: Application fee 10%:)
  ///
  /// In en, this message translates to:
  /// **'Application fee 10%:'**
  String get application_fee_10;

  /// UI string (source key: VAT 15%: )
  ///
  /// In en, this message translates to:
  /// **'VAT 15%: '**
  String get vAT_15;

  /// UI string (source key:  R.S )
  ///
  /// In en, this message translates to:
  /// **' R.S '**
  String get r_S2;

  /// UI string (source key: Total:  )
  ///
  /// In en, this message translates to:
  /// **'Total:  '**
  String get total;

  /// UI string (source key: Address Details)
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get address_Details;

  /// UI string (source key: Note: This is the address where the driver will be directed)
  ///
  /// In en, this message translates to:
  /// **'Note: This is the address where the driver will be directed'**
  String get note_This_is_the_address_where_the_driver_will_be_directed;

  /// UI string (source key: Address Name (e.g. Home, Work))
  ///
  /// In en, this message translates to:
  /// **'Address Name (e.g. Home, Work)'**
  String get address_Name_e_g_Home_Work;

  /// UI string (source key: Field is required)
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get field_is_required;

  /// UI string (source key: My current location)
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get my_current_location;

  /// UI string (source key: Save Address)
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get save_Address;

  /// UI string (source key: Add Your Address)
  ///
  /// In en, this message translates to:
  /// **'Add Your Address'**
  String get add_Your_Address;

  /// UI string (source key: Schedule the Trip)
  ///
  /// In en, this message translates to:
  /// **'Schedule the Trip'**
  String get schedule_the_Trip;

  /// UI string (source key: Select the Time)
  ///
  /// In en, this message translates to:
  /// **'Select the Time'**
  String get select_the_Time;

  /// UI string (source key: Hour)
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// UI string (source key: Search...)
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search2;

  /// UI string (source key: 00)
  ///
  /// In en, this message translates to:
  /// **'00'**
  String get n00;

  /// UI string (source key: Minute)
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// UI string (source key: PM)
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pM;

  /// UI string (source key: AM)
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get aM;

  /// UI string (source key: The trip time is)
  ///
  /// In en, this message translates to:
  /// **'The trip time is'**
  String get the_trip_time_is;

  /// UI string (source key: Confirm)
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// UI string (source key: + Add New Address)
  ///
  /// In en, this message translates to:
  /// **'+ Add New Address'**
  String get add_New_Address;

  /// UI string (source key: Choose your delivery address:)
  ///
  /// In en, this message translates to:
  /// **'Choose your delivery address:'**
  String get choose_your_delivery_address;

  /// UI string (source key: 456 Park Avenue)
  ///
  /// In en, this message translates to:
  /// **'456 Park Avenue'**
  String get n456_Park_Avenue;

  /// UI string (source key: Suite 789, New York, NY 10022)
  ///
  /// In en, this message translates to:
  /// **'Suite 789, New York, NY 10022'**
  String get suite_789_New_York_NY_10022;

  /// UI string (source key: 789 Broadway)
  ///
  /// In en, this message translates to:
  /// **'789 Broadway'**
  String get n789_Broadway;

  /// UI string (source key: Floor 12, New York, NY 10003)
  ///
  /// In en, this message translates to:
  /// **'Floor 12, New York, NY 10003'**
  String get floor_12_New_York_NY_10003;

  /// UI string (source key: Select the address)
  ///
  /// In en, this message translates to:
  /// **'Select the address'**
  String get select_the_address;

  /// UI string (source key: Note: This is the address where the driver will be directed.)
  ///
  /// In en, this message translates to:
  /// **'Note: This is the address where the driver will be directed.'**
  String get note_This_is_the_address_where_the_driver_will_be_directed2;

  /// UI string (source key: update Address)
  ///
  /// In en, this message translates to:
  /// **'update Address'**
  String get update_Address;

  /// UI string (source key: Selecting the address)
  ///
  /// In en, this message translates to:
  /// **'Selecting the address'**
  String get selecting_the_address;

  /// UI string (source key: 456 Oak Avenue)
  ///
  /// In en, this message translates to:
  /// **'456 Oak Avenue'**
  String get n456_Oak_Avenue;

  /// UI string (source key: Los Angeles, CA 90012)
  ///
  /// In en, this message translates to:
  /// **'Los Angeles, CA 90012'**
  String get los_Angeles_CA_90012;

  /// UI string (source key: 789 Pine Street)
  ///
  /// In en, this message translates to:
  /// **'789 Pine Street'**
  String get n789_Pine_Street;

  /// UI string (source key: Chicago, IL 60601)
  ///
  /// In en, this message translates to:
  /// **'Chicago, IL 60601'**
  String get chicago_IL_60601;

  /// UI string (source key: Don't have an account?  )
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?  '**
  String get don_t_have_an_account;

  /// UI string (source key: Sign Up here)
  ///
  /// In en, this message translates to:
  /// **'Sign Up here'**
  String get sign_Up_here;

  /// UI string (source key: Option 1)
  ///
  /// In en, this message translates to:
  /// **'Option 1'**
  String get option_1;

  /// UI string (source key: Page Title)
  ///
  /// In en, this message translates to:
  /// **'Page Title'**
  String get page_Title;

  /// UI string (source key: Your request has been successfully submitted.)
  ///
  /// In en, this message translates to:
  /// **'Your request has been successfully submitted.'**
  String get your_request_has_been_successfully_submitted;

  /// UI string (source key: You can track the status of your order through the "My Orders" page.)
  ///
  /// In en, this message translates to:
  /// **'You can track the status of your order through the \"My Orders\" page.'**
  String get you_can_track_the_status_of_your_order_through_the_My_Orders_page;

  /// UI string (source key: View Orders)
  ///
  /// In en, this message translates to:
  /// **'View Orders'**
  String get view_Orders;

  /// UI string (source key: Pending)
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// UI string (source key: Completed)
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// UI string (source key: Expired)
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// UI string (source key: Your Bookings)
  ///
  /// In en, this message translates to:
  /// **'Your Bookings'**
  String get your_Bookings;

  /// UI string (source key: Order #2847)
  ///
  /// In en, this message translates to:
  /// **'Order #2847'**
  String get order_2847;

  /// UI string (source key: Paris, France)
  ///
  /// In en, this message translates to:
  /// **'Paris, France'**
  String get paris_France;

  /// UI string (source key: Sept 15, 2024)
  ///
  /// In en, this message translates to:
  /// **'Sept 15, 2024'**
  String get sept_15_2024;

  /// UI string (source key: Order #2831)
  ///
  /// In en, this message translates to:
  /// **'Order #2831'**
  String get order_2831;

  /// UI string (source key: Rome, Italy)
  ///
  /// In en, this message translates to:
  /// **'Rome, Italy'**
  String get rome_Italy;

  /// UI string (source key: Sept 12, 2024)
  ///
  /// In en, this message translates to:
  /// **'Sept 12, 2024'**
  String get sept_12_2024;

  /// UI string (source key: Order #2819)
  ///
  /// In en, this message translates to:
  /// **'Order #2819'**
  String get order_2819;

  /// UI string (source key: London, UK)
  ///
  /// In en, this message translates to:
  /// **'London, UK'**
  String get london_UK;

  /// UI string (source key: Sept 8, 2024)
  ///
  /// In en, this message translates to:
  /// **'Sept 8, 2024'**
  String get sept_8_2024;

  /// UI string (source key: New York City)
  ///
  /// In en, this message translates to:
  /// **'New York City'**
  String get new_York_City;

  /// UI string (source key: In Progress)
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get in_Progress;

  /// UI string (source key: Check-in)
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get check_in;

  /// UI string (source key: Sep 12, 2024)
  ///
  /// In en, this message translates to:
  /// **'Sep 12, 2024'**
  String get sep_12_2024;

  /// UI string (source key: Check-out)
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get check_out;

  /// UI string (source key: Sep 15, 2024)
  ///
  /// In en, this message translates to:
  /// **'Sep 15, 2024'**
  String get sep_15_2024;

  /// UI string (source key: $840.00)
  ///
  /// In en, this message translates to:
  /// **'\$840.00'**
  String get n840_00;

  /// UI string (source key: Search by name or booking ID...)
  ///
  /// In en, this message translates to:
  /// **'Search by name or booking ID...'**
  String get search_by_name_or_booking_ID;

  /// UI string (source key: Date Range)
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get date_Range;

  /// UI string (source key: City)
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// UI string (source key: Sort by)
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sort_by;

  /// UI string (source key: Apply Filters)
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get apply_Filters;

  /// UI string (source key: Booking Status)
  ///
  /// In en, this message translates to:
  /// **'Booking Status'**
  String get booking_Status;

  /// UI string (source key: You don't have any bookings in this category yet. Start exploring and book your next experience!)
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any bookings in this category yet. Start exploring and book your next experience!'**
  String
      get you_don_t_have_any_bookings_in_this_category_yet_Start_exploring_and_book_your_n;

  /// UI string (source key: Browse Services)
  ///
  /// In en, this message translates to:
  /// **'Browse Services'**
  String get browse_Services;

  /// UI string (source key: Support Tickets)
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get support_Tickets;

  /// UI string (source key: Create New Support Ticket)
  ///
  /// In en, this message translates to:
  /// **'Create New Support Ticket'**
  String get create_New_Support_Ticket;

  /// UI string (source key: Contact us directly)
  ///
  /// In en, this message translates to:
  /// **'Contact us directly'**
  String get contact_us_directly;

  /// UI string (source key: Would you like to contact our support team directly via WhatsApp for faster assistance?)
  ///
  /// In en, this message translates to:
  /// **'Would you like to contact our support team directly via WhatsApp for faster assistance?'**
  String
      get would_you_like_to_contact_our_support_team_directly_via_WhatsApp_for_faster_assi;

  /// UI string (source key: WhatsApp)
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// UI string (source key: New Support Ticket)
  ///
  /// In en, this message translates to:
  /// **'New Support Ticket'**
  String get new_Support_Ticket;

  /// UI string (source key: Brief description of your issue)
  ///
  /// In en, this message translates to:
  /// **'Brief description of your issue'**
  String get brief_description_of_your_issue;

  /// UI string (source key: Category)
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// UI string (source key: Select a category)
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get select_a_category;

  /// UI string (source key: Search categories...)
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get search_categories;

  /// UI string (source key: Inquiry)
  ///
  /// In en, this message translates to:
  /// **'Inquiry'**
  String get inquiry;

  /// UI string (source key: Suggestion)
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// UI string (source key: Complaint)
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get complaint;

  /// UI string (source key: Booking Issue)
  ///
  /// In en, this message translates to:
  /// **'Booking Issue'**
  String get booking_Issue;

  /// UI string (source key: Other)
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// UI string (source key: Message)
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// UI string (source key: Please provide detailed information about your issue...)
  ///
  /// In en, this message translates to:
  /// **'Please provide detailed information about your issue...'**
  String get please_provide_detailed_information_about_your_issue;

  /// UI string (source key: Support ticket information)
  ///
  /// In en, this message translates to:
  /// **'Support ticket information'**
  String get support_ticket_information;

  /// UI string (source key: Our support team typically responds within 24-48 hours. For urgent matters, please contact us directly by phone.)
  ///
  /// In en, this message translates to:
  /// **'Our support team typically responds within 24-48 hours. For urgent matters, please contact us directly by phone.'**
  String
      get our_support_team_typically_responds_within_24_48_hours_For_urgent_matters_please;

  /// UI string (source key: Create New Ticket)
  ///
  /// In en, this message translates to:
  /// **'Create New Ticket'**
  String get create_New_Ticket;

  /// UI string (source key: Back)
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// UI string (source key: Forgot Password)
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgot_Password2;

  /// UI string (source key: We will send you an email with a link to reset your password, please enter the email associated with your account below.)
  ///
  /// In en, this message translates to:
  /// **'We will send you an email with a link to reset your password, please enter the email associated with your account below.'**
  String
      get we_will_send_you_an_email_with_a_link_to_reset_your_password_please_enter_the_em;

  /// UI string (source key: Your email address...)
  ///
  /// In en, this message translates to:
  /// **'Your email address...'**
  String get your_email_address;

  /// UI string (source key: Send Link)
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get send_Link;

  /// UI string (source key: BMW 5 Series)
  ///
  /// In en, this message translates to:
  /// **'BMW 5 Series'**
  String get bMW_5_Series;

  /// UI string (source key: Min: 4 hours)
  ///
  /// In en, this message translates to:
  /// **'Min: 4 hours'**
  String get min_4_hours;

  /// UI string (source key: $35/hour)
  ///
  /// In en, this message translates to:
  /// **'\$35/hour'**
  String get n35_hour;

  /// UI string (source key: Honda CR-V)
  ///
  /// In en, this message translates to:
  /// **'Honda CR-V'**
  String get honda_CR_V;

  /// UI string (source key: Min: 2 hours)
  ///
  /// In en, this message translates to:
  /// **'Min: 2 hours'**
  String get min_2_hours;

  /// UI string (source key: $25/hour)
  ///
  /// In en, this message translates to:
  /// **'\$25/hour'**
  String get n25_hour;

  /// UI string (source key: Tesla Model 3)
  ///
  /// In en, this message translates to:
  /// **'Tesla Model 3'**
  String get tesla_Model_3;

  /// UI string (source key: Min: 5 hours)
  ///
  /// In en, this message translates to:
  /// **'Min: 5 hours'**
  String get min_5_hours;

  /// UI string (source key: $40/hour)
  ///
  /// In en, this message translates to:
  /// **'\$40/hour'**
  String get n40_hour;

  /// UI string (source key: Ford Mustang)
  ///
  /// In en, this message translates to:
  /// **'Ford Mustang'**
  String get ford_Mustang;

  /// UI string (source key: Min: 6 hours)
  ///
  /// In en, this message translates to:
  /// **'Min: 6 hours'**
  String get min_6_hours;

  /// UI string (source key: $45/hour)
  ///
  /// In en, this message translates to:
  /// **'\$45/hour'**
  String get n45_hour;

  /// UI string (source key: List of cars)
  ///
  /// In en, this message translates to:
  /// **'List of cars'**
  String get list_of_cars;

  /// UI string (source key: Button)
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get button;

  /// UI string (source key: Edit the address.)
  ///
  /// In en, this message translates to:
  /// **'Edit the address.'**
  String get edit_the_address;

  /// UI string (source key: Update)
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// UI string (source key: Maryam Kutob)
  ///
  /// In en, this message translates to:
  /// **'Maryam Kutob'**
  String get maryam_Kutob;

  /// UI string (source key: kutob.m1413@gmail.com)
  ///
  /// In en, this message translates to:
  /// **'kutob.m1413@gmail.com'**
  String get kutob_m1413_gmail_com;

  /// UI string (source key: HGSHUM)
  ///
  /// In en, this message translates to:
  /// **'HGSHUM'**
  String get hGSHUM;

  /// UI string (source key: Gregory Smith)
  ///
  /// In en, this message translates to:
  /// **'Gregory Smith'**
  String get gregory_Smith;

  /// UI string (source key: 652 - UKW)
  ///
  /// In en, this message translates to:
  /// **'652 - UKW'**
  String get n652_UKW;

  /// UI string (source key: How is your trip?)
  ///
  /// In en, this message translates to:
  /// **'How is your trip?'**
  String get how_is_your_trip;

  /// UI string (source key: Your feedback will help improve driving experience)
  ///
  /// In en, this message translates to:
  /// **'Your feedback will help improve driving experience'**
  String get your_feedback_will_help_improve_driving_experience;

  /// UI string (source key: Additional comments...)
  ///
  /// In en, this message translates to:
  /// **'Additional comments...'**
  String get additional_comments;

  /// UI string (source key: Submit Review)
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submit_Review;

  /// UI string (source key: Rating)
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// UI string (source key: Wow! A 5 star !
  /// Wanna add tip for Gregory?)
  ///
  /// In en, this message translates to:
  /// **'Wow! A 5 star !\nWanna add tip for Gregory?'**
  String get wow_A_5_star_Wanna_add_tip_for_Gregory;

  /// UI string (source key: Choose other amount)
  ///
  /// In en, this message translates to:
  /// **'Choose other amount'**
  String get choose_other_amount;

  /// UI string (source key: Done)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// UI string (source key: Maybe next time)
  ///
  /// In en, this message translates to:
  /// **'Maybe next time'**
  String get maybe_next_time;

  /// UI string (source key: Tips)
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// UI string (source key: Choose the type of entity you represent)
  ///
  /// In en, this message translates to:
  /// **'Choose the type of entity you represent'**
  String get choose_the_type_of_entity_you_represent;

  /// UI string (source key: Government Entity)
  ///
  /// In en, this message translates to:
  /// **'Government Entity'**
  String get government_Entity;

  /// UI string (source key: Company or Organization)
  ///
  /// In en, this message translates to:
  /// **'Company or Organization'**
  String get company_or_Organization;

  /// UI string (source key: Individual)
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// UI string (source key: Next)
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// UI string (source key: Register a Success Partner - Step 1 of 3 )
  ///
  /// In en, this message translates to:
  /// **'Register a Success Partner - Step 1 of 3 '**
  String get register_a_Success_Partner_Step_1_of_3;

  /// UI string (source key: Company Information)
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get company_Information;

  /// UI string (source key: Enter company name *)
  ///
  /// In en, this message translates to:
  /// **'Enter company name *'**
  String get enter_company_name;

  /// UI string (source key: Enter phone number *)
  ///
  /// In en, this message translates to:
  /// **'Enter phone number *'**
  String get enter_phone_number;

  /// UI string (source key: Set Location *)
  ///
  /// In en, this message translates to:
  /// **'Set Location *'**
  String get set_Location;

  /// UI string (source key: Enter business description *)
  ///
  /// In en, this message translates to:
  /// **'Enter business description *'**
  String get enter_business_description;

  /// UI string (source key: Documents)
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// UI string (source key: Upload Place Image *)
  ///
  /// In en, this message translates to:
  /// **'Upload Place Image *'**
  String get upload_Place_Image;

  /// UI string (source key: Tap to select image)
  ///
  /// In en, this message translates to:
  /// **'Tap to select image'**
  String get tap_to_select_image;

  /// UI string (source key: Attach License Document *)
  ///
  /// In en, this message translates to:
  /// **'Attach License Document *'**
  String get attach_License_Document;

  /// UI string (source key: The file has been successfully uploaded.)
  ///
  /// In en, this message translates to:
  /// **'The file has been successfully uploaded.'**
  String get the_file_has_been_successfully_uploaded;

  /// UI string (source key: Attach Registration Letter *)
  ///
  /// In en, this message translates to:
  /// **'Attach Registration Letter *'**
  String get attach_Registration_Letter;

  /// UI string (source key: Service Details)
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get service_Details;

  /// UI string (source key: Describe your provided services *)
  ///
  /// In en, this message translates to:
  /// **'Describe your provided services *'**
  String get describe_your_provided_services;

  /// UI string (source key: Cancel Order)
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancel_Order;

  /// UI string (source key: Company Information -  Step 3 of 3)
  ///
  /// In en, this message translates to:
  /// **'Company Information -  Step 3 of 3'**
  String get company_Information_Step_3_of_3;

  /// UI string (source key: Step 2 of 3)
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3'**
  String get step_2_of_3;

  /// UI string (source key: Create an account)
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get create_an_account;

  /// UI string (source key: Let's get started by filling out the form below.)
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started by filling out the form below.'**
  String get let_s_get_started_by_filling_out_the_form_below;

  /// UI string (source key: Next )
  ///
  /// In en, this message translates to:
  /// **'Next '**
  String get next2;

  /// UI string (source key: Initiate )
  ///
  /// In en, this message translates to:
  /// **'Initiate '**
  String get initiate;

  /// UI string (source key: What kind of tour would you like to explore today?)
  ///
  /// In en, this message translates to:
  /// **'What kind of tour would you like to explore today?'**
  String get what_kind_of_tour_would_you_like_to_explore_today;

  /// UI string (source key: Select My Own Tour Route)
  ///
  /// In en, this message translates to:
  /// **'Select My Own Tour Route'**
  String get select_My_Own_Tour_Route;

  /// UI string (source key: Get Help from the Driver Guide)
  ///
  /// In en, this message translates to:
  /// **'Get Help from the Driver Guide'**
  String get get_Help_from_the_Driver_Guide;

  /// UI string (source key: Current Address)
  ///
  /// In en, this message translates to:
  /// **'Current Address'**
  String get current_Address;

  /// UI string (source key: Current Country)
  ///
  /// In en, this message translates to:
  /// **'Current Country'**
  String get current_Country;

  /// UI string (source key: Current City)
  ///
  /// In en, this message translates to:
  /// **'Current City'**
  String get current_City;

  /// UI string (source key: Initiate)
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get initiate2;

  /// UI string (source key: Trip Assistance Selected)
  ///
  /// In en, this message translates to:
  /// **'Trip Assistance Selected'**
  String get trip_Assistance_Selected;

  /// UI string (source key: Personalized Route)
  ///
  /// In en, this message translates to:
  /// **'Personalized Route'**
  String get personalized_Route;

  /// UI string (source key: Top local attractions curated just for you)
  ///
  /// In en, this message translates to:
  /// **'Top local attractions curated just for you'**
  String get top_local_attractions_curated_just_for_you;

  /// UI string (source key: Historical Sites)
  ///
  /// In en, this message translates to:
  /// **'Historical Sites'**
  String get historical_Sites;

  /// UI string (source key: Local Markets)
  ///
  /// In en, this message translates to:
  /// **'Local Markets'**
  String get local_Markets;

  /// UI string (source key: Scenic Views)
  ///
  /// In en, this message translates to:
  /// **'Scenic Views'**
  String get scenic_Views;

  /// UI string (source key: Cultural Centers)
  ///
  /// In en, this message translates to:
  /// **'Cultural Centers'**
  String get cultural_Centers;

  /// UI string (source key: Contact Your Guide)
  ///
  /// In en, this message translates to:
  /// **'Contact Your Guide'**
  String get contact_Your_Guide;

  /// UI string (source key: View Trip Details)
  ///
  /// In en, this message translates to:
  /// **'View Trip Details'**
  String get view_Trip_Details;

  /// UI string (source key: Suggest a New Place!)
  ///
  /// In en, this message translates to:
  /// **'Suggest a New Place!'**
  String get suggest_a_New_Place;

  /// UI string (source key: Help Us Enrich the Experience)
  ///
  /// In en, this message translates to:
  /// **'Help Us Enrich the Experience'**
  String get help_Us_Enrich_the_Experience;

  /// UI string (source key: Do you know a hidden gem or a must-visit spot that's not listed in our app? We'd love to hear from you!)
  ///
  /// In en, this message translates to:
  /// **'Do you know a hidden gem or a must-visit spot that\'s not listed in our app? We\'d love to hear from you!'**
  String
      get do_you_know_a_hidden_gem_or_a_must_visit_spot_that_s_not_listed_in_our_app_We_d_;

  /// UI string (source key: Your suggestions help others discover more amazing places!)
  ///
  /// In en, this message translates to:
  /// **'Your suggestions help others discover more amazing places!'**
  String get your_suggestions_help_others_discover_more_amazing_places;

  /// UI string (source key: Share your favorite place with the community:)
  ///
  /// In en, this message translates to:
  /// **'Share your favorite place with the community:'**
  String get share_your_favorite_place_with_the_community;

  /// UI string (source key: Place Name)
  ///
  /// In en, this message translates to:
  /// **'Place Name'**
  String get place_Name;

  /// UI string (source key: Enter the name of the place)
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the place'**
  String get enter_the_name_of_the_place;

  /// UI string (source key: Tell us what makes it special)
  ///
  /// In en, this message translates to:
  /// **'Tell us what makes it special'**
  String get tell_us_what_makes_it_special;

  /// UI string (source key: Describe what makes this place unique and worth visiting...)
  ///
  /// In en, this message translates to:
  /// **'Describe what makes this place unique and worth visiting...'**
  String get describe_what_makes_this_place_unique_and_worth_visiting;

  /// UI string (source key: Upload  Photos)
  ///
  /// In en, this message translates to:
  /// **'Upload  Photos'**
  String get upload_Photos;

  /// UI string (source key: Tap to upload photos)
  ///
  /// In en, this message translates to:
  /// **'Tap to upload photos'**
  String get tap_to_upload_photos;

  /// UI string (source key: Image uploaded successfully. ✅)
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully. ✅'**
  String get image_uploaded_successfully;

  /// UI string (source key: Maximum 3 photos)
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 photos'**
  String get maximum_3_photos;

  /// UI string (source key: Mark the Location on the Map)
  ///
  /// In en, this message translates to:
  /// **'Mark the Location on the Map'**
  String get mark_the_Location_on_the_Map;

  /// UI string (source key: Tap to select location on map)
  ///
  /// In en, this message translates to:
  /// **'Tap to select location on map'**
  String get tap_to_select_location_on_map;

  /// UI string (source key: Location has been set✅)
  ///
  /// In en, this message translates to:
  /// **'Location has been set✅'**
  String get location_has_been_set;

  /// UI string (source key:  Submit)
  ///
  /// In en, this message translates to:
  /// **' Submit'**
  String get submit;

  /// UI string (source key: Ahmed Al-Qahtani)
  ///
  /// In en, this message translates to:
  /// **'Ahmed Al-Qahtani'**
  String get ahmed_Al_Qahtani;

  /// UI string (source key: Delivery Agent)
  ///
  /// In en, this message translates to:
  /// **'Delivery Agent'**
  String get delivery_Agent;

  /// UI string (source key: +966 50 123 4567)
  ///
  /// In en, this message translates to:
  /// **'+966 50 123 4567'**
  String get n966_50_123_4567;

  /// UI string (source key: Chat Messages)
  ///
  /// In en, this message translates to:
  /// **'Chat Messages'**
  String get chat_Messages;

  /// UI string (source key: Vehicle Plate)
  ///
  /// In en, this message translates to:
  /// **'Vehicle Plate'**
  String get vehicle_Plate;

  /// UI string (source key: KSA | 1234 ABC)
  ///
  /// In en, this message translates to:
  /// **'KSA | 1234 ABC'**
  String get kSA_1234_ABC;

  /// UI string (source key: VERIFIED)
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get vERIFIED;

  /// UI string (source key: Live Location Tracking)
  ///
  /// In en, this message translates to:
  /// **'Live Location Tracking'**
  String get live_Location_Tracking;

  /// UI string (source key: Real-time tracking active)
  ///
  /// In en, this message translates to:
  /// **'Real-time tracking active'**
  String get real_time_tracking_active;

  /// UI string (source key: Track Location)
  ///
  /// In en, this message translates to:
  /// **'Track Location'**
  String get track_Location;

  /// UI string (source key: Call Now)
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get call_Now;

  /// UI string (source key: Type your message...)
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get type_your_message;

  /// UI string (source key: Pay the reservation fee)
  ///
  /// In en, this message translates to:
  /// **'Pay the reservation fee'**
  String get pay_the_reservation_fee;

  /// UI string (source key: Where would you like to start your ride?)
  ///
  /// In en, this message translates to:
  /// **'Where would you like to start your ride?'**
  String get where_would_you_like_to_start_your_ride;

  /// UI string (source key: United States)
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get united_States;

  /// UI string (source key: San Francisco)
  ///
  /// In en, this message translates to:
  /// **'San Francisco'**
  String get san_Francisco;

  /// UI string (source key: 1234 Market Street, Downtown)
  ///
  /// In en, this message translates to:
  /// **'1234 Market Street, Downtown'**
  String get n1234_Market_Street_Downtown;

  /// UI string (source key: Map showing your current location)
  ///
  /// In en, this message translates to:
  /// **'Map showing your current location'**
  String get map_showing_your_current_location;

  /// UI string (source key: Design My Route)
  ///
  /// In en, this message translates to:
  /// **'Design My Route'**
  String get design_My_Route;

  /// UI string (source key: Add landmarks to customize your journey)
  ///
  /// In en, this message translates to:
  /// **'Add landmarks to customize your journey'**
  String get add_landmarks_to_customize_your_journey;

  /// UI string (source key: Let the Driver Decide)
  ///
  /// In en, this message translates to:
  /// **'Let the Driver Decide'**
  String get let_the_Driver_Decide;

  /// UI string (source key: Rely on the driver's local expertise)
  ///
  /// In en, this message translates to:
  /// **'Rely on the driver\'s local expertise'**
  String get rely_on_the_driver_s_local_expertise;

  /// UI string (source key: Choose Your Location)
  ///
  /// In en, this message translates to:
  /// **'Choose Your Location'**
  String get choose_Your_Location;

  /// UI string (source key: Cardholder Name)
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholder_Name;

  /// UI string (source key: Enter cardholder name)
  ///
  /// In en, this message translates to:
  /// **'Enter cardholder name'**
  String get enter_cardholder_name;

  /// UI string (source key: Card Number)
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get card_Number;

  /// UI string (source key: Expiry Month)
  ///
  /// In en, this message translates to:
  /// **'Expiry Month'**
  String get expiry_Month;

  /// UI string (source key: MM)
  ///
  /// In en, this message translates to:
  /// **'MM'**
  String get mM;

  /// UI string (source key: Expiry Year)
  ///
  /// In en, this message translates to:
  /// **'Expiry Year'**
  String get expiry_Year;

  /// UI string (source key: YY)
  ///
  /// In en, this message translates to:
  /// **'YY'**
  String get yY;

  /// UI string (source key: Save this card for future payments)
  ///
  /// In en, this message translates to:
  /// **'Save this card for future payments'**
  String get save_this_card_for_future_payments;

  /// UI string (source key: Save Card)
  ///
  /// In en, this message translates to:
  /// **'Save Card'**
  String get save_Card;

  /// UI string (source key: Close Page)
  ///
  /// In en, this message translates to:
  /// **'Close Page'**
  String get close_Page;

  /// UI string (source key: Please do not close the page until the payment is completed)
  ///
  /// In en, this message translates to:
  /// **'Please do not close the page until the payment is completed'**
  String get please_do_not_close_the_page_until_the_payment_is_completed;

  /// UI string (source key: Payment Confirmed!)
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed!'**
  String get payment_Confirmed;

  /// UI string (source key: "Your request has been sent successfully, and a driver will accept your request within the next few minutes)
  ///
  /// In en, this message translates to:
  /// **'\"Your request has been sent successfully, and a driver will accept your request within the next few minutes'**
  String
      get your_request_has_been_sent_successfully_and_a_driver_will_accept_your_request_wi;

  /// UI string (source key: Go to Order)
  ///
  /// In en, this message translates to:
  /// **'Go to Order'**
  String get go_to_Order;

  /// UI string (source key: The last payment was not completed, please try again)
  ///
  /// In en, this message translates to:
  /// **'The last payment was not completed, please try again'**
  String get the_last_payment_was_not_completed_please_try_again;

  /// UI string (source key: Payment History)
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get payment_History;

  /// UI string (source key: TXN ID:)
  ///
  /// In en, this message translates to:
  /// **'TXN ID:'**
  String get tXN_ID;

  /// UI string (source key: معرف العملية)
  ///
  /// In en, this message translates to:
  /// **'معرف العملية'**
  String get k3603b6854b;

  /// UI string (source key: Online Payment ID:)
  ///
  /// In en, this message translates to:
  /// **'Online Payment ID:'**
  String get online_Payment_ID;

  /// UI string (source key: Online Payment ID)
  ///
  /// In en, this message translates to:
  /// **'Online Payment ID'**
  String get online_Payment_ID2;

  /// UI string (source key: Salary Deposit)
  ///
  /// In en, this message translates to:
  /// **'Salary Deposit'**
  String get salary_Deposit;

  /// UI string (source key: TXN ID: TXN654321987)
  ///
  /// In en, this message translates to:
  /// **'TXN ID: TXN654321987'**
  String get tXN_ID_TXN654321987;

  /// UI string (source key: Dec 14, 2024 • 9:15 AM)
  ///
  /// In en, this message translates to:
  /// **'Dec 14, 2024 • 9:15 AM'**
  String get dec_14_2024_9_15_AM;

  /// UI string (source key: +$3,250.00)
  ///
  /// In en, this message translates to:
  /// **'+\$3,250.00'**
  String get n3_250_00;

  /// UI string (source key: Electronic Payment ID)
  ///
  /// In en, this message translates to:
  /// **'Electronic Payment ID'**
  String get electronic_Payment_ID;

  /// UI string (source key: EPY-2024-654321)
  ///
  /// In en, this message translates to:
  /// **'EPY-2024-654321'**
  String get ePY_2024_654321;

  /// UI string (source key: Utility Bill Payment)
  ///
  /// In en, this message translates to:
  /// **'Utility Bill Payment'**
  String get utility_Bill_Payment;

  /// UI string (source key: TXN ID: TXN456789012)
  ///
  /// In en, this message translates to:
  /// **'TXN ID: TXN456789012'**
  String get tXN_ID_TXN456789012;

  /// UI string (source key: Dec 13, 2024 • 4:22 PM)
  ///
  /// In en, this message translates to:
  /// **'Dec 13, 2024 • 4:22 PM'**
  String get dec_13_2024_4_22_PM;

  /// UI string (source key: -$156.78)
  ///
  /// In en, this message translates to:
  /// **'-\$156.78'**
  String get n156_78;

  /// UI string (source key: EPY-2024-456789)
  ///
  /// In en, this message translates to:
  /// **'EPY-2024-456789'**
  String get ePY_2024_456789;

  /// UI string (source key: Restaurant Payment)
  ///
  /// In en, this message translates to:
  /// **'Restaurant Payment'**
  String get restaurant_Payment;

  /// UI string (source key: TXN ID: TXN321654987)
  ///
  /// In en, this message translates to:
  /// **'TXN ID: TXN321654987'**
  String get tXN_ID_TXN321654987;

  /// UI string (source key: Dec 12, 2024 • 7:45 PM)
  ///
  /// In en, this message translates to:
  /// **'Dec 12, 2024 • 7:45 PM'**
  String get dec_12_2024_7_45_PM;

  /// UI string (source key: -$42.50)
  ///
  /// In en, this message translates to:
  /// **'-\$42.50'**
  String get n42_50;

  /// UI string (source key: EPY-2024-321654)
  ///
  /// In en, this message translates to:
  /// **'EPY-2024-321654'**
  String get ePY_2024_321654;

  /// UI string (source key: Investment Transfer)
  ///
  /// In en, this message translates to:
  /// **'Investment Transfer'**
  String get investment_Transfer;

  /// UI string (source key: TXN ID: TXN987123456)
  ///
  /// In en, this message translates to:
  /// **'TXN ID: TXN987123456'**
  String get tXN_ID_TXN987123456;

  /// UI string (source key: Dec 11, 2024 • 11:30 AM)
  ///
  /// In en, this message translates to:
  /// **'Dec 11, 2024 • 11:30 AM'**
  String get dec_11_2024_11_30_AM;

  /// UI string (source key: -$500.00)
  ///
  /// In en, this message translates to:
  /// **'-\$500.00'**
  String get n500_00;

  /// UI string (source key: EPY-2024-987123)
  ///
  /// In en, this message translates to:
  /// **'EPY-2024-987123'**
  String get ePY_2024_987123;

  /// UI string (source key: Refund - Online Store)
  ///
  /// In en, this message translates to:
  /// **'Refund - Online Store'**
  String get refund_Online_Store;

  /// UI string (source key: TXN ID: TXN147258369)
  ///
  /// In en, this message translates to:
  /// **'TXN ID: TXN147258369'**
  String get tXN_ID_TXN147258369;

  /// UI string (source key: Dec 10, 2024 • 3:18 PM)
  ///
  /// In en, this message translates to:
  /// **'Dec 10, 2024 • 3:18 PM'**
  String get dec_10_2024_3_18_PM;

  /// UI string (source key: Start from your current location)
  ///
  /// In en, this message translates to:
  /// **'Start from your current location'**
  String get start_from_your_current_location;

  /// UI string (source key: Change city)
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get change_city;

  /// UI string (source key: View My Trip)
  ///
  /// In en, this message translates to:
  /// **'View My Trip'**
  String get view_My_Trip;

  /// UI string (source key: Experience top destinations)
  ///
  /// In en, this message translates to:
  /// **'Experience top destinations'**
  String get experience_top_destinations;

  /// UI string (source key: Tourist landmarks)
  ///
  /// In en, this message translates to:
  /// **'Tourist landmarks'**
  String get tourist_landmarks;

  /// UI string (source key: Landmarks - معالم سياحية)
  ///
  /// In en, this message translates to:
  /// **'Landmarks - معالم سياحية'**
  String get landmarks;

  /// UI string (source key: Google Map)
  ///
  /// In en, this message translates to:
  /// **'Google Map'**
  String get google_Map;

  /// UI string (source key: Agent Location)
  ///
  /// In en, this message translates to:
  /// **'Agent Location'**
  String get agent_Location;

  /// UI string (source key: the details)
  ///
  /// In en, this message translates to:
  /// **'the details'**
  String get the_details;

  /// UI string (source key: Select Travel Date)
  ///
  /// In en, this message translates to:
  /// **'Select Travel Date'**
  String get select_Travel_Date;

  /// UI string (source key: Choose your preferred departure date)
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred departure date'**
  String get choose_your_preferred_departure_date;

  /// UI string (source key: Selected Date)
  ///
  /// In en, this message translates to:
  /// **'Selected Date'**
  String get selected_Date;

  /// UI string (source key: March 15, 2024)
  ///
  /// In en, this message translates to:
  /// **'March 15, 2024'**
  String get march_15_2024;

  /// UI string (source key: Change Date)
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get change_Date;

  /// UI string (source key: Select Time)
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get select_Time;

  /// UI string (source key: AM/PM)
  ///
  /// In en, this message translates to:
  /// **'AM/PM'**
  String get aM_PM;

  /// UI string (source key: No Addresses Found)
  ///
  /// In en, this message translates to:
  /// **'No Addresses Found'**
  String get no_Addresses_Found;

  /// UI string (source key: You haven't added any addresses yet. Add a title to get started.)
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any addresses yet. Add a title to get started.'**
  String get you_haven_t_added_any_addresses_yet_Add_a_title_to_get_started;

  /// UI string (source key: Payment Methods)
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get payment_Methods;

  /// UI string (source key: Select )
  ///
  /// In en, this message translates to:
  /// **'Select '**
  String get select;

  /// UI string (source key: Save)
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// UI string (source key: Quick Pay Options)
  ///
  /// In en, this message translates to:
  /// **'Quick Pay Options'**
  String get quick_Pay_Options;

  /// UI string (source key: Saved Cards)
  ///
  /// In en, this message translates to:
  /// **'Saved Cards'**
  String get saved_Cards;

  /// UI string (source key: Add New Payment Method)
  ///
  /// In en, this message translates to:
  /// **'Add New Payment Method'**
  String get add_New_Payment_Method;

  /// UI string (source key: Hello World)
  ///
  /// In en, this message translates to:
  /// **'Hello World'**
  String get hello_World;

  /// UI string (source key: No cards have been added!)
  ///
  /// In en, this message translates to:
  /// **'No cards have been added!'**
  String get no_cards_have_been_added;

  /// UI string (source key: Payment Card)
  ///
  /// In en, this message translates to:
  /// **'Payment Card'**
  String get payment_Card;

  /// UI string (source key: Choice)
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get choice;

  /// UI string (source key: •••• •••• •••• 8901)
  ///
  /// In en, this message translates to:
  /// **'•••• •••• •••• 8901'**
  String get n8901;

  /// UI string (source key: Mastercard • Expires 08/25)
  ///
  /// In en, this message translates to:
  /// **'Mastercard • Expires 08/25'**
  String get mastercard_Expires_08_25;

  /// UI string (source key: •••• •••• •••• 2468)
  ///
  /// In en, this message translates to:
  /// **'•••• •••• •••• 2468'**
  String get n2468;

  /// UI string (source key: American Express • Expires 03/27)
  ///
  /// In en, this message translates to:
  /// **'American Express • Expires 03/27'**
  String get american_Express_Expires_03_27;

  /// UI string (source key: Number of Extra Hours)
  ///
  /// In en, this message translates to:
  /// **'Number of Extra Hours'**
  String get number_of_Extra_Hours;

  /// UI string (source key: Payment Method)
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get payment_Method;

  /// UI string (source key: Add Card)
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get add_Card;

  /// UI string (source key: Total Price)
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get total_Price;

  /// UI string (source key: 4:00pm)
  ///
  /// In en, this message translates to:
  /// **'4:00pm'**
  String get n4_00pm;

  /// UI string (source key: 5+ ساعات)
  ///
  /// In en, this message translates to:
  /// **'5+ ساعات'**
  String get n52;

  /// UI string (source key: Extra hours have been added to the trip)
  ///
  /// In en, this message translates to:
  /// **'Extra hours have been added to the trip'**
  String get extra_hours_have_been_added_to_the_trip;

  /// UI string (source key: Order Summary)
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get order_Summary;

  /// UI string (source key: request summary)
  ///
  /// In en, this message translates to:
  /// **'Request Summary'**
  String get request_summary;

  /// UI string (source key: $25.40)
  ///
  /// In en, this message translates to:
  /// **'\$25.40'**
  String get n25_40;

  /// UI string (source key: (4 items))
  ///
  /// In en, this message translates to:
  /// **'(4 items)'**
  String get n4_items;

  /// UI string (source key: Reservations)
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get reservations;

  /// UI string (source key: ux_welcome_login)
  ///
  /// In en, this message translates to:
  /// **'Welcome to Touri Taxi'**
  String get ux_welcome_login;

  /// UI string (source key: ux_welcome_login_sub)
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to start booking your tour easily'**
  String get ux_welcome_login_sub;

  /// UI string (source key: ux_booking_steps)
  ///
  /// In en, this message translates to:
  /// **'Booking steps'**
  String get ux_booking_steps;

  /// UI string (source key: ux_step_trip_type)
  ///
  /// In en, this message translates to:
  /// **'Trip type'**
  String get ux_step_trip_type;

  /// UI string (source key: ux_step_location)
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get ux_step_location;

  /// UI string (source key: ux_step_details)
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ux_step_details;

  /// UI string (source key: ux_step_payment)
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get ux_step_payment;

  /// UI string (source key: ux_choose_trip_type)
  ///
  /// In en, this message translates to:
  /// **'How do you want to explore?'**
  String get ux_choose_trip_type;

  /// UI string (source key: ux_choose_trip_hint)
  ///
  /// In en, this message translates to:
  /// **'Choose one option below, then set your location to continue'**
  String get ux_choose_trip_hint;

  /// UI string (source key: ux_car_list_hint)
  ///
  /// In en, this message translates to:
  /// **'Choose the right car for your trip, then tap Select'**
  String get ux_car_list_hint;

  /// UI string (source key: ux_car_available)
  ///
  /// In en, this message translates to:
  /// **'cars available'**
  String get ux_car_available;

  /// UI string (source key: ux_per_hour)
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get ux_per_hour;

  /// UI string (source key: ux_min_hours)
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get ux_min_hours;

  /// UI string (source key: ux_car_list_empty_title)
  ///
  /// In en, this message translates to:
  /// **'No cars available'**
  String get ux_car_list_empty_title;

  /// UI string (source key: ux_car_list_empty_msg)
  ///
  /// In en, this message translates to:
  /// **'No cars are available right now. Please try again later'**
  String get ux_car_list_empty_msg;

  /// UI string (source key: ux_car_list_error_title)
  ///
  /// In en, this message translates to:
  /// **'Could not load cars'**
  String get ux_car_list_error_title;

  /// UI string (source key: ux_car_list_error_msg)
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get ux_car_list_error_msg;

  /// UI string (source key: ux_retry)
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ux_retry;

  /// UI string (source key: booking_success_title)
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get booking_success_title;

  /// UI string (source key: booking_success_msg)
  ///
  /// In en, this message translates to:
  /// **'Your request was sent successfully. Drivers will be notified and one should accept it soon.'**
  String get booking_success_msg;

  /// UI string (source key: booking_login_required)
  ///
  /// In en, this message translates to:
  /// **'Please sign in before completing your booking'**
  String get booking_login_required;

  /// UI string (source key: booking_save_failed)
  ///
  /// In en, this message translates to:
  /// **'Could not send your request. Check your connection and try again'**
  String get booking_save_failed;

  /// UI string (source key: ux_custom_route_desc)
  ///
  /// In en, this message translates to:
  /// **'You pick places on the map and plan your own route'**
  String get ux_custom_route_desc;

  /// UI string (source key: ux_driver_guide_desc)
  ///
  /// In en, this message translates to:
  /// **'Your driver guides you and suggests the best attractions'**
  String get ux_driver_guide_desc;

  /// UI string (source key: ux_my_bookings_sub)
  ///
  /// In en, this message translates to:
  /// **'Track your current and past bookings here'**
  String get ux_my_bookings_sub;

  /// UI string (source key: ux_no_bookings_title)
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get ux_no_bookings_title;

  /// UI string (source key: ux_no_bookings_msg)
  ///
  /// In en, this message translates to:
  /// **'Start your first trip from the Book Now tab'**
  String get ux_no_bookings_msg;

  /// UI string (source key: ux_account_sub)
  ///
  /// In en, this message translates to:
  /// **'Manage profile, language, and support'**
  String get ux_account_sub;

  /// UI string (source key: ux_account_settings)
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get ux_account_settings;

  /// UI string (source key: ux_new_booking)
  ///
  /// In en, this message translates to:
  /// **'Book a new trip'**
  String get ux_new_booking;

  /// UI string (source key: dialog_ok)
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialog_ok;

  /// UI string (source key: dialog_yes)
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get dialog_yes;

  /// UI string (source key: dialog_no)
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get dialog_no;

  /// UI string (source key: dialog_confirm)
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialog_confirm;

  /// UI string (source key: dialog_cancel)
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialog_cancel;

  /// UI string (source key: dialog_error_title)
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get dialog_error_title;

  /// UI string (source key: dialog_location_error)
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your current location. Please enable location services.'**
  String get dialog_location_error;

  /// UI string (source key: dialog_country_mismatch_title)
  ///
  /// In en, this message translates to:
  /// **'Incorrect country'**
  String get dialog_country_mismatch_title;

  /// UI string (source key: dialog_country_mismatch_msg)
  ///
  /// In en, this message translates to:
  /// **'The displayed country doesn\'t match your current location. Please select the correct country.'**
  String get dialog_country_mismatch_msg;

  /// UI string (source key: dialog_outside_coverage_title)
  ///
  /// In en, this message translates to:
  /// **'Outside service area'**
  String get dialog_outside_coverage_title;

  /// UI string (source key: dialog_outside_coverage_msg)
  ///
  /// In en, this message translates to:
  /// **'Your current country is outside the system\'s service area. Booking is not available from your location.'**
  String get dialog_outside_coverage_msg;

  /// UI string (source key: dialog_change_country_title)
  ///
  /// In en, this message translates to:
  /// **'Change country'**
  String get dialog_change_country_title;

  /// UI string (source key: dialog_change_country_msg)
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the country?'**
  String get dialog_change_country_msg;

  /// UI string (source key: dialog_change_city_title)
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get dialog_change_city_title;

  /// UI string (source key: dialog_change_city_msg)
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the city?'**
  String get dialog_change_city_msg;

  /// UI string (source key: dialog_select_trip_or_location)
  ///
  /// In en, this message translates to:
  /// **'Please select a trip type or location'**
  String get dialog_select_trip_or_location;

  /// UI string (source key: dialog_update_location_title)
  ///
  /// In en, this message translates to:
  /// **'Update location'**
  String get dialog_update_location_title;

  /// UI string (source key: dialog_update_location_msg)
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to update your current location?'**
  String get dialog_update_location_msg;

  /// UI string (source key: dialog_select_all_options)
  ///
  /// In en, this message translates to:
  /// **'Please select all required options'**
  String get dialog_select_all_options;

  /// UI string (source key: dialog_delete_account_title)
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get dialog_delete_account_title;

  /// UI string (source key: dialog_delete_account_msg)
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to request account deletion? Deletion may take 24 hours if there are no pending amounts or balance.'**
  String get dialog_delete_account_msg;

  /// UI string (source key: dialog_request_sent_title)
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get dialog_request_sent_title;

  /// UI string (source key: dialog_request_sent_msg)
  ///
  /// In en, this message translates to:
  /// **'You can track your request status through support tickets'**
  String get dialog_request_sent_msg;

  /// UI string (source key: Take a photo to set your profile picture using the camera directly.)
  ///
  /// In en, this message translates to:
  /// **'Take a photo to set your profile picture using the camera directly.'**
  String get take_a_photo_to_set_your_profile_picture_using_the_camera_directly;

  /// UI string (source key: Upload images to set your account profile picture.
  /// )
  ///
  /// In en, this message translates to:
  /// **'Upload images to set your account profile picture.\n'**
  String get upload_images_to_set_your_account_profile_picture;

  /// UI string (source key: Allow the "Ara Watan" app to access your location for the purpose of delivering you to the specified tourist destinations.)
  ///
  /// In en, this message translates to:
  /// **'Allow the \"Touri Taxi\" app to access your location for the purpose of delivering you to the specified tourist destinations.'**
  String
      get allow_the_Ara_Watan_app_to_access_your_location_for_the_purpose_of_delivering_yo;

  /// UI string (source key: this allows for the exploitation of the nation's resources to access distinctive tourist areas.)
  ///
  /// In en, this message translates to:
  /// **'This allows for the exploitation of the nation\'s resources to access distinctive tourist areas.'**
  String
      get this_allows_for_the_exploitation_of_the_nation_s_resources_to_access_distinctive;

  /// UI string (source key: unexpected_error_title)
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpected_error_title;

  /// UI string (source key: unexpected_error_msg)
  ///
  /// In en, this message translates to:
  /// **'Please restart the app or return to the home screen.'**
  String get unexpected_error_msg;

  /// UI string (source key: dialog_location_required)
  ///
  /// In en, this message translates to:
  /// **'Please set your current location.'**
  String get dialog_location_required;

  /// UI string (source key: custom_place_name_required)
  ///
  /// In en, this message translates to:
  /// **'Enter a place name or pick one from search'**
  String get custom_place_name_required;

  /// UI string (source key: custom_place_duplicate)
  ///
  /// In en, this message translates to:
  /// **'This place is already in your trip'**
  String get custom_place_duplicate;

  /// UI string (source key: instant_booking)
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get instant_booking;

  /// UI string (source key: custom_place_added)
  ///
  /// In en, this message translates to:
  /// **'Added: {name}'**
  String custom_place_added(String name);

  /// UI string (source key: view_my_trip)
  ///
  /// In en, this message translates to:
  /// **'View my trip'**
  String get view_my_trip;

  /// UI string (source key: landmarks_loaded_count)
  ///
  /// In en, this message translates to:
  /// **'Showing {count} landmarks'**
  String landmarks_loaded_count(String count);

  /// UI string (source key: load_more_landmarks)
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get load_more_landmarks;

  /// UI string (source key: load_more_landmarks_count)
  ///
  /// In en, this message translates to:
  /// **'Load more ({loaded} / {total}+)'**
  String load_more_landmarks_count(String loaded, String total);

  /// UI string (source key: add_destination_first)
  ///
  /// In en, this message translates to:
  /// **'Add at least one destination first'**
  String get add_destination_first;

  /// UI string (source key: car_selected_success)
  ///
  /// In en, this message translates to:
  /// **'Car selected successfully'**
  String get car_selected_success;

  /// UI string (source key: generic_error_retry)
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get generic_error_retry;

  /// UI string (source key: custom_place_title)
  ///
  /// In en, this message translates to:
  /// **'Custom place'**
  String get custom_place_title;

  /// UI string (source key: custom_place_map_hint)
  ///
  /// In en, this message translates to:
  /// **'Every place you add counts toward your trip like landmarks (2 stops = 1 hour minimum)'**
  String get custom_place_map_hint;

  /// UI string (source key: custom_place_search_hint)
  ///
  /// In en, this message translates to:
  /// **'Search for a place...'**
  String get custom_place_search_hint;

  /// UI string (source key: custom_place_add_to_trip)
  ///
  /// In en, this message translates to:
  /// **'Add to my trip'**
  String get custom_place_add_to_trip;

  /// UI string (source key: landmarks_custom_banner)
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your place? Add a custom location on the map'**
  String get landmarks_custom_banner;

  /// UI string (source key: ux_pick_location_next_hint)
  ///
  /// In en, this message translates to:
  /// **'Set your location and tap Next to start your tour'**
  String get ux_pick_location_next_hint;

  /// UI string (source key: ux_driver_guide_location_hint)
  ///
  /// In en, this message translates to:
  /// **'Your driver will be your guide — set your location and tap Next'**
  String get ux_driver_guide_location_hint;

  /// UI string (source key: custom_place_move_map_hint)
  ///
  /// In en, this message translates to:
  /// **'Move the map to set the location'**
  String get custom_place_move_map_hint;

  /// UI string (source key: custom_place_name_label)
  ///
  /// In en, this message translates to:
  /// **'Place name (optional)'**
  String get custom_place_name_label;

  /// UI string (source key: custom_place_name_hint)
  ///
  /// In en, this message translates to:
  /// **'e.g. Family café, private beach...'**
  String get custom_place_name_hint;

  /// UI string (source key: my_trip_count)
  ///
  /// In en, this message translates to:
  /// **'My trip ({count})'**
  String my_trip_count(String count);

  /// UI string (source key: landmarks_custom_list_title)
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your place in the list?'**
  String get landmarks_custom_list_title;

  /// UI string (source key: ux_not_available)
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get ux_not_available;

  /// UI string (source key: ux_no_car_selected)
  ///
  /// In en, this message translates to:
  /// **'No car selected'**
  String get ux_no_car_selected;

  /// UI string (source key: ux_preferred_car)
  ///
  /// In en, this message translates to:
  /// **'Preferred car'**
  String get ux_preferred_car;

  /// UI string (source key: ux_meeting_point)
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get ux_meeting_point;

  /// UI string (source key: ux_pick_meeting_point)
  ///
  /// In en, this message translates to:
  /// **'Please select a meeting point'**
  String get ux_pick_meeting_point;

  /// UI string (source key: ux_schedule_optional)
  ///
  /// In en, this message translates to:
  /// **'Optionally, choose a trip start date and time'**
  String get ux_schedule_optional;

  /// UI string (source key: ux_choose_payment_method)
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get ux_choose_payment_method;

  /// UI string (source key: ux_one_hour)
  ///
  /// In en, this message translates to:
  /// **'One hour'**
  String get ux_one_hour;

  /// UI string (source key: ux_two_hours)
  ///
  /// In en, this message translates to:
  /// **'Two hours'**
  String get ux_two_hours;

  /// UI string (source key: ux_hours_count)
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String ux_hours_count(String count);

  /// UI string (source key: ux_car_select_failed)
  ///
  /// In en, this message translates to:
  /// **'Could not select the car. Please try again.'**
  String get ux_car_select_failed;

  /// UI string (source key: app_title)
  ///
  /// In en, this message translates to:
  /// **'Touri Taxi'**
  String get app_title;

  /// UI string (source key: ux_cash_payment)
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get ux_cash_payment;

  /// UI string (source key: ux_change)
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get ux_change;

  /// UI string (source key: ux_card_payment_network)
  ///
  /// In en, this message translates to:
  /// **'Pay by card'**
  String get ux_card_payment_network;

  /// UI string (source key: checkout_extra_hour_discount)
  ///
  /// In en, this message translates to:
  /// **'You get {percent}% off each extra hour you add, up to {max}{currency}'**
  String checkout_extra_hour_discount(
      String percent, String max, String currency);

  /// UI string (source key: checkout_min_hours_hint)
  ///
  /// In en, this message translates to:
  /// **'Based on your selected stops, the minimum trip length is {hours} hours'**
  String checkout_min_hours_hint(String hours, Object horas);

  /// UI string (source key: checkout_payment_card_error)
  ///
  /// In en, this message translates to:
  /// **'Payment or card details are incorrect'**
  String get checkout_payment_card_error;

  /// UI string (source key: checkout_order_status_pending)
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver acceptance'**
  String get checkout_order_status_pending;

  /// UI string (source key: checkout_add_hours_prompt)
  ///
  /// In en, this message translates to:
  /// **'Please add at least {hours} more hour(s) to continue'**
  String checkout_add_hours_prompt(String hours, Object horas);

  /// UI string (source key: checkout_complete_options_prompt)
  ///
  /// In en, this message translates to:
  /// **'Complete all options or add more hours to match your trip'**
  String get checkout_complete_options_prompt;

  /// UI string (source key: landmark_added_success)
  ///
  /// In en, this message translates to:
  /// **'Added: {name}'**
  String landmark_added_success(String name);

  /// UI string (source key: landmark_already_in_cart)
  ///
  /// In en, this message translates to:
  /// **'This place is already in your trip'**
  String get landmark_already_in_cart;

  /// UI string (source key: load_error_title)
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get load_error_title;

  /// UI string (source key: load_error_message)
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get load_error_message;

  /// UI string (source key: change_region)
  ///
  /// In en, this message translates to:
  /// **'Change region'**
  String get change_region2;

  /// UI string (source key: places_in_city)
  ///
  /// In en, this message translates to:
  /// **'Places in {city}'**
  String places_in_city(String city);

  /// UI string (source key: destinations_added_label)
  ///
  /// In en, this message translates to:
  /// **'Added destinations:'**
  String get destinations_added_label;

  /// UI string (source key: custom_place_list_hint)
  ///
  /// In en, this message translates to:
  /// **'Pick on the map or search — it counts toward your trip'**
  String get custom_place_list_hint;

  /// UI string (source key: filter_all)
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_all;

  /// UI string (source key: map_locating)
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get map_locating;

  /// UI string (source key: map_calculating_route)
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get map_calculating_route;

  /// UI string (source key: map_distance_label)
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get map_distance_label;

  /// UI string (source key: map_estimated_time)
  ///
  /// In en, this message translates to:
  /// **'Estimated time'**
  String get map_estimated_time;

  /// UI string (source key: map_stops_count)
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get map_stops_count;

  /// UI string (source key: map_avg_speed)
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get map_avg_speed;

  /// UI string (source key: map_calc_type)
  ///
  /// In en, this message translates to:
  /// **'Calculation type'**
  String get map_calc_type;

  /// UI string (source key: map_calc_accurate)
  ///
  /// In en, this message translates to:
  /// **'Accurate'**
  String get map_calc_accurate;

  /// UI string (source key: map_calc_approximate)
  ///
  /// In en, this message translates to:
  /// **'Approximate'**
  String get map_calc_approximate;

  /// UI string (source key: map_route_fallback)
  ///
  /// In en, this message translates to:
  /// **'Could not calculate the best route; using approximate distance'**
  String get map_route_fallback;

  /// UI string (source key: map_your_location)
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get map_your_location;

  /// UI string (source key: map_destination_n)
  ///
  /// In en, this message translates to:
  /// **'Stop {n}'**
  String map_destination_n(String n);

  /// UI string (source key: map_load_failed)
  ///
  /// In en, this message translates to:
  /// **'The map could not load. Check your connection and map service settings.'**
  String get map_load_failed;

  /// UI string (source key: wallet_title)
  ///
  /// In en, this message translates to:
  /// **'My wallet'**
  String get wallet_title;

  /// UI string (source key: wallet_load_error)
  ///
  /// In en, this message translates to:
  /// **'Could not load wallet'**
  String get wallet_load_error;

  /// UI string (source key: wallet_not_created)
  ///
  /// In en, this message translates to:
  /// **'No wallet yet'**
  String get wallet_not_created;

  /// UI string (source key: wallet_created_success)
  ///
  /// In en, this message translates to:
  /// **'Wallet created successfully'**
  String get wallet_created_success;

  /// UI string (source key: wallet_create_button)
  ///
  /// In en, this message translates to:
  /// **'Create wallet'**
  String get wallet_create_button;

  /// UI string (source key: wallet_current_balance)
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get wallet_current_balance;

  /// UI string (source key: wallet_currency_label)
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get wallet_currency_label;

  /// UI string (source key: wallet_last_updated)
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get wallet_last_updated;

  /// UI string (source key: wallet_never)
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get wallet_never;

  /// UI string (source key: wallet_login_required_title)
  ///
  /// In en, this message translates to:
  /// **'Please sign in'**
  String get wallet_login_required_title;

  /// UI string (source key: wallet_login_required_msg)
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your wallet'**
  String get wallet_login_required_msg;

  /// UI string (source key: wallet_add_balance)
  ///
  /// In en, this message translates to:
  /// **'Add balance'**
  String get wallet_add_balance;

  /// UI string (source key: wallet_withdraw)
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get wallet_withdraw;

  /// UI string (source key: wallet_transactions)
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get wallet_transactions;

  /// UI string (source key: wallet_view_all)
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get wallet_view_all;

  /// UI string (source key: wallet_transactions_error)
  ///
  /// In en, this message translates to:
  /// **'Could not load transactions'**
  String get wallet_transactions_error;

  /// UI string (source key: wallet_tx_deposit)
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get wallet_tx_deposit;

  /// UI string (source key: wallet_tx_withdraw)
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get wallet_tx_withdraw;

  /// UI string (source key: wallet_tx_refund)
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get wallet_tx_refund;

  /// UI string (source key: wallet_tx_transfer)
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get wallet_tx_transfer;

  /// UI string (source key: wallet_status_completed)
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get wallet_status_completed;

  /// UI string (source key: wallet_status_pending)
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get wallet_status_pending;

  /// UI string (source key: wallet_status_failed)
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get wallet_status_failed;

  /// UI string (source key: wallet_status_cancelled)
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get wallet_status_cancelled;

  /// UI string (source key: wallet_no_transactions)
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get wallet_no_transactions;

  /// UI string (source key: wallet_no_transactions_hint)
  ///
  /// In en, this message translates to:
  /// **'Your transactions will appear here'**
  String get wallet_no_transactions_hint;

  /// UI string (source key: wallet_login_first)
  ///
  /// In en, this message translates to:
  /// **'Please sign in first'**
  String get wallet_login_first;

  /// UI string (source key: wallet_add_balance_title)
  ///
  /// In en, this message translates to:
  /// **'Add wallet balance'**
  String get wallet_add_balance_title;

  /// UI string (source key: wallet_amount_label)
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get wallet_amount_label;

  /// UI string (source key: wallet_amount_required)
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get wallet_amount_required;

  /// UI string (source key: wallet_amount_invalid)
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get wallet_amount_invalid;

  /// UI string (source key: wallet_amount_max)
  ///
  /// In en, this message translates to:
  /// **'Maximum deposit is 10,000'**
  String get wallet_amount_max;

  /// UI string (source key: wallet_no_payment_methods)
  ///
  /// In en, this message translates to:
  /// **'No payment methods available'**
  String get wallet_no_payment_methods;

  /// UI string (source key: wallet_add_payment_method)
  ///
  /// In en, this message translates to:
  /// **'Add new payment method'**
  String get wallet_add_payment_method;

  /// UI string (source key: wallet_choose_payment)
  ///
  /// In en, this message translates to:
  /// **'Choose payment method:'**
  String get wallet_choose_payment;

  /// UI string (source key: wallet_card_ending)
  ///
  /// In en, this message translates to:
  /// **'Card ending in ****{last4}'**
  String wallet_card_ending(String last4);

  /// UI string (source key: wallet_add_new_card)
  ///
  /// In en, this message translates to:
  /// **'Add new card'**
  String get wallet_add_new_card;

  /// UI string (source key: wallet_add_confirm)
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get wallet_add_confirm;

  /// UI string (source key: wallet_add_description)
  ///
  /// In en, this message translates to:
  /// **'Add wallet balance'**
  String get wallet_add_description;

  /// UI string (source key: wallet_add_success)
  ///
  /// In en, this message translates to:
  /// **'Added {amount} to your wallet successfully'**
  String wallet_add_success(String amount);

  /// UI string (source key: wallet_error_generic)
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String wallet_error_generic(String error);

  /// UI string (source key: wallet_select_payment)
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get wallet_select_payment;

  /// UI string (source key: wallet_withdraw_title)
  ///
  /// In en, this message translates to:
  /// **'Withdraw balance'**
  String get wallet_withdraw_title;

  /// UI string (source key: wallet_withdraw_request_note)
  ///
  /// In en, this message translates to:
  /// **'Your withdrawal will be reviewed before transfer. The balance is not finally deducted until approval.'**
  String get wallet_withdraw_request_note;

  /// UI string (source key: wallet_withdraw_request_success)
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request for {amount} {currency} was sent for review'**
  String wallet_withdraw_request_success(String amount, String currency);

  /// UI string (source key: wallet_withdraw_request_failed)
  ///
  /// In en, this message translates to:
  /// **'Could not submit the withdrawal request'**
  String get wallet_withdraw_request_failed;

  /// UI string (source key: don't_have_account)
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get don_t_have_account;

  /// UI string (source key: Message...)
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get message2;

  /// UI string (source key: wallet_available_balance)
  ///
  /// In en, this message translates to:
  /// **'Available balance: {amount} {currency}'**
  String wallet_available_balance(String amount, String currency);

  /// UI string (source key: wallet_withdraw_confirm)
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get wallet_withdraw_confirm;

  /// UI string (source key: wallet_withdraw_description)
  ///
  /// In en, this message translates to:
  /// **'Withdraw from wallet'**
  String get wallet_withdraw_description;

  /// UI string (source key: wallet_withdraw_no_card_deposit)
  ///
  /// In en, this message translates to:
  /// **'No card deposit covers this withdrawal amount'**
  String get wallet_withdraw_no_card_deposit;

  /// UI string (source key: wallet_withdraw_refund_failed)
  ///
  /// In en, this message translates to:
  /// **'Payment refund failed'**
  String get wallet_withdraw_refund_failed;

  /// UI string (source key: wallet_card_topup_success)
  ///
  /// In en, this message translates to:
  /// **'Wallet topped up successfully. Return to wallet?'**
  String get wallet_card_topup_success;

  /// UI string (source key: payment_pending_message)
  ///
  /// In en, this message translates to:
  /// **'Payment is still pending. Please wait or try again.'**
  String get payment_pending_message;

  /// UI string (source key: payment_failed_message)
  ///
  /// In en, this message translates to:
  /// **'Payment was not completed. Check your card and try again.'**
  String get payment_failed_message;

  /// UI string (source key: payment_verify_error)
  ///
  /// In en, this message translates to:
  /// **'Payment could not be verified. Please try again.'**
  String get payment_verify_error;

  /// UI string (source key: payment_order_save_error)
  ///
  /// In en, this message translates to:
  /// **'The order could not be saved. Contact support if you were charged.'**
  String get payment_order_save_error;

  /// UI string (source key: wallet_withdraw_success)
  ///
  /// In en, this message translates to:
  /// **'Withdrew {amount} {currency} successfully'**
  String wallet_withdraw_success(String amount, String currency);

  /// UI string (source key: wallet_amount_exceeds_balance)
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds available balance'**
  String get wallet_amount_exceeds_balance;

  /// UI string (source key: wallet_choose_payout)
  ///
  /// In en, this message translates to:
  /// **'Choose the card to receive funds:'**
  String get wallet_choose_payout;

  /// UI string (source key: country_saudi)
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get country_saudi;

  /// UI string (source key: map_driver)
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get map_driver;

  /// UI string (source key: map_pickup)
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get map_pickup;

  /// UI string (source key: map_destination)
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get map_destination;

  /// UI string (source key: map_open_google_maps)
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get map_open_google_maps;

  /// UI string (source key: map_track_driver_title)
  ///
  /// In en, this message translates to:
  /// **'Track driver on the map'**
  String get map_track_driver_title;

  /// UI string (source key: map_waiting_driver_location)
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver\'s location'**
  String get map_waiting_driver_location;

  /// UI string (source key: booking_status_active)
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get booking_status_active;

  /// UI string (source key: booking_view_route)
  ///
  /// In en, this message translates to:
  /// **'View route'**
  String get booking_view_route;

  /// UI string (source key: map_eta_minutes)
  ///
  /// In en, this message translates to:
  /// **'Arriving in about {minutes} min'**
  String map_eta_minutes(String minutes);

  /// UI string (source key: browsing_now)
  ///
  /// In en, this message translates to:
  /// **'You are browsing {country}'**
  String browsing_now(String country);

  /// UI string (source key: card_confirm_title)
  ///
  /// In en, this message translates to:
  /// **'Confirm card'**
  String get card_confirm_title;

  /// UI string (source key: card_confirm_msg)
  ///
  /// In en, this message translates to:
  /// **'Enter the full card number ending in {last4} and the CVV to continue.'**
  String card_confirm_msg(String last4);

  /// UI string (source key: select_region_title)
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get select_region_title;

  /// UI string (source key: select_region_msg)
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to select or change this city?'**
  String get select_region_msg;

  /// UI string (source key: card_number_label)
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get card_number_label;

  /// UI string (source key: dialog_continue)
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get dialog_continue;

  /// UI string (source key: card_invalid_data)
  ///
  /// In en, this message translates to:
  /// **'Card details are invalid'**
  String get card_invalid_data;

  /// UI string (source key: checkout_paying)
  ///
  /// In en, this message translates to:
  /// **'Processing card payment...'**
  String get checkout_paying;

  /// UI string (source key: map_trip_destination)
  ///
  /// In en, this message translates to:
  /// **'Trip destination'**
  String get map_trip_destination;

  /// UI string (source key: map_invalid_destinations)
  ///
  /// In en, this message translates to:
  /// **'{count} invalid or out-of-area stop(s) were excluded from the route.'**
  String map_invalid_destinations(String count);

  /// UI string (source key: checkout_estimated_time_warning)
  ///
  /// In en, this message translates to:
  /// **'The estimated drive time ({time}) is shorter than the recommended booking duration. Traffic may affect the estimate.'**
  String checkout_estimated_time_warning(String time);

  /// UI string (source key: checkout_vat_rate)
  ///
  /// In en, this message translates to:
  /// **'VAT ({rate}%):'**
  String checkout_vat_rate(String rate);

  /// UI string (source key: map_location_unavailable)
  ///
  /// In en, this message translates to:
  /// **'Your current location is unavailable.'**
  String get map_location_unavailable;

  /// UI string (source key: map_no_valid_destinations)
  ///
  /// In en, this message translates to:
  /// **'No valid stops are available for this route.'**
  String get map_no_valid_destinations;

  /// UI string (source key: unit_km)
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unit_km;

  /// UI string (source key: unit_meter)
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unit_meter;

  /// UI string (source key: unit_minute)
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unit_minute;

  /// UI string (source key: unit_hour)
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get unit_hour;

  /// UI string (source key: unit_kmh)
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unit_kmh;

  /// UI string (source key: duration_hours_minutes)
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String duration_hours_minutes(String hours, String minutes, Object horas);

  /// UI string (source key: location_city_unresolved)
  ///
  /// In en, this message translates to:
  /// **'Your city could not be determined accurately.'**
  String get location_city_unresolved;

  /// UI string (source key: country_map)
  ///
  /// In en, this message translates to:
  /// **'Country map'**
  String get country_map;

  /// UI string (source key: ui_text_44134f762b)
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match!'**
  String get ui_text_44134f762b;

  /// UI string (source key: ui_text_b6f51cadc4)
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get ui_text_b6f51cadc4;

  /// UI string (source key: ui_text_1a4e87f7a9)
  ///
  /// In en, this message translates to:
  /// **'You must agree to the terms and conditions'**
  String get ui_text_1a4e87f7a9;

  /// UI string (source key: ui_text_b0a98216a3)
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ui_text_b0a98216a3;

  /// UI string (source key: ui_text_224b63d8e3)
  ///
  /// In en, this message translates to:
  /// **'Please select a region'**
  String get ui_text_224b63d8e3;

  /// UI string (source key: ui_text_af02762d6d)
  ///
  /// In en, this message translates to:
  /// **'Please select a region'**
  String get ui_text_af02762d6d;

  /// UI string (source key: ui_text_9072549574)
  ///
  /// In en, this message translates to:
  /// **'agree'**
  String get ui_text_9072549574;

  /// UI string (source key: ui_text_17db754851)
  ///
  /// In en, this message translates to:
  /// **'Added: Selected location successfully'**
  String get ui_text_17db754851;

  /// UI string (source key: ui_text_71995f6f4a)
  ///
  /// In en, this message translates to:
  /// **'Location is already added.'**
  String get ui_text_71995f6f4a;

  /// UI string (source key: ui_text_b73e88df71)
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get ui_text_b73e88df71;

  /// UI string (source key: ui_text_b4bbf18b10)
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get ui_text_b4bbf18b10;

  /// UI string (source key: ui_text_cf4d76accb)
  ///
  /// In en, this message translates to:
  /// **'Are you sure to cancel the order?'**
  String get ui_text_cf4d76accb;

  /// UI string (source key: ui_text_5c528d9fa3)
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get ui_text_5c528d9fa3;

  /// UI string (source key: ui_text_d045bef8e5)
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get ui_text_d045bef8e5;

  /// UI string (source key: ui_text_1431f68f35)
  ///
  /// In en, this message translates to:
  /// **'Unset'**
  String get ui_text_1431f68f35;

  /// UI string (source key: ui_text_8bc9b333df)
  ///
  /// In en, this message translates to:
  /// **'Choose Source'**
  String get ui_text_8bc9b333df;

  /// UI string (source key: ui_text_35d76b889c)
  ///
  /// In en, this message translates to:
  /// **'Email required!'**
  String get ui_text_35d76b889c;

  /// UI string (source key: ui_text_f0ad7ac205)
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get ui_text_f0ad7ac205;

  /// UI string (source key: ui_text_12ee72ca4f)
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get ui_text_12ee72ca4f;

  /// UI string (source key: ui_text_d93bf2eb9f)
  ///
  /// In en, this message translates to:
  /// **'Distance and time are estimates and may vary based on traffic, route changes, or location accuracy.'**
  String get ui_text_d93bf2eb9f;

  /// UI string (source key: ui_text_e93e07976e)
  ///
  /// In en, this message translates to:
  /// **'Rating sent'**
  String get ui_text_e93e07976e;

  /// UI string (source key: ui_text_7f2f6a15cf)
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get ui_text_7f2f6a15cf;

  /// UI string (source key: ui_text_9262ef60ec)
  ///
  /// In en, this message translates to:
  /// **'Please check the date and time'**
  String get ui_text_9262ef60ec;

  /// UI string (source key: ui_text_cff8cb30ef)
  ///
  /// In en, this message translates to:
  /// **'Are you sure to cancel the order and get a refund?'**
  String get ui_text_cff8cb30ef;

  /// UI string (source key: ui_text_23ef9d7d03)
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel the order'**
  String get ui_text_23ef9d7d03;

  /// UI string (source key: ui_text_eae6165343)
  ///
  /// In en, this message translates to:
  /// **'The order has been successfully cancelled'**
  String get ui_text_eae6165343;

  /// UI string (source key: ui_text_860c735760)
  ///
  /// In en, this message translates to:
  /// **'You cannot cancel the order because the cancellation time has exceeded. Please contact the support team'**
  String get ui_text_860c735760;

  /// UI string (source key: ui_text_5a9a57155e)
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get ui_text_5a9a57155e;

  /// UI string (source key: ui_text_5eac766a7c)
  ///
  /// In en, this message translates to:
  /// **'Verify that your current location is within the same city, and complete all data accurately.'**
  String get ui_text_5eac766a7c;

  /// UI string (source key: ui_text_1d36255e4a)
  ///
  /// In en, this message translates to:
  /// **'Please complete all data correctly'**
  String get ui_text_1d36255e4a;

  /// UI string (source key: ui_text_def4060285)
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the address?'**
  String get ui_text_def4060285;

  /// UI string (source key: ui_text_85d0e17cdb)
  ///
  /// In en, this message translates to:
  /// **'The address has been successfully deleted'**
  String get ui_text_85d0e17cdb;

  /// UI string (source key: ui_text_471f24ef6b)
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get ui_text_471f24ef6b;

  /// UI string (source key: ui_text_dbee2e6613)
  ///
  /// In en, this message translates to:
  /// **'The request has been sent successfully, and we will review it and contact you shortly.'**
  String get ui_text_dbee2e6613;

  /// UI string (source key: ui_text_095479cd38)
  ///
  /// In en, this message translates to:
  /// **'Dear partner, please fill out all the required fields so that you can submit the application successfully.'**
  String get ui_text_095479cd38;

  /// UI string (source key: rating_driver_title)
  ///
  /// In en, this message translates to:
  /// **'Rate {driver}'**
  String rating_driver_title(String driver);

  /// UI string (source key: rating_driver_question)
  ///
  /// In en, this message translates to:
  /// **'How would you rate {driver}?'**
  String rating_driver_question(String driver);

  /// UI string (source key: order_details_number)
  ///
  /// In en, this message translates to:
  /// **'Order details #{id}'**
  String order_details_number(String id);

  /// UI string (source key: order_time_label)
  ///
  /// In en, this message translates to:
  /// **'Order time: {time}'**
  String order_time_label(String time);

  /// UI string (source key: support_ticket_number)
  ///
  /// In en, this message translates to:
  /// **'Ticket #{id}'**
  String support_ticket_number(String id);

  /// UI string (source key: place_city_only)
  ///
  /// In en, this message translates to:
  /// **'You can only choose a place within {city}, or change the city.'**
  String place_city_only(String city);

  /// UI string (source key: notification_payment_success_title)
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get notification_payment_success_title;

  /// UI string (source key: notification_payment_success_body)
  ///
  /// In en, this message translates to:
  /// **'Payment for booking #{bookingId} was confirmed. We are finding a driver for you.'**
  String notification_payment_success_body(String bookingId);

  /// UI string (source key: notification_paid_order_admin_title)
  ///
  /// In en, this message translates to:
  /// **'New paid booking'**
  String get notification_paid_order_admin_title;

  /// UI string (source key: notification_paid_order_admin_body)
  ///
  /// In en, this message translates to:
  /// **'New paid booking #{bookingId}: {hours} hours, {amount} {currency}.'**
  String notification_paid_order_admin_body(String bookingId, String hours,
      String amount, String currency, Object horas);

  /// UI string (source key: notification_wallet_topup_title)
  ///
  /// In en, this message translates to:
  /// **'Wallet topped up'**
  String get notification_wallet_topup_title;

  /// UI string (source key: notification_wallet_topup_body)
  ///
  /// In en, this message translates to:
  /// **'{amount} SAR was added to your wallet successfully.'**
  String notification_wallet_topup_body(String amount);

  /// UI string (source key: notification_new_order_driver_title)
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get notification_new_order_driver_title;

  /// UI string (source key: notification_new_order_driver_body)
  ///
  /// In en, this message translates to:
  /// **'A new Touri Taxi booking is available for {hours} hours with earnings of {amount} {currency}. Open the driver app to review it.'**
  String notification_new_order_driver_body(
      String hours, String amount, String currency, Object horas);

  /// UI string (source key: notification_private_message_title)
  ///
  /// In en, this message translates to:
  /// **'New private message'**
  String get notification_private_message_title;

  /// UI string (source key: notification_private_message_body)
  ///
  /// In en, this message translates to:
  /// **'You have a new message from {sender}.'**
  String notification_private_message_body(String sender);

  /// UI string (source key: status_pending_driver)
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver acceptance'**
  String get status_pending_driver;

  /// UI string (source key: status_driver_assigned)
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get status_driver_assigned;

  /// UI string (source key: status_driver_arrived)
  ///
  /// In en, this message translates to:
  /// **'Driver arrived'**
  String get status_driver_arrived;

  /// UI string (source key: status_trip_started)
  ///
  /// In en, this message translates to:
  /// **'Trip started'**
  String get status_trip_started;

  /// UI string (source key: status_trip_completed)
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get status_trip_completed;

  /// UI string (source key: status_cancelled)
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get status_cancelled;

  /// UI string (source key: status_payment_pending)
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get status_payment_pending;

  /// UI string (source key: status_paid)
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get status_paid;

  /// UI string (source key: status_payment_failed)
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get status_payment_failed;

  /// UI string (source key: looking_for_destination)
  ///
  /// In en, this message translates to:
  /// **'Looking for a destination...'**
  String get looking_for_destination;

  /// UI string (source key: map_selected_location)
  ///
  /// In en, this message translates to:
  /// **'Selected location on map'**
  String get map_selected_location;

  /// UI string (source key: current_location_label)
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get current_location_label;

  /// UI string (source key: pickup_location_label)
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickup_location_label;

  /// UI string (source key: destination_label)
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination_label;

  /// UI string (source key: stops_label)
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get stops_label;

  /// UI string (source key: view_route_label)
  ///
  /// In en, this message translates to:
  /// **'View route'**
  String get view_route_label;

  /// UI string (source key: trip_details_label)
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get trip_details_label;

  /// UI string (source key: choose_payment_method)
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get choose_payment_method;

  /// UI string (source key: pay_online_option)
  ///
  /// In en, this message translates to:
  /// **'Pay online'**
  String get pay_online_option;

  /// UI string (source key: pay_cash_option)
  ///
  /// In en, this message translates to:
  /// **'Pay with cash'**
  String get pay_cash_option;

  /// UI string (source key: driver_fee_label)
  ///
  /// In en, this message translates to:
  /// **'Driver fee'**
  String get driver_fee_label;

  /// UI string (source key: app_fee_label)
  ///
  /// In en, this message translates to:
  /// **'App fee'**
  String get app_fee_label;

  /// UI string (source key: vat_label)
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat_label;

  /// UI string (source key: total_amount_label)
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get total_amount_label;

  /// UI string (source key: my_bookings_nav)
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get my_bookings_nav;

  /// UI string (source key: my_account_nav)
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get my_account_nav;

  /// UI string (source key: home_nav)
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_nav;

  /// UI string (source key: error_generic_user)
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get error_generic_user;

  /// UI string (source key: error_network_user)
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get error_network_user;

  /// UI string (source key: error_location_permission)
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get error_location_permission;

  /// UI string (source key: error_route_unavailable)
  ///
  /// In en, this message translates to:
  /// **'Route unavailable'**
  String get error_route_unavailable;

  /// UI string (source key: error_outside_service_area)
  ///
  /// In en, this message translates to:
  /// **'Outside service area'**
  String get error_outside_service_area;

  /// UI string (source key: kyrgyz_char_sample)
  ///
  /// In en, this message translates to:
  /// **'Kyrgyz: ң ө ү Ң Ө Ү'**
  String get kyrgyz_char_sample;

  /// booking_hours
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No booking hours} one{1 booking hour} other{{count} booking hours}}'**
  String booking_hours(num count);

  /// minutes_count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 minutes} one{1 minute} other{{count} minutes}}'**
  String minutes_count(num count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'fr',
        'ky',
        'pt',
        'ru',
        'ur'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ky':
      return AppLocalizationsKy();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
