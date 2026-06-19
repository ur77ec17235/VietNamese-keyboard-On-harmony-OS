import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const PREF_NAME = 'gtv_preferences';

export class PreferencesManager {
  private static pref: preferences.Preferences | null = null;

  static async init(context: common.Context, forceRefresh: boolean = false): Promise<void> {
    const appContext = context.getApplicationContext ? context.getApplicationContext() : context;
    if (forceRefresh) {
      try {
        await preferences.removePreferencesFromCache(appContext, PREF_NAME);
      } catch (e) {}
      PreferencesManager.pref = null;
    }
    if (!PreferencesManager.pref) {
      PreferencesManager.pref = await preferences.getPreferences(appContext, PREF_NAME);
    }
  }

  static async set(key: string, value: preferences.ValueType): Promise<void> {
    if (PreferencesManager.pref) {
      await PreferencesManager.pref.put(key, value);
      await PreferencesManager.pref.flush();
    }
  }

  static async get(key: string, defaultValue: preferences.ValueType): Promise<preferences.ValueType> {
    if (PreferencesManager.pref) {
      return await PreferencesManager.pref.get(key, defaultValue);
    }
    return defaultValue;
  }
}
