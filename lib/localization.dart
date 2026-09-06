import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final AppLanguage instance = AppLanguage._();
  String _language = 'English';
  String get language => _language;
  String get localeCode => _language == 'Sinhala' ? 'si' : (_language == 'Tamil' ? 'ta' : 'en');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('app_language') ?? 'English';
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (!{'English', 'Sinhala', 'Tamil'}.contains(language)) return;
    _language = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language);
    notifyListeners();
  }
}

final Map<String, Map<String, String>> translations = {
  'Sinhala': {
    'View':'බලන්න','Settings':'සැකසුම්','Home':'මුල් පිටුව','Wallet':'පසුම්බිය','Sell':'විකුණන්න','Chats':'චැට්','Profile':'පැතිකඩ','Notifications':'දැනුම්දීම්','No notifications yet':'තවම දැනුම්දීම් නැත',
    'Login':'පිවිසෙන්න','Sign Up':'ලියාපදිංචි වන්න','Create account':'ගිණුමක් සාදන්න','Welcome back':'නැවත සාදරයෙන් පිළිගනිමු','Sign up to get started':'ආරම්භ කිරීමට ලියාපදිංචි වන්න','Login to continue':'ඉදිරියට යාමට පිවිසෙන්න',
    'Email':'ඊමේල්','Display Name':'පෙන්වන නම','Enter a display name':'පෙන්වන නමක් ඇතුළත් කරන්න','User':'පරිශීලකයා','From':'වෙතින්','Guest User':'ආගන්තුක පරිශීලකයා','Password':'මුරපදය','New Password':'නව මුරපදය','Confirm New Password':'නව මුරපදය තහවුරු කරන්න','Current Password':'වත්මන් මුරපදය','Forgot Password?':'මුරපදය අමතකද?',
    'Reset Password':'මුරපදය යළි සකසන්න','Send Code':'කේතය යවන්න','Resend Code':'කේතය නැවත යවන්න','Verification Code':'තහවුරු කිරීමේ කේතය','Enter the 6-digit code':'අංක 6ක කේතය ඇතුළත් කරන්න','Verify':'තහවුරු කරන්න',
    'Cancel':'අවලංගු කරන්න','Delete':'මකන්න','Save Changes':'වෙනස්කම් සුරකින්න','Submit':'යවන්න','Confirm':'තහවුරු කරන්න','Next':'ඊළඟ','Skip':'මඟ හරින්න','Get Started':'ආරම්භ කරන්න',
    'Language':'භාෂාව','English':'ඉංග්‍රීසි','Sinhala':'සිංහල','Tamil':'දෙමළ','Account':'ගිණුම','Profile Management':'පැතිකඩ කළමනාකරණය','Change Password / PIN':'මුරපදය / PIN වෙනස් කරන්න',
    'Verified Badge Status':'තහවුරු කළ ලාංඡන තත්ත්වය','My Listings':'මගේ ලැයිස්තුගත කිරීම්','My Purchases':'මගේ මිලදී ගැනීම්','My Sales':'මගේ විකුණුම්','Offers':'යෝජනා','Wishlist':'ප්‍රියතම ලැයිස්තුව',
    'Wallet & Bank Details':'පසුම්බිය සහ බැංකු විස්තර','Referral Code':'යොමු කේතය','Security':'ආරක්ෂාව','Biometric Lock':'ජෛවමිතික අගුල','Blocked Users':'අවහිර කළ පරිශීලකයන්',
    'Order Updates':'ඇණවුම් යාවත්කාලීන','Offers & Bids':'යෝජනා සහ ලංසු','Promotions':'ප්‍රවර්ධන','Privacy & Data':'පෞද්ගලිකත්වය සහ දත්ත','Download My Data':'මගේ දත්ත බාගත කරන්න',
    'Terms & Conditions':'නියම සහ කොන්දේසි','Privacy Policy':'පෞද්ගලිකත්ව ප්‍රතිපත්තිය','Support':'සහාය','Help & FAQ':'උදව් සහ FAQ','Logout':'ඉවත් වන්න','Delete Account':'ගිණුම මකන්න',
    'Not Verified':'තහවුරු කර නැත','Verification Pending':'තහවුරු කිරීම පොරොත්තුවෙන්','Verified Seller':'තහවුරු කළ විකුණුම්කරු','Verification Rejected':'තහවුරු කිරීම ප්‍රතික්ෂේප කර ඇත',
    'Retry':'නැවත උත්සාහ කරන්න','My Wallet':'මගේ පසුම්බිය','Available Balance':'පවතින ශේෂය','Top Up':'මුදල් එක් කරන්න','Withdraw':'මුදල් ලබාගන්න','Transaction History':'ගනුදෙනු ඉතිහාසය','No transactions yet':'තවම ගනුදෙනු නැත',
    'Amount (LKR)':'මුදල (LKR)','Upload Bank Slip':'බැංකු ස්ලිප් එක උඩුගත කරන්න','Request Withdrawal':'මුදල් ලබාගැනීම ඉල්ලන්න','Sell an Account':'ගිණුමක් විකුණන්න','Verification Required':'තහවුරු කිරීම අවශ්‍යයි',
    'Game':'ක්‍රීඩාව','Listing Details':'ලැයිස්තුගත විස්තර','Title':'මාතෘකාව','Description':'විස්තරය','Price (LKR)':'මිල (LKR)','Allow Bidding':'ලංසු තැබීමට ඉඩ දෙන්න','Post Listing':'ලැයිස්තුගත කරන්න',
    'Place a Bid':'ලංසුවක් තබන්න','Make an Offer':'යෝජනාවක් ඉදිරිපත් කරන්න','Buy Now':'දැන් මිලදී ගන්න','Confirm Purchase':'මිලදී ගැනීම තහවුරු කරන්න','Bid History':'ලංසු ඉතිහාසය','No listings yet':'තවම ලැයිස්තුගත කිරීම් නැත',
    'Active':'ක්‍රියාකාරී','Pending':'පොරොත්තුවෙන්','Sold':'විකුණා ඇත','Removed':'ඉවත් කර ඇත','Completed':'සම්පූර්ණයි','Disputed':'විවාදයට ලක්ව ඇත','Refunded':'මුදල් ආපසු ලබා දී ඇත','No purchases yet':'තවම මිලදී ගැනීම් නැත','No sales yet':'තවම විකුණුම් නැත','In Escrow':'Escrow තුළ','Paid Out':'ගෙවා අවසන්',
    'Chat with Admin':'පරිපාලක සමඟ චැට් කරන්න','Admin':'පරිපාලක','Message admin...':'පරිපාලකට පණිවිඩයක්...','Chat':'චැට්','Type a message...':'පණිවිඩයක් ටයිප් කරන්න...',
    'Account Credentials':'ගිණුම් පිවිසුම් විස්තර','Account Email':'ගිණුම් ඊමේල්','Account Password':'ගිණුම් මුරපදය','Recovery Codes':'ප්‍රතිසාධන කේත','Bank Name':'බැංකුවේ නම','Account Holder Name':'ගිණුම් හිමියාගේ නම','Account Number':'ගිණුම් අංකය','Branch':'ශාඛාව','Send Verification Code':'තහවුරු කිරීමේ කේතය යවන්න',
    'Buy & Sell Game Accounts Safely':'ක්‍රීඩා ගිණුම් ආරක්ෂිතව මිලදී ගෙන විකුණන්න','3-Day Escrow Protection':'දින 3ක Escrow ආරක්ෂාව','Encrypted Credentials Vault':'සංකේතනය කළ පිවිසුම් Vault','Verified Sellers':'තහවුරු කළ විකුණුම්කරුවන්',
    'Received':'ලැබුණු','Sent':'යවන ලද','Accept':'පිළිගන්න','Reject':'ප්‍රතික්ෂේප කරන්න','Accepted':'පිළිගෙන ඇත','Rejected':'ප්‍රතික්ෂේප කර ඇත','Expired':'කල් ඉකුත් වී ඇත','Referral Bonus':'යොමු ප්‍රසාද දීමනාව','Copied to clipboard':'Clipboard වෙත පිටපත් කළා','Request Change':'වෙනස් කිරීමක් ඉල්ලන්න',
    'App Version':'යෙදුම් අනුවාදය','Report a Problem / Contact Admin':'ගැටලුවක් වාර්තා කරන්න / පරිපාලක අමතන්න','Privacy & Data Deletion Request':'පෞද්ගලික දත්ත මකා දැමීමේ ඉල්ලීම','My Listings':'මගේ ලැයිස්තුගත කිරීම්',
    'No messages yet. Ask admin any questions here.': 'තවම පණිවිඩ නැත. ඕනෑම ප්\u200dරශ්නයක් පරිපාලකගෙන් අසන්න.',
    'Back to Login': 'පිවිසීම වෙත ආපසු',
    'Account Suspended': 'ගිණුම අත්හිටුවා ඇත',
    'Sale Details': 'විකුණුම් විස්තර',
    'Order ID': 'ඇණවුම් අංකය',
    'Sale Price': 'විකුණුම් මිල',
    'You Receive': 'ඔබට ලැබෙන මුදල',
    'Sold On': 'විකුණු දිනය',
    'Funds will be added to your wallet automatically once escrow releases.': 'Escrow අවසන් වූ පසු මුදල් ස්වයංක්\u200dරීයව ඔබේ පසුම්බියට එක් වේ.',
    'Payment has been released to your wallet.': 'ගෙවීම ඔබේ පසුම්බියට මුදා හැර ඇත.',
    'This sale is under dispute review by admin.': 'මෙම විකිණීම පරිපාලකගේ විවාද සමාලෝචනය යටතේ ඇත.',
    'No sales yet': 'තවම විකුණුම් නැත',
    'Change these credentials immediately after login for your own security.': 'ඔබේ ආරක්ෂාව සඳහා පිවිසීමෙන් පසු මෙම විස්තර වහාම වෙනස් කරන්න.',
    'Remove Listing': 'ලැයිස්තුව ඉවත් කරන්න',
    'Listing removed': 'ලැයිස්තුව ඉවත් කළා',
    'Remove': 'ඉවත් කරන්න',
    'Bidding ended': 'ලංසු තැබීම අවසන්',
    'Enter a valid amount': 'වලංගු මුදලක් ඇතුළත් කරන්න',
    'Bid placed!': 'ලංසුව තැබුවා!',
    'Purchase successful! View credentials in My Purchases.': 'මිලදී ගැනීම සාර්ථකයි! My Purchases වෙතින් විස්තර බලන්න.',
    'Offer sent to seller': 'විකුණුම්කරුට යෝජනාව යැව්වා',
    'Offer accepted — order created': 'යෝජනාව පිළිගත්තා — ඇණවුම සාදන ලදී',
    'Offer rejected': 'යෝජනාව ප්\u200dරතික්ෂේප කළා',
    'No offers received yet': 'තවම ලැබුණු යෝජනා නැත',
    'No offers sent yet': 'තවම යැවූ යෝජනා නැත',
    'Photo updated': 'ඡායාරූපය යාවත්කාලීන කළා',
    'Profile saved. Name and phone are now locked.': 'පැතිකඩ සුරකින ලදී. නම සහ දුරකථන අංකය දැන් අගුළු දමා ඇත.',
    'Request Profile Change': 'පැතිකඩ වෙනස් කිරීමක් ඉල්ලන්න',
    'Support request submitted': 'සහාය ඉල්ලීම යවා ඇත',
    'Profile Management': 'පැතිකඩ කළමනාකරණය',
    'Display Name': 'පෙන්වන නම',
    'Phone Number': 'දුරකථන අංකය',
    'Request Change': 'වෙනස් කිරීමක් ඉල්ලන්න',
    'Your Referral Code': 'ඔබේ යොමු කේතය',
    'Share this code — earn LKR 100 per signup': 'මෙම කේතය බෙදාගෙන එක් ලියාපදිංචියකට LKR 100 උපයන්න',
    'My Purchases': 'මගේ මිලදී ගැනීම්',
    'Purchased On': 'මිලදී ගත් දිනය',
    'Admin has been notified': 'පරිපාලක දැනුවත් කර ඇත',
    'Dispute raised — admin will review': 'විවාදයක් ඉදිරිපත් කළා — පරිපාලක සමාලෝචනය කරනු ඇත',
    'View Account Credentials': 'ගිණුම් විස්තර බලන්න',
    'Raise a Dispute': 'විවාදයක් ඉදිරිපත් කරන්න',
    'Search accounts...': 'ගිණුම් සොයන්න...',
    'No conversations yet.\nChats appear after you buy or sell an account.': 'තවම සංවාද නැත.\nගිණුමක් මිලදී ගත් හෝ විකිණූ පසු චැට් පෙන්වනු ඇත.',
    'Changing your bank details requires email verification for security.': 'ආරක්ෂාව සඳහා බැංකු විස්තර වෙනස් කිරීමට ඊමේල් තහවුරු කිරීම අවශ්\u200dයයි.',
    'Enter Verification Code': 'තහවුරු කිරීමේ කේතය ඇතුළත් කරන්න',
    'Bank details updated successfully': 'බැංකු විස්තර සාර්ථකව යාවත්කාලීන කළා',
    'Add an account': 'ගිණුමක් එක් කරන්න',
    'Verification submitted — pending admin review': 'තහවුරු කිරීම යවා ඇත — පරිපාලක සමාලෝචනය පොරොත්තුවෙන්',
    'Get Verified': 'තහවුරු කරගන්න',
    'Verification Required': 'තහවුරු කිරීම අවශ්\u200dයයි',
    'Listing posted successfully': 'ලැයිස්තුව සාර්ථකව පළ කළා',
    'New passwords do not match': 'නව මුරපද ගැලපෙන්නේ නැත',
    'Password updated successfully': 'මුරපදය සාර්ථකව යාවත්කාලීන කළා',
    'Password reset successfully. Please login.': 'මුරපදය සාර්ථකව යළි සකසා ඇත. කරුණාකර පිවිසෙන්න',
    'Enter a valid email': 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න',
    'Send Verification Code': 'තහවුරු කිරීමේ කේතය යවන්න',
    'Top-up request submitted': 'මුදල් එක් කිරීමේ ඉල්ලීම යවා ඇත',
    'Withdrawal request submitted': 'මුදල් ලබාගැනීමේ ඉල්ලීම යවා ඇත',
    'Submit Top-Up': 'මුදල් එක් කිරීම යවන්න',
    'Request Withdrawal': 'මුදල් ලබාගැනීම ඉල්ලන්න',
    'Deposit to this account': 'මෙම ගිණුමට තැන්පත් කරන්න',
    'Withdraw to Bank': 'බැංකුවට මුදල් ලබාගන්න',
    'Terms & Agreement': 'නියම සහ ගිවිසුම',
    'I Agree & Continue': 'මම එකඟ වෙමි සහ ඉදිරියට යන්න',
    'Offer Received':'යෝජනාවක් ලැබී ඇත','Offer Accepted':'යෝජනාව පිළිගෙන ඇත','Offer Rejected':'යෝජනාව ප්‍රතික්ෂේප කර ඇත','Order Completed':'ඇණවුම සම්පූර්ණයි','Sale Paid':'විකුණුම් මුදල් ගෙවා ඇත','Top-Up Confirmed':'මුදල් එක් කිරීම තහවුරු කළා','Top-Up Rejected':'මුදල් එක් කිරීම ප්‍රතික්ෂේප කළා','Withdrawal Confirmed':'මුදල් ලබාගැනීම තහවුරු කළා','Withdrawal Rejected':'මුදල් ලබාගැනීම ප්‍රතික්ෂේප කළා','Verification Approved!':'තහවුරු කිරීම අනුමතයි!','Verification Rejected':'තහවුරු කිරීම ප්‍රතික්ෂේප කර ඇත','New Message':'නව පණිවිඩයක්','Dispute Resolved':'විවාදය විසඳා ඇත','Dispute Raised':'විවාදයක් ඉදිරිපත් කර ඇත','Account Banned':'ගිණුම අත්හිටුවා ඇත','Account Restored':'ගිණුම ප්‍රතිස්ථාපනය කළා','Wallet Adjusted':'පසුම්බිය යාවත්කාලීන කළා','Promotion':'ප්‍රවර්ධනය',

  },
  'Tamil': {
    'View':'பார்','Settings':'அமைப்புகள்','Home':'முகப்பு','Wallet':'பணப்பை','Sell':'விற்க','Chats':'அரட்டைகள்','Profile':'சுயவிவரம்','Notifications':'அறிவிப்புகள்','No notifications yet':'இன்னும் அறிவிப்புகள் இல்லை',
    'Login':'உள்நுழை','Sign Up':'பதிவு செய்க','Create account':'கணக்கை உருவாக்கு','Welcome back':'மீண்டும் வரவேற்கிறோம்','Sign up to get started':'தொடங்க பதிவு செய்க','Login to continue':'தொடர உள்நுழைக',
    'Email':'மின்னஞ்சல்','Display Name':'காட்சிப் பெயர்','Enter a display name':'காட்சிப் பெயரை உள்ளிடவும்','User':'பயனர்','From':'இருந்து','Guest User':'விருந்தினர்','Password':'கடவுச்சொல்','New Password':'புதிய கடவுச்சொல்','Confirm New Password':'புதிய கடவுச்சொல்லை உறுதிப்படுத்து','Current Password':'தற்போதைய கடவுச்சொல்','Forgot Password?':'கடவுச்சொல் மறந்துவிட்டதா?',
    'Reset Password':'கடவுச்சொல்லை மீட்டமை','Send Code':'குறியீட்டை அனுப்பு','Resend Code':'குறியீட்டை மீண்டும் அனுப்பு','Verification Code':'சரிபார்ப்பு குறியீடு','Enter the 6-digit code':'6 இலக்க குறியீட்டை உள்ளிடவும்','Verify':'சரிபார்',
    'Cancel':'ரத்து செய்','Delete':'நீக்கு','Save Changes':'மாற்றங்களை சேமி','Submit':'சமர்ப்பி','Confirm':'உறுதிப்படுத்து','Next':'அடுத்து','Skip':'தவிர்','Get Started':'தொடங்கு',
    'Language':'மொழி','English':'ஆங்கிலம்','Sinhala':'சிங்களம்','Tamil':'தமிழ்','Account':'கணக்கு','Profile Management':'சுயவிவர மேலாண்மை','Change Password / PIN':'கடவுச்சொல் / PIN மாற்று',
    'Verified Badge Status':'சரிபார்ப்பு பேட்ஜ் நிலை','My Listings':'எனது பட்டியல்கள்','My Purchases':'எனது கொள்முதல்கள்','My Sales':'எனது விற்பனைகள்','Offers':'சலுகைகள்','Wishlist':'விருப்பப்பட்டியல்',
    'Wallet & Bank Details':'பணப்பை மற்றும் வங்கி விவரங்கள்','Referral Code':'பரிந்துரை குறியீடு','Security':'பாதுகாப்பு','Biometric Lock':'உயிர்முறை பூட்டு','Blocked Users':'தடுக்கப்பட்ட பயனர்கள்',
    'Order Updates':'ஆர்டர் புதுப்பிப்புகள்','Offers & Bids':'சலுகைகள் மற்றும் ஏலங்கள்','Promotions':'விளம்பரங்கள்','Privacy & Data':'தனியுரிமை மற்றும் தரவு','Download My Data':'எனது தரவை பதிவிறக்கு',
    'Terms & Conditions':'விதிமுறைகள் மற்றும் நிபந்தனைகள்','Privacy Policy':'தனியுரிமைக் கொள்கை','Support':'ஆதரவு','Help & FAQ':'உதவி மற்றும் FAQ','Logout':'வெளியேறு','Delete Account':'கணக்கை நீக்கு',
    'Not Verified':'சரிபார்க்கப்படவில்லை','Verification Pending':'சரிபார்ப்பு நிலுவையில்','Verified Seller':'சரிபார்க்கப்பட்ட விற்பனையாளர்','Verification Rejected':'சரிபார்ப்பு நிராகரிக்கப்பட்டது',
    'Retry':'மீண்டும் முயற்சி','My Wallet':'எனது பணப்பை','Available Balance':'கிடைக்கும் இருப்பு','Top Up':'பணம் சேர்க்க','Withdraw':'பணம் பெற','Transaction History':'பரிவர்த்தனை வரலாறு','No transactions yet':'இன்னும் பரிவர்த்தனைகள் இல்லை',
    'Amount (LKR)':'தொகை (LKR)','Upload Bank Slip':'வங்கி ரசீதை பதிவேற்று','Request Withdrawal':'பணம் பெற கோரிக்கை','Sell an Account':'கணக்கை விற்க','Verification Required':'சரிபார்ப்பு தேவை',
    'Game':'விளையாட்டு','Listing Details':'பட்டியல் விவரங்கள்','Title':'தலைப்பு','Description':'விளக்கம்','Price (LKR)':'விலை (LKR)','Allow Bidding':'ஏலத்தை அனுமதி','Post Listing':'பட்டியலை வெளியிடு',
    'Place a Bid':'ஏலம் இடு','Make an Offer':'சலுகை செய்','Buy Now':'இப்போது வாங்கு','Confirm Purchase':'கொள்முதலை உறுதிப்படுத்து','Bid History':'ஏல வரலாறு','No listings yet':'இன்னும் பட்டியல்கள் இல்லை',
    'Active':'செயலில்','Pending':'நிலுவையில்','Sold':'விற்கப்பட்டது','Removed':'அகற்றப்பட்டது','Completed':'முடிந்தது','Disputed':'தகராறு','Refunded':'பணம் திருப்பப்பட்டது','No purchases yet':'இன்னும் கொள்முதல்கள் இல்லை','No sales yet':'இன்னும் விற்பனைகள் இல்லை','In Escrow':'Escrow-ல்','Paid Out':'பணம் வழங்கப்பட்டது',
    'Chat with Admin':'நிர்வாகியுடன் அரட்டை','Admin':'நிர்வாகி','Message admin...':'நிர்வாகிக்கு செய்தி...','Chat':'அரட்டை','Type a message...':'செய்தியை உள்ளிடவும்...',
    'Account Credentials':'கணக்கு உள்நுழைவு விவரங்கள்','Account Email':'கணக்கு மின்னஞ்சல்','Account Password':'கணக்கு கடவுச்சொல்','Recovery Codes':'மீட்பு குறியீடுகள்','Bank Name':'வங்கி பெயர்','Account Holder Name':'கணக்கு வைத்திருப்பவர் பெயர்','Account Number':'கணக்கு எண்','Branch':'கிளை','Send Verification Code':'சரிபார்ப்பு குறியீட்டை அனுப்பு',
    'Buy & Sell Game Accounts Safely':'விளையாட்டு கணக்குகளை பாதுகாப்பாக வாங்கி விற்கவும்','3-Day Escrow Protection':'3 நாள் Escrow பாதுகாப்பு','Encrypted Credentials Vault':'குறியாக்கப்பட்ட உள்நுழைவு Vault','Verified Sellers':'சரிபார்க்கப்பட்ட விற்பனையாளர்கள்',
    'Received':'பெறப்பட்டது','Sent':'அனுப்பப்பட்டது','Accept':'ஏற்றுக்கொள்','Reject':'நிராகரி','Accepted':'ஏற்றுக்கொள்ளப்பட்டது','Rejected':'நிராகரிக்கப்பட்டது','Expired':'காலாவதியானது','Referral Bonus':'பரிந்துரை போனஸ்','Copied to clipboard':'Clipboard-க்கு நகலெடுக்கப்பட்டது','Request Change':'மாற்றம் கோரு',
    'App Version':'பயன்பாட்டு பதிப்பு','Report a Problem / Contact Admin':'சிக்கலைப் புகாரளிக்க / நிர்வாகியைத் தொடர்புகொள்ள','Privacy & Data Deletion Request':'தனியுரிமை மற்றும் தரவு நீக்கக் கோரிக்கை',
    'Offer Received':'சலுகை கிடைத்துள்ளது','Offer Accepted':'சலுகை ஏற்கப்பட்டது','Offer Rejected':'சலுகை நிராகரிக்கப்பட்டது','Order Completed':'ஆர்டர் முடிந்தது','Sale Paid':'விற்பனை பணம் செலுத்தப்பட்டது','Top-Up Confirmed':'பணம் சேர்ப்பு உறுதிப்படுத்தப்பட்டது','Top-Up Rejected':'பணம் சேர்ப்பு நிராகரிக்கப்பட்டது','Withdrawal Confirmed':'பணம் பெறுதல் உறுதிப்படுத்தப்பட்டது','Withdrawal Rejected':'பணம் பெறுதல் நிராகரிக்கப்பட்டது','Verification Approved!':'சரிபார்ப்பு அங்கீகரிக்கப்பட்டது!','Verification Rejected':'சரிபார்ப்பு நிராகரிக்கப்பட்டது','New Message':'புதிய செய்தி','Dispute Resolved':'தகராறு தீர்க்கப்பட்டது','Dispute Raised':'தகராறு சமர்ப்பிக்கப்பட்டது','Account Banned':'கணக்கு இடைநிறுத்தப்பட்டது','Account Restored':'கணக்கு மீட்டமைக்கப்பட்டது','Wallet Adjusted':'பணப்பை புதுப்பிக்கப்பட்டது','Promotion':'விளம்பரம்',

  }
};

String tr(String key) {
  final lang = AppLanguage.instance.language;
  final direct = translations[lang]?[key];
  if (direct != null) return direct;
  if (lang == 'Sinhala') {
    if (key.startsWith('Reason: ')) return 'හේතුව: ${key.substring(8)}';
    if (key.endsWith(' coming soon')) return '${key.substring(0, key.length - 12)} ළඟදීම ලබාගත හැක';
    if (key == 'Fingerprint / Face ID to open app') return 'යෙදුම විවෘත කිරීමට Fingerprint / Face ID';
  }
  if (lang == 'Tamil') {
    if (key.startsWith('Reason: ')) return 'காரணம்: ${key.substring(8)}';
    if (key.endsWith(' coming soon')) return '${key.substring(0, key.length - 12)} விரைவில் கிடைக்கும்';
    if (key == 'Fingerprint / Face ID to open app') return 'பயன்பாட்டைத் திறக்க Fingerprint / Face ID';
  }
  return key;
}
