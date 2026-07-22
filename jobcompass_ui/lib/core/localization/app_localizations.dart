import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en'),
  russian('ru');

  const AppLanguage(this.code);

  final String code;
}

class LocaleNotifier extends Notifier<AppLanguage> {
  static const _languageKey = 'app_language';

  @override
  AppLanguage build() {
    Future.microtask(_restoreLanguage);
    return AppLanguage.russian;
  }

  Future<void> _restoreLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_languageKey);
    final language = AppLanguage.values.where((item) => item.code == saved);
    if (language.isNotEmpty) {
      state = language.first;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language.code);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, AppLanguage>(
  LocaleNotifier.new,
);

class AppStrings extends InheritedWidget {
  final AppLanguage language;

  const AppStrings({super.key, required this.language, required super.child});

  static AppStrings of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStrings>() ??
        const AppStrings(
          language: AppLanguage.russian,
          child: SizedBox.shrink(),
        );
  }

  String tr(String key) {
    return _translations[language]?[key] ??
        _translations[AppLanguage.english]![key] ??
        key;
  }

  @override
  bool updateShouldNotify(AppStrings oldWidget) =>
      language != oldWidget.language;
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
  String tr(String key) => strings.tr(key);
}

const Map<AppLanguage, Map<String, String>> _translations = {
  AppLanguage.english: {
    'home': 'Home',
    'feed': 'Feed',
    'saved': 'Saved',
    'crm': 'Analytics',
    'profile': 'Profile',
    'admin': 'Admin',
    'settings': 'Settings',
    'retry': 'Retry',
    'language': 'Language',
    'english': 'English',
    'russian': 'Русский',
    'dark_theme': 'Dark Theme',
    'dark_theme_subtitle': 'Use dark appearance',
    'logout': 'Logout',
    'logout_title': 'Log out of JobCompass?',
    'logout_description': 'You can sign in again at any time.',
    'cancel': 'Cancel',
    'about': 'About JobCompass',
    'version': 'Version 1.0',
    'notifications': 'Notifications',
    'privacy': 'Privacy',
    'privacy_subtitle': 'How JobCompass handles your account data',
    'privacy_passwords':
        'Passwords are stored only as secure hashes and are never shown in the interface.',
    'privacy_profile':
        'Profile data is used to personalize vacancies and calculate job matches.',
    'privacy_resume':
        'You can remove the uploaded resume without deleting manually entered profile fields.',
    'privacy_admin':
        'Account information is available only to you and platform administrators.',
    'account': 'Account',
    'login': 'Login',
    'account_id': 'User ID',
    'account_status': 'Account status',
    'user_role': 'User',
    'administrator_role': 'Administrator',
    'failed_load_account': 'Could not load account information',
    'welcome_back': 'Welcome back',
    'workspace_ready': 'Your JobCompass workspace is ready.',
    'platform_title': 'Your job search, in one place',
    'platform_description':
        'JobCompass turns your resume into a focused workspace for finding, saving and tracking the right opportunities.',
    'how_to_use': 'How to use JobCompass',
    'step_upload': 'Set up your profile',
    'step_upload_description':
        'Fill it manually, upload a resume, or combine both options.',
    'step_discover': 'Discover relevant jobs',
    'step_discover_description':
        'Browse vacancies selected for your profile in Feed.',
    'step_save': 'Save what matters',
    'step_save_description':
        'Keep promising opportunities and add comments for later.',
    'step_track': 'Track your progress',
    'step_track_description': 'Analyze applications and track their stages.',
    'open_feed': 'Explore Feed',
    'open_saved': 'Saved Jobs',
    'manage_profile': 'Manage Profile',
    'profile_setup_options':
        'Fill in the profile manually, upload a resume, or use both options together.',
    'create_profile_manually': 'Fill Profile Manually',
    'upload_resume': 'Upload Resume',
    'replace_resume': 'Replace Resume',
    'analyzing_resume': 'Analyzing Resume...',
    'profile_not_specified': 'Profession not specified',
    'level_not_specified': 'Level not specified',
    'profession': 'Profession',
    'level': 'Level',
    'preferred_roles': 'Preferred Roles',
    'skills': 'Skills',
    'technologies': 'Technologies',
    'english_level': 'English Level',
    'resume': 'Resume',
    'resume_uploaded': 'Resume uploaded',
    'no_resume': 'No resume uploaded',
    'delete_resume': 'Delete Resume',
    'delete_resume_title': 'Delete Resume',
    'delete_resume_description':
        'This will permanently delete the uploaded resume. Your manually entered profile fields will remain. Continue?',
    'delete': 'Delete',
    'close': 'Close',
    'edit_profile': 'Edit Profile',
    'save_changes': 'Save Changes',
    'saving': 'Saving...',
    'crm_empty_title': 'No applications yet',
    'crm_empty_description': 'Jobs you apply to will appear here.',
    'analytics': 'Summary',
    'in_progress': 'In Progress',
    'edit_analytics': 'Edit Analytics',
    'use_automatic': 'Use automatic',
    'save': 'Save',
    'open_vacancy': 'Open vacancy details',
    'change_status': 'Change application status',
    'failed_open': 'Failed to open vacancy',
    'failed_status': 'Failed to update application status',
    'failed_upload': 'Failed to upload resume',
    'failed_delete': 'Failed to delete resume',
    'resume_created': 'Resume uploaded and profile created',
    'resume_deleted': 'Resume deleted successfully',
    'resume_replaced': 'Resume replaced and profile updated',
    'failed_profile': 'Failed to update profile',
    'failed_load_profile': 'Could not load your profile',
    'failed_load_profile_description':
        'JobCompass could not check your profile right now.',
    'no_saved_jobs': 'No saved jobs found',
    'search': 'Search',
    'clear_search': 'Clear search',
    'reset': 'Reset',
    'job_removed': 'Job removed from Saved',
    'failed_remove_job': 'Failed to remove saved job',
    'check_again': 'Check again',
    'clear_filters': 'Clear filters',
    'work_format': 'Work format',
    'publication_date': 'Publication date',
    'jobs_found': 'Found',
    'jobs_visible': 'Visible',
    'job_sources': 'Platforms',
    'sources_unknown': 'Sources unknown',
    'refresh_jobs': 'Refresh vacancies',
    'refresh_jobs_failed':
        'Could not refresh vacancies. The current list was preserved. Please try again later.',
    'apply': 'Apply',
    'skip': 'Skip',
    'saved_action': 'Saved',
    'save_action': 'Save',
    'job_saved': 'Job saved',
    'could_not_save': 'Could not save job',
    'failed_skip': 'Failed to skip job',
    'job_skipped': 'Job skipped',
    'vacancy': 'Vacancy',
    'open_again': 'Open Vacancy Again',
    'add_comment': 'Add comment',
    'edit_comment': 'Edit comment',
    'comment_hint': 'Add a note about this vacancy',
    'comment': 'Comment',
    'loading_comment': 'Loading comment...',
    'failed_load_comment': 'Could not load comment',
    'retry_comment': 'Retry loading comment',
    'comment_unavailable': 'Comment is not available for this vacancy yet.',
    'comment_saved': 'Comment saved',
    'comment_removed': 'Comment removed',
    'failed_comment': 'Failed to save comment',
    'upload_resume_first': 'Set up your profile first',
    'feed_resume_description':
        'JobCompass needs profile data to build a personalized job feed.',
    'feed_resume_long_description':
        'Fill in your profile manually or upload a resume so JobCompass can understand your experience, skills, and preferred roles.',
    'open_profile_upload':
        'Open Profile and fill in the fields or upload a resume to get started.',
    'registered_users': 'Registered users',
    'administrators': 'Administrators',
    'users': 'Users',
    'no_users': 'No users found',
    'user_details': 'User details',
    'registered_at': 'Registered',
    'profile_data': 'Profile data',
    'profile_not_created': 'The user has not created a profile yet.',
    'resume_present': 'Resume uploaded',
    'resume_absent': 'Profile completed without a resume',
    'grant_admin': 'Grant administrator rights',
    'revoke_admin': 'Revoke administrator rights',
    'change_role_confirmation':
        'The user permissions will change immediately. Continue?',
    'confirm': 'Confirm',
    'admin_role_updated': 'Administrator rights updated',
    'failed_admin_role': 'Could not update administrator rights',
    'cannot_change_own_role':
        'You cannot revoke your own administrator rights.',
    'admin_access_error':
        'The Admin section is available only to platform administrators.',
    'no_jobs_found': 'No jobs found',
    'untitled_vacancy': 'Untitled vacancy',
    'details_not_specified': 'Details not specified',
    'no_saved_jobs_yet': 'No saved jobs yet',
    'saved_from_feed': 'Jobs saved from the Feed will appear here.',
    'removing_saved': 'Removing saved vacancy',
    'remove_saved': 'Remove saved',
    'total_applications': 'Total Applications',
    'total_screenings': 'Total Screenings',
    'total_interviews': 'Total Interviews',
    'total_offers': 'Total Offers',
    'total_rejected': 'Total Rejected',
    'active_processes': 'Active Processes',
    'screening': 'Screening',
    'interview': 'Interview',
    'technical_interview': 'Tech Interview',
    'offer': 'Offer',
    'historical_totals': 'Historical totals across your job search',
    'automatic_statuses': 'Calculated automatically from current CRM statuses',
    'applied': 'Applied',
    'rejected': 'Rejected',
    'failed_stats': 'Failed to load CRM statistics',
    'analytics_editor_description':
        'These historical totals are saved to your account. In Progress metrics stay automatic.',
    'enter_non_negative': 'Enter a number of 0 or greater',
    'sign_in_subtitle': 'Sign in to continue your job search',
    'sign_up_subtitle': 'Create an account to start using JobCompass',
    'full_name': 'Full name',
    'full_name_hint': 'Alex Johnson',
    'enter_full_name': 'Enter your full name',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm password',
    'enter_email': 'Enter your email',
    'valid_email': 'Enter a valid email',
    'enter_password': 'Enter your password',
    'password_min_length': 'Password must be at least 12 characters',
    'password_max_length': 'Password must be no longer than 128 characters',
    'confirm_password_required': 'Confirm your password',
    'passwords_do_not_match': 'Passwords do not match',
    'sign_in': 'Sign In',
    'sign_up': 'Create Account',
    'create_account': 'Create a new account',
    'already_have_account': 'Already have an account? Sign in',
    'registration_check_email':
        'Account created. Check your email and confirm it before signing in.',
    'email_verification_required':
        'Confirm your email before signing in. You can request a new link below.',
    'resend_verification': 'Send the link again',
    'verification_sent': 'A verification link has been sent to your email.',
    'failed_send_verification': 'Could not send the verification email.',
    'email_verification_success': 'Email confirmed. You can now sign in.',
    'email_verification_invalid':
        'This confirmation link is invalid or has expired.',
    'verify_email_prompt_title': 'Confirm your email',
    'verify_email_prompt_body':
        'Confirm the address to protect your account and enable payments.',
    'verify_email': 'Confirm',
    'email_verified': 'Email confirmed',
    'email_not_verified': 'Email is not confirmed',
    'analytics_promo_short':
        'Lifetime access to job search Analytics — 99 ₽ once',
    'learn_more': 'Learn more',
    'analytics_lifetime_title': 'Analytics forever for 99 ₽',
    'analytics_lifetime_body':
        'Track applications, stages, comments and historical results. One payment, no recurring charge.',
    'buy_analytics_crypto': 'Pay {price} with crypto',
    'payment_invoice_amount':
        'The invoice is {amount} {currency}; you choose the cryptocurrency on the payment page.',
    'payment_requires_verified_email':
        'Confirm your email in Profile before payment.',
    'payment_unavailable':
        'Payment is temporarily unavailable. Please try again later.',
    'payment_open_failed': 'Could not open the secure payment page.',
    'check_payment': 'I paid — check payment',
    'payment_pending': 'Payment has not been confirmed yet.',
    'analytics_access_active': 'Analytics access is active.',
    'payment_security_note':
        'Payment is completed on NOWPayments. JobCompass does not receive or store wallet keys.',
    'why_matches': 'Why this matches',
    'missing_skills': 'Missing skills',
    'match': 'Match',
    'applying': 'Applying...',
    'application_saved_not_opened':
        'Application saved, but the vacancy could not be opened',
    'failed_application': 'Failed to save application',
    'separate_commas': 'Separate values with commas',
    'required': 'is required',
    'api_hint': 'API Testing, Regression Testing, SQL',
    'tech_hint': 'Postman, Docker, PostgreSQL',
    'ai_coach': 'AI Career Coach',
    'ai_hint': 'Ask your career question...',
    'roles_hint': 'QA Engineer, Manual QA, Test Engineer',
    'no_preferred_roles': 'No preferred roles specified',
    'no_skills': 'No skills specified',
    'no_technologies': 'No technologies specified',
    'no_english_level': 'English level not specified',
    'route_not_found': 'Route not found',
    'archive': 'Archive',
    'archive_application': 'Archive vacancy',
    'archived_applications_description':
        'Archived CRM vacancies are stored here and can be restored at any time.',
    'archive_is_empty': 'Archive is empty',
    'restore_from_archive': 'Restore from archive',
    'failed_load_archive': 'Failed to load archive',
    'failed_archive_application': 'Failed to archive vacancy',
    'failed_unarchive_application': 'Failed to restore vacancy',
    'open_vacancy_first': 'Open Vacancy',
    'opening_vacancy': 'Opening vacancy...',
    'did_you_apply_question': 'Did you apply to this vacancy?',
    'yes': 'Yes',
    'no': 'No',
    'application_yes_status': 'Application was submitted',
    'application_no_status': 'No application was sent',
    'change_decision': 'Change decision',
    'failed_load_job_details': 'Could not load vacancy details',
    'details_not_available': 'Details are not available yet',
    'job_description': 'Job Description',
    'load_job_description': 'Load job description',
    'description_unavailable':
        'The vacancy description is not available for this source yet.',
    'failed_load_description': 'Could not load job description',
    'short_cover_letter': 'Short Cover Letter',
    'generate_cover_letter': 'Generate cover letter',
    'cover_letter_unavailable': 'The cover letter is not available right now.',
    'failed_generate_cover_letter': 'Could not generate cover letter',
    'tailored_resume': 'Tailored Resume',
    'tailored_resume_description':
        'Generate a resume version focused on this vacancy requirements.',
    'generate_resume': 'Generate tailored resume',
    'failed_generate_resume': 'Could not generate tailored resume',
    'resume_generation_unavailable':
        'Tailored resume is not available right now.',
    'loading_match': 'Calculating match percentage...',
    'failed_load_match': 'Could not calculate match percentage',
    'required_skills_title': 'Required Skills',
    'failed_load_required_skills': 'Could not load required skills',
    'last_24_hours': 'Last 24 hours',
    'last_7_days': 'Last 7 days',
    'last_30_days': 'Last 30 days',
  },
  AppLanguage.russian: {
    'home': 'Главная',
    'feed': 'Вакансии',
    'saved': 'Сохранённые',
    'crm': 'Аналитика',
    'profile': 'Профиль',
    'admin': 'Админ',
    'settings': 'Настройки',
    'retry': 'Повторить',
    'language': 'Язык',
    'english': 'English',
    'russian': 'Русский',
    'dark_theme': 'Тёмная тема',
    'dark_theme_subtitle': 'Использовать тёмное оформление',
    'logout': 'Выйти',
    'logout_title': 'Выйти из JobCompass?',
    'logout_description': 'Вы сможете войти снова в любой момент.',
    'cancel': 'Отмена',
    'about': 'О JobCompass',
    'version': 'Версия 1.0',
    'notifications': 'Уведомления',
    'privacy': 'Приватность',
    'privacy_subtitle': 'Как JobCompass работает с данными аккаунта',
    'privacy_passwords':
        'Пароли хранятся только в виде защищённых хешей и не отображаются в интерфейсе.',
    'privacy_profile':
        'Данные профиля используются для подбора вакансий и расчёта совпадения.',
    'privacy_resume':
        'Загруженное резюме можно удалить, не удаляя поля, заполненные вручную.',
    'privacy_admin':
        'Информация аккаунта доступна только вам и администраторам платформы.',
    'account': 'Аккаунт',
    'login': 'Логин',
    'account_id': 'ID пользователя',
    'account_status': 'Статус аккаунта',
    'user_role': 'Пользователь',
    'administrator_role': 'Администратор',
    'failed_load_account': 'Не удалось загрузить информацию об аккаунте',
    'welcome_back': 'С возвращением',
    'workspace_ready': 'Рабочее пространство JobCompass готово.',
    'platform_title': 'Поиск работы — в одном месте',
    'platform_description':
        'JobCompass превращает резюме в удобное пространство для поиска, сохранения и отслеживания подходящих вакансий.',
    'how_to_use': 'Как пользоваться JobCompass',
    'step_upload': 'Настройте профиль',
    'step_upload_description':
        'Заполните его вручную, загрузите резюме или совместите оба варианта.',
    'step_discover': 'Изучайте вакансии',
    'step_discover_description':
        'Смотрите подходящие предложения в разделе Вакансии.',
    'step_save': 'Сохраняйте важное',
    'step_save_description':
        'Сохраняйте перспективные вакансии и добавляйте комментарии.',
    'step_track': 'Отслеживайте прогресс',
    'step_track_description': 'Анализируйте отклики и отслеживайте их этапы.',
    'open_feed': 'Открыть вакансии',
    'open_saved': 'Сохранённые вакансии',
    'manage_profile': 'Управление профилем',
    'profile_setup_options':
        'Заполните профиль вручную, загрузите резюме или используйте оба варианта вместе.',
    'create_profile_manually': 'Заполнить профиль вручную',
    'upload_resume': 'Загрузить резюме',
    'replace_resume': 'Заменить резюме',
    'analyzing_resume': 'Анализируем резюме...',
    'profile_not_specified': 'Профессия не указана',
    'level_not_specified': 'Уровень не указан',
    'profession': 'Профессия',
    'level': 'Уровень',
    'preferred_roles': 'Желаемые роли',
    'skills': 'Навыки',
    'technologies': 'Технологии',
    'english_level': 'Уровень английского',
    'resume': 'Резюме',
    'resume_uploaded': 'Резюме загружено',
    'no_resume': 'Резюме не загружено',
    'delete_resume': 'Удалить резюме',
    'delete_resume_title': 'Удалить резюме',
    'delete_resume_description':
        'Загруженное резюме будет удалено без возможности восстановления. Поля профиля, заполненные вручную, сохранятся. Продолжить?',
    'delete': 'Удалить',
    'close': 'Закрыть',
    'edit_profile': 'Редактировать профиль',
    'save_changes': 'Сохранить изменения',
    'saving': 'Сохраняем...',
    'crm_empty_title': 'Откликов пока нет',
    'crm_empty_description':
        'Вакансии, на которые вы откликнетесь, появятся здесь.',
    'analytics': 'Итоги',
    'in_progress': 'В процессе',
    'edit_analytics': 'Изменить аналитику',
    'use_automatic': 'Использовать автоматически',
    'save': 'Сохранить',
    'open_vacancy': 'Открыть детали вакансии',
    'change_status': 'Изменить статус отклика',
    'failed_open': 'Не удалось открыть вакансию',
    'failed_status': 'Не удалось изменить статус отклика',
    'failed_upload': 'Не удалось загрузить резюме',
    'failed_delete': 'Не удалось удалить резюме',
    'resume_created': 'Резюме загружено, профиль создан',
    'resume_deleted': 'Резюме успешно удалено',
    'resume_replaced': 'Резюме заменено, профиль обновлён',
    'failed_profile': 'Не удалось обновить профиль',
    'failed_load_profile': 'Не удалось загрузить профиль',
    'failed_load_profile_description':
        'JobCompass не может проверить профиль прямо сейчас.',
    'no_saved_jobs': 'Сохранённых вакансий нет',
    'ai_coach': 'AI-карьерный консультант',
    'ai_hint': 'Задайте вопрос о карьере...',
    'no_preferred_roles': 'Желаемые роли не указаны',
    'no_skills': 'Навыки не указаны',
    'no_technologies': 'Технологии не указаны',
    'no_english_level': 'Уровень английского не указан',
    'route_not_found': 'Раздел не найден',
    'last_24_hours': 'Последние 24 часа',
    'last_7_days': 'Последние 7 дней',
    'last_30_days': 'Последние 30 дней',
    'sign_in_subtitle': 'Войдите, чтобы продолжить поиск работы',
    'sign_up_subtitle':
        'Создайте аккаунт, чтобы начать пользоваться JobCompass',
    'full_name': 'Имя и фамилия',
    'full_name_hint': 'Алексей Иванов',
    'enter_full_name': 'Введите имя и фамилию',
    'email': 'Email',
    'password': 'Пароль',
    'confirm_password': 'Повторите пароль',
    'enter_email': 'Введите email',
    'valid_email': 'Введите корректный email',
    'enter_password': 'Введите пароль',
    'password_min_length': 'Пароль должен быть не короче 12 символов',
    'password_max_length': 'Пароль должен быть не длиннее 128 символов',
    'confirm_password_required': 'Повторите пароль',
    'passwords_do_not_match': 'Пароли не совпадают',
    'sign_in': 'Войти',
    'sign_up': 'Создать аккаунт',
    'create_account': 'Создать новый аккаунт',
    'already_have_account': 'Уже есть аккаунт? Войти',
    'registration_check_email':
        'Аккаунт создан. Проверьте почту и подтвердите её перед входом.',
    'email_verification_required':
        'Подтвердите почту перед входом. Новую ссылку можно запросить ниже.',
    'resend_verification': 'Отправить ссылку ещё раз',
    'verification_sent': 'Ссылка подтверждения отправлена на вашу почту.',
    'failed_send_verification': 'Не удалось отправить письмо подтверждения.',
    'email_verification_success': 'Почта подтверждена. Теперь можно войти.',
    'email_verification_invalid':
        'Ссылка подтверждения недействительна или устарела.',
    'verify_email_prompt_title': 'Подтвердите почту',
    'verify_email_prompt_body':
        'Подтверждение защищает аккаунт и открывает возможность оплаты.',
    'verify_email': 'Подтвердить',
    'email_verified': 'Почта подтверждена',
    'email_not_verified': 'Почта не подтверждена',
    'analytics_promo_short': 'Бессрочный доступ к Аналитике — один платёж 99 ₽',
    'learn_more': 'Подробнее',
    'analytics_lifetime_title': 'Аналитика навсегда за 99 ₽',
    'analytics_lifetime_body':
        'Отслеживайте отклики, этапы, комментарии и исторические итоги. Один платёж без продления подписки.',
    'buy_analytics_crypto': 'Оплатить {price} криптовалютой',
    'payment_invoice_amount':
        'Счёт выставляется на {amount} {currency}; криптовалюту вы выбираете на странице оплаты.',
    'payment_requires_verified_email':
        'Перед оплатой подтвердите почту в разделе «Профиль».',
    'payment_unavailable': 'Оплата временно недоступна. Попробуйте позже.',
    'payment_open_failed': 'Не удалось открыть безопасную страницу оплаты.',
    'check_payment': 'Я оплатил — проверить платёж',
    'payment_pending': 'Платёж пока не подтверждён.',
    'analytics_access_active': 'Доступ к Аналитике активирован.',
    'payment_security_note':
        'Оплата проходит на стороне NOWPayments. JobCompass не получает и не хранит ключи вашего кошелька.',
    'why_matches': 'Почему подходит',
    'missing_skills': 'Недостающие навыки',
    'match': 'Совпадение',
    'applying': 'Откликаемся...',
    'application_saved_not_opened':
        'Отклик сохранён, но вакансию не удалось открыть',
    'failed_application': 'Не удалось сохранить отклик',
    'separate_commas': 'Разделяйте значения запятыми',
    'required': 'обязательно',
    'api_hint': 'API-тестирование, регрессионное тестирование, SQL',
    'tech_hint': 'Postman, Docker, PostgreSQL',
    'roles_hint': 'QA Engineer, Manual QA, Test Engineer',
    'search': 'Поиск',
    'clear_search': 'Очистить поиск',
    'reset': 'Сбросить',
    'job_removed': 'Вакансия удалена из сохранённых',
    'failed_remove_job': 'Не удалось удалить сохранённую вакансию',
    'check_again': 'Проверить снова',
    'clear_filters': 'Очистить фильтры',
    'work_format': 'Формат работы',
    'publication_date': 'Дата публикации',
    'jobs_found': 'Найдено',
    'jobs_visible': 'Показано',
    'job_sources': 'Платформы',
    'sources_unknown': 'Источники не определены',
    'refresh_jobs': 'Обновить вакансии',
    'refresh_jobs_failed':
        'Не удалось обновить вакансии. Текущий список сохранён. Повторите позже.',
    'apply': 'Применить',
    'skip': 'Пропустить',
    'saved_action': 'Сохранено',
    'save_action': 'Сохранить',
    'job_saved': 'Вакансия сохранена',
    'could_not_save': 'Не удалось сохранить вакансию',
    'failed_skip': 'Не удалось пропустить вакансию',
    'job_skipped': 'Вакансия пропущена',
    'vacancy': 'Вакансия',
    'open_again': 'Открыть вакансию снова',
    'add_comment': 'Добавить комментарий',
    'edit_comment': 'Изменить комментарий',
    'comment_hint': 'Добавьте заметку о вакансии',
    'comment': 'Комментарий',
    'loading_comment': 'Загружаем комментарий...',
    'failed_load_comment': 'Не удалось загрузить комментарий',
    'retry_comment': 'Повторить загрузку комментария',
    'comment_unavailable': 'Комментарий для этой вакансии пока недоступен.',
    'comment_saved': 'Комментарий сохранён',
    'comment_removed': 'Комментарий удалён',
    'failed_comment': 'Не удалось сохранить комментарий',
    'upload_resume_first': 'Сначала настройте профиль',
    'feed_resume_description':
        'JobCompass нужны данные профиля для формирования персональной ленты вакансий.',
    'feed_resume_long_description':
        'Заполните профиль вручную или загрузите резюме, чтобы JobCompass понял ваш опыт, навыки и желаемые роли.',
    'open_profile_upload':
        'Откройте Профиль и заполните поля или загрузите резюме, чтобы начать.',
    'registered_users': 'Зарегистрировано пользователей',
    'administrators': 'Администраторов',
    'users': 'Пользователи',
    'no_users': 'Пользователи не найдены',
    'user_details': 'Информация о пользователе',
    'registered_at': 'Дата регистрации',
    'profile_data': 'Данные профиля',
    'profile_not_created': 'Пользователь ещё не создал профиль.',
    'resume_present': 'Резюме загружено',
    'resume_absent': 'Профиль заполнен без резюме',
    'grant_admin': 'Выдать права администратора',
    'revoke_admin': 'Забрать права администратора',
    'change_role_confirmation':
        'Права пользователя изменятся сразу. Продолжить?',
    'confirm': 'Подтвердить',
    'admin_role_updated': 'Права администратора обновлены',
    'failed_admin_role': 'Не удалось изменить права администратора',
    'cannot_change_own_role':
        'Нельзя забрать права администратора у собственного аккаунта.',
    'admin_access_error':
        'Раздел «Админ» доступен только администраторам платформы.',
    'no_jobs_found': 'Вакансии не найдены',
    'untitled_vacancy': 'Вакансия без названия',
    'details_not_specified': 'Детали не указаны',
    'no_saved_jobs_yet': 'Сохранённых вакансий пока нет',
    'saved_from_feed': 'Вакансии, сохранённые в ленте, появятся здесь.',
    'removing_saved': 'Удаляем сохранённую вакансию',
    'remove_saved': 'Удалить из сохранённых',
    'total_applications': 'Всего откликов',
    'total_screenings': 'Всего скринингов',
    'total_interviews': 'Всего интервью',
    'total_offers': 'Всего офферов',
    'total_rejected': 'Всего отказов',
    'active_processes': 'Активные процессы',
    'screening': 'Скрининг',
    'interview': 'Интервью',
    'technical_interview': 'Тех. интервью',
    'offer': 'Оффер',
    'historical_totals': 'Исторические итоги поиска',
    'automatic_statuses':
        'Рассчитывается автоматически по текущим статусам CRM',
    'applied': 'Отклик отправлен',
    'rejected': 'Отказ',
    'failed_stats': 'Не удалось загрузить статистику CRM',
    'analytics_editor_description':
        'Исторические итоги сохраняются в аккаунте. Показатели «В процессе» остаются автоматическими.',
    'enter_non_negative': 'Введите число 0 или больше',
    'archive': 'Архив',
    'archive_application': 'Архивировать вакансию',
    'archived_applications_description':
        'Здесь хранятся архивные вакансии CRM. Их можно восстановить в любой момент.',
    'archive_is_empty': 'Архив пуст',
    'restore_from_archive': 'Восстановить из архива',
    'failed_load_archive': 'Не удалось загрузить архив',
    'failed_archive_application': 'Не удалось архивировать вакансию',
    'failed_unarchive_application': 'Не удалось восстановить вакансию',
    'open_vacancy_first': 'Открыть вакансию',
    'opening_vacancy': 'Открываем вакансию...',
    'did_you_apply_question': 'Вы откликнулись на вакансию?',
    'yes': 'Да',
    'no': 'Нет',
    'application_yes_status': 'Отклик был отправлен',
    'application_no_status': 'Отклика не было',
    'change_decision': 'Изменить решение',
    'failed_load_job_details': 'Не удалось загрузить детали вакансии',
    'details_not_available': 'Данные пока недоступны',
    'job_description': 'Описание вакансии',
    'load_job_description': 'Загрузить описание вакансии',
    'description_unavailable':
        'Описание вакансии пока недоступно для этого источника.',
    'failed_load_description': 'Не удалось загрузить описание вакансии',
    'short_cover_letter': 'Короткое сопроводительное письмо',
    'generate_cover_letter': 'Сгенерировать сопроводительное письмо',
    'cover_letter_unavailable': 'Сопроводительное письмо сейчас недоступно.',
    'failed_generate_cover_letter':
        'Не удалось сгенерировать сопроводительное письмо',
    'tailored_resume': 'Резюме под вакансию',
    'tailored_resume_description':
        'Сгенерируйте версию резюме, сфокусированную на требованиях этой вакансии.',
    'generate_resume': 'Сгенерировать резюме',
    'failed_generate_resume': 'Не удалось сгенерировать резюме под вакансию',
    'resume_generation_unavailable': 'Резюме под вакансию сейчас недоступно.',
    'loading_match': 'Рассчитываем процент совпадения...',
    'failed_load_match': 'Не удалось рассчитать процент совпадения',
    'required_skills_title': 'Требуемые навыки',
    'failed_load_required_skills': 'Не удалось загрузить требуемые навыки',
  },
};
