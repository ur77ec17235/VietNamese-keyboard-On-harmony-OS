/**
 * Index.ets - Settings Page của GoTiếngViệt
 * Giao diện cài đặt đẹp với dark theme
 */

import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import commonEventManager from '@ohos.commonEventManager';
import preferences from '@ohos.data.preferences';
import display from '@ohos.display';
import { InputLanguageOption, INSTALLED_INPUT_LANGUAGES } from '../telex/core/InputLanguageCatalog';
import { PreferencesManager } from '../telex/core/PreferencesManager';
import { DEFAULT_KEYBOARD_BG_COLOR, DEFAULT_KEYBOARD_DARK_MODE, DEFAULT_KEYBOARD_KEY_COLOR,
  DEFAULT_KEYBOARD_KEY_OPACITY, DEFAULT_KEYBOARD_OPACITY, getKeyboardTextColor, GTV_BG_COLOR_KEY,
  GTV_BG_OPACITY_KEY, GTV_DARK_MODE_KEY, GTV_KEY_COLOR_KEY, GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR, GTV_KEY_OPACITY_KEY,
  GTV_SHOW_NUMBER_ROW_KEY, KEYBOARD_COLOR_PALETTE, KEYBOARD_THEME_PRESETS, KeyboardThemePreset,
  normalizeKeyboardOpacity } from '../telex/ui/KeyboardTheme';
import {
  GTV_KEY_SIZE_LABEL_KEY,
  GTV_SOUND_ENABLED_KEY,
  GTV_VIBRATION_ENABLED_KEY,
  GTV_CLIPBOARD_ENABLED_KEY,
  GTV_SUGGESTION_ENABLED_KEY,
  GTV_AUTO_CAPITALIZE_KEY,
  GTV_AUTO_SPACE_PUNCTUATION_KEY,
  GTV_KEY_POPUP_PREVIEW_KEY,
  GTV_KEYBOARD_HEIGHT_VP_KEY,
  GTV_KEYBOARD_HEIGHT_PORTRAIT_VP_KEY,
  GTV_KEYBOARD_HEIGHT_LANDSCAPE_VP_KEY,
  GTV_KEY_SOUND_VOLUME_KEY,
  GTV_VIBRATION_STRENGTH_KEY,
  DEFAULT_KEY_SIZE_LABEL,
  DEFAULT_SOUND_ENABLED,
  DEFAULT_VIBRATION_ENABLED,
  DEFAULT_CLIPBOARD_ENABLED,
  DEFAULT_SUGGESTION_ENABLED,
  DEFAULT_AUTO_CAPITALIZE,
  DEFAULT_AUTO_SPACE_PUNCTUATION,
  DEFAULT_KEY_POPUP_PREVIEW,
  DEFAULT_KEYBOARD_HEIGHT_VP,
  DEFAULT_KEYBOARD_HEIGHT_PORTRAIT_VP,
  DEFAULT_KEYBOARD_HEIGHT_LANDSCAPE_VP,
  DEFAULT_KEY_SOUND_VOLUME,
  DEFAULT_VIBRATION_STRENGTH,
  GTV_LONG_PRESS_ENABLED_KEY,
  GTV_SWIPE_SPACE_ENABLED_KEY,
  GTV_TRANSLATION_ENABLED_KEY,
  GTV_AUTOCORRECT_ENABLED_KEY,
  GTV_SHORTHAND_ENABLED_KEY,
  GTV_BACKGROUND_IMAGE_KEY,
  DEFAULT_LONG_PRESS_ENABLED,
  DEFAULT_SWIPE_SPACE_ENABLED,
  DEFAULT_TRANSLATION_ENABLED,
  DEFAULT_AUTOCORRECT_ENABLED,
  DEFAULT_SHORTHAND_ENABLED,
  DEFAULT_BACKGROUND_IMAGE
} from '../telex/core/KeyboardSettingsKeys';
const GTV_BUNDLE_NAME = 'com.example.gotiengviet';
const GTV_SETTINGS_CHANGED_EVENT = 'com.example.gotiengviet.SETTINGS_CHANGED';
const APP_DETAILS_ACTION = 'ohos.settings.application.details';
const MANAGE_APPLICATIONS_ACTION = 'ohos.settings.manage.applications';
const PERMISSION_VOICE: Permissions[] = ['ohos.permission.MICROPHONE'];
const PERMISSION_MEDIA: Permissions[] = ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.READ_AUDIO'];
const PERMISSION_FILE: Permissions[] = ['ohos.permission.READ_DOCUMENT'];
const PERMISSION_NETWORK: Permissions[] = ['ohos.permission.INTERNET'];
const PERMISSION_STARTUP: Permissions[] = ['ohos.permission.RECEIVER_STARTUP_COMPLETED'];

// Khai báo interface rõ ràng (ArkTS yêu cầu)
interface GuideRow {
  key: string;
  result: string;
  example: string;
}

interface FeatureEntry {
  id: string;
  title: string;
  subtitle: string;
  icon: string;
}

@Entry
@Component
struct SettingsPage {
  @State inputMethodEnabled: boolean = false;
  @State autocorrect: boolean = true;
  @State sound: boolean = false;
  @State vibration: boolean = true;
  @State selectedTab: number = 0;
  @State showGuideDialog: boolean = false;
  @State openedFeature: string = 'appearance';
  @State permissionVoice: boolean = false;
  @State permissionMedia: boolean = false;
  @State permissionFile: boolean = false;
  @State permissionNetwork: boolean = true;
  @State permissionStartup: boolean = false;
  @State backgroundOpacity: number = DEFAULT_KEYBOARD_OPACITY;
  @State keyOpacity: number = DEFAULT_KEYBOARD_KEY_OPACITY;
  @State numberRowEnabled: boolean = true;
  @State darkMode: boolean = DEFAULT_KEYBOARD_DARK_MODE;
  @State uppercaseLabels: boolean = false;
  @State fontSizeValue: number = 16;
  @State bgBaseColor: string = DEFAULT_KEYBOARD_BG_COLOR;
  @State keyBaseColor: string = DEFAULT_KEYBOARD_KEY_COLOR;
  @State textBaseColor: string = DEFAULT_KEYBOARD_TEXT_COLOR;
  @State draftBackgroundOpacity: number = DEFAULT_KEYBOARD_OPACITY;
  @State draftKeyOpacity: number = DEFAULT_KEYBOARD_KEY_OPACITY;
  @State draftBgBaseColor: string = DEFAULT_KEYBOARD_BG_COLOR;
  @State draftKeyBaseColor: string = DEFAULT_KEYBOARD_KEY_COLOR;
  @State draftDarkMode: boolean = DEFAULT_KEYBOARD_DARK_MODE;
  @State appearanceSavedMessage: string = '';
  @State fontWeightLevel: string = 'Vừa';
  @State keyboardWindowHeight: number = DEFAULT_KEYBOARD_HEIGHT_VP;
  @State keyboardPortraitHeight: number = DEFAULT_KEYBOARD_HEIGHT_PORTRAIT_VP;
  @State keyboardLandscapeHeight: number = DEFAULT_KEYBOARD_HEIGHT_LANDSCAPE_VP;
  @State resizableKeyboard: boolean = true;
  @State enterToSend: boolean = false;
  @State autoCapitalize: boolean = true;
  @State autoSpaceAfterPunctuation: boolean = true;
  @State textSuggestion: boolean = true;
  @State translateEnabled: boolean = false;
  @State clipboardDailyStore: boolean = false;
  @State clipboardKeepHours: string = '3 tiếng';
  @State keySoundVolume: number = 45;
  @State keySoundType: string = 'Mặc định';
  @State vibrationStrength: number = 2;
  @State keyPopupPreview: boolean = true;
  @State longPressDelay: number = 350;
  @State voiceInputEnabled: boolean = false;
  @State voiceModel: string = 'Nhẹ';
  @State stickerGifEnabled: boolean = true;
  @State inputLanguageIndex: number = 0;
  @State showDevelopingPopup: boolean = false;
  @State developingFeature: string = '';
  @State keyboardPreviewWidthPercent: number = 94;
  @State resizeStartHeight: number = 280;
  @State resizeStartWidthPercent: number = 94;
  @State longPressEnabled: boolean = true;
  @State swipeSpaceEnabled: boolean = true;
  @State shorthandEnabled: boolean = false;
  @State bgImage: string = '';

  // Theme colors
  private bg: string = '#0A0A1E';
  private cardBg: string = '#12122A';
  private accentColor: string = '#E94560';
  private isLandscapeOrientation: boolean = false;
  private accentLight: string = '#FF6B80';
  private textPrimary: string = '#EAEAEA';
  private textSecondary: string = '#8888AA';
  private divider: string = '#1E1E3A';

  private detectOrientation(): void {
    try {
      const d = display.getDefaultDisplaySync();
      this.isLandscapeOrientation = d.width > d.height;
    } catch (_) {
      this.isLandscapeOrientation = false;
    }
  }

  private getHeightSettingKey(): string {
    return this.isLandscapeOrientation ? GTV_KEYBOARD_HEIGHT_LANDSCAPE_VP_KEY : GTV_KEYBOARD_HEIGHT_PORTRAIT_VP_KEY;
  }

  private async loadCurrentKeyboardHeight(): Promise<number> {
    const fallbackHeight = await PreferencesManager.get(GTV_KEYBOARD_HEIGHT_VP_KEY, DEFAULT_KEYBOARD_HEIGHT_VP) as number;
    const savedHeight = await PreferencesManager.get(this.getHeightSettingKey(), fallbackHeight) as number;
    const parsedHeight = typeof savedHeight === 'number' ? savedHeight : fallbackHeight;
    return Math.round(Math.min(420, Math.max(180, Number(parsedHeight) || DEFAULT_KEYBOARD_HEIGHT_VP)));
  }

  aboutToAppear(): void {
    this.detectOrientation();
    this.checkInputMethodStatus();
    this.refreshPermissionStatus();
    PreferencesManager.init(getContext(this)).then(() => {
      this.loadSettings();
    });
  }

  async loadSettings() {
    this.backgroundOpacity = await PreferencesManager.get(GTV_BG_OPACITY_KEY, DEFAULT_KEYBOARD_OPACITY) as number;
    this.keyOpacity = await PreferencesManager.get(GTV_KEY_OPACITY_KEY, DEFAULT_KEYBOARD_KEY_OPACITY) as number;
    this.numberRowEnabled = await PreferencesManager.get(GTV_SHOW_NUMBER_ROW_KEY, true) as boolean;
    this.bgBaseColor = await PreferencesManager.get(GTV_BG_COLOR_KEY, DEFAULT_KEYBOARD_BG_COLOR) as string;
    this.keyBaseColor = await PreferencesManager.get(GTV_KEY_COLOR_KEY, DEFAULT_KEYBOARD_KEY_COLOR) as string;
    this.textBaseColor = await PreferencesManager.get(GTV_TEXT_COLOR_KEY, DEFAULT_KEYBOARD_TEXT_COLOR) as string;
    this.darkMode = await PreferencesManager.get(GTV_DARK_MODE_KEY, DEFAULT_KEYBOARD_DARK_MODE) as boolean;

    this.detectOrientation();
    const fallbackLegacy = await PreferencesManager.get(GTV_KEYBOARD_HEIGHT_VP_KEY, DEFAULT_KEYBOARD_HEIGHT_VP) as number;
    this.keyboardPortraitHeight = await PreferencesManager.get(GTV_KEYBOARD_HEIGHT_PORTRAIT_VP_KEY, fallbackLegacy) as number;
    this.keyboardLandscapeHeight = await PreferencesManager.get(GTV_KEYBOARD_HEIGHT_LANDSCAPE_VP_KEY, fallbackLegacy) as number;
    this.keyboardWindowHeight = this.isLandscapeOrientation ? this.keyboardLandscapeHeight : this.keyboardPortraitHeight;

    this.sound = await PreferencesManager.get(GTV_SOUND_ENABLED_KEY, DEFAULT_SOUND_ENABLED) as boolean;
    this.vibration = await PreferencesManager.get(GTV_VIBRATION_ENABLED_KEY, DEFAULT_VIBRATION_ENABLED) as boolean;
    this.clipboardDailyStore = await PreferencesManager.get(GTV_CLIPBOARD_ENABLED_KEY, DEFAULT_CLIPBOARD_ENABLED) as boolean;
    this.textSuggestion = await PreferencesManager.get(GTV_SUGGESTION_ENABLED_KEY, DEFAULT_SUGGESTION_ENABLED) as boolean;

    this.autoCapitalize = await PreferencesManager.get(GTV_AUTO_CAPITALIZE_KEY, DEFAULT_AUTO_CAPITALIZE) as boolean;
    this.autoSpaceAfterPunctuation = await PreferencesManager.get(GTV_AUTO_SPACE_PUNCTUATION_KEY, DEFAULT_AUTO_SPACE_PUNCTUATION) as boolean;
    this.keyPopupPreview = await PreferencesManager.get(GTV_KEY_POPUP_PREVIEW_KEY, DEFAULT_KEY_POPUP_PREVIEW) as boolean;

    this.keySoundVolume = await PreferencesManager.get(GTV_KEY_SOUND_VOLUME_KEY, DEFAULT_KEY_SOUND_VOLUME) as number;
    this.vibrationStrength = await PreferencesManager.get(GTV_VIBRATION_STRENGTH_KEY, DEFAULT_VIBRATION_STRENGTH) as number;
    this.longPressEnabled = await PreferencesManager.get(GTV_LONG_PRESS_ENABLED_KEY, DEFAULT_LONG_PRESS_ENABLED) as boolean;
    this.swipeSpaceEnabled = await PreferencesManager.get(GTV_SWIPE_SPACE_ENABLED_KEY, DEFAULT_SWIPE_SPACE_ENABLED) as boolean;
    this.translateEnabled = await PreferencesManager.get(GTV_TRANSLATION_ENABLED_KEY, DEFAULT_TRANSLATION_ENABLED) as boolean;
    this.autocorrect = await PreferencesManager.get(GTV_AUTOCORRECT_ENABLED_KEY, DEFAULT_AUTOCORRECT_ENABLED) as boolean;
    this.shorthandEnabled = await PreferencesManager.get(GTV_SHORTHAND_ENABLED_KEY, DEFAULT_SHORTHAND_ENABLED) as boolean;
    this.bgImage = await PreferencesManager.get(GTV_BACKGROUND_IMAGE_KEY, DEFAULT_BACKGROUND_IMAGE) as string;

    this.syncAppearanceDrafts();
  }

  async saveSetting(key: string, value: preferences.ValueType, notifyKeyboard: boolean = true): Promise<void> {
    await PreferencesManager.set(key, value);
    this.notifyKeyboardSettingsChanged();
    AppStorage.setOrCreate(key, value);
    if (notifyKeyboard) {
      this.notifyKeyboardSettingsChanged();
    }
  }

  private notifyKeyboardSettingsChanged(): void {
    let payload = JSON.stringify({
      backgroundOpacity: this.backgroundOpacity,
      keyOpacity: this.keyOpacity,
      bgBaseColor: this.bgBaseColor,
      keyBaseColor: this.keyBaseColor,
      textBaseColor: this.textBaseColor,
      darkMode: this.darkMode,
      keyboardPortraitHeightVp: this.keyboardPortraitHeight,
      keyboardLandscapeHeightVp: this.keyboardLandscapeHeight,
      sound: this.sound,
      vibration: this.vibration,
      clipboardDailyStore: this.clipboardDailyStore,
      numberRowEnabled: this.numberRowEnabled,
      longPressEnabled: this.longPressEnabled,
      swipeSpaceEnabled: this.swipeSpaceEnabled,
      translateEnabled: this.translateEnabled,
      autocorrect: this.autocorrect,
      shorthandEnabled: this.shorthandEnabled,
      backgroundImage: this.bgImage
    });

    commonEventManager.publish(GTV_SETTINGS_CHANGED_EVENT, {
      data: payload
    }, () =>{});
  }

  syncAppearanceDrafts(): void {
    this.draftBackgroundOpacity = this.backgroundOpacity;
    this.draftKeyOpacity = this.keyOpacity;
    this.draftBgBaseColor = this.bgBaseColor;
    this.draftKeyBaseColor = this.keyBaseColor;
    this.draftDarkMode = this.darkMode;
  }

  async applyAppearanceSettings(): Promise<void> {
    this.backgroundOpacity = this.draftBackgroundOpacity;
    this.keyOpacity = this.draftKeyOpacity;
    this.bgBaseColor = this.draftBgBaseColor;
    this.keyBaseColor = this.draftKeyBaseColor;
    this.darkMode = this.draftDarkMode;
    await this.saveSetting(GTV_BG_OPACITY_KEY, this.backgroundOpacity, false);
    await this.saveSetting(GTV_KEY_OPACITY_KEY, this.keyOpacity, false);
    await this.saveSetting(GTV_BG_COLOR_KEY, this.bgBaseColor, false);
    await this.saveSetting(GTV_KEY_COLOR_KEY, this.keyBaseColor, false);
    await this.saveSetting(GTV_TEXT_COLOR_KEY, this.textBaseColor, false);
    await this.saveSetting(GTV_DARK_MODE_KEY, this.darkMode, false);
    this.notifyKeyboardSettingsChanged();
    this.appearanceSavedMessage = 'Đã lưu và áp dụng giao diện';
  }

  applyThemePreset(preset: KeyboardThemePreset): void {
    this.draftBgBaseColor = preset.bgColor;
    this.draftKeyBaseColor = preset.keyColor;
    this.textBaseColor = preset.textColor || "";
    
    this.draftBackgroundOpacity = preset.bgOpacity;
    this.draftKeyOpacity = preset.keyOpacity;
    this.draftDarkMode = preset.darkMode;
    this.appearanceSavedMessage = '';
  }

  isDraftThemePreset(preset: KeyboardThemePreset): boolean {
    return this.draftBgBaseColor === preset.bgColor &&
      this.draftKeyBaseColor === preset.keyColor &&
      this.draftBackgroundOpacity === preset.bgOpacity &&
      this.draftKeyOpacity === preset.keyOpacity &&
      this.draftDarkMode === preset.darkMode;
  }

  getKeyTextColor(color: string): string {
    return getKeyboardTextColor(color);
  }

  onPageShow(): void {
    this.refreshPermissionStatus();
    PreferencesManager.init(getContext(this), true).then(() => {
      this.loadSettings();
    });
  }

  async checkInputMethodStatus(): Promise<void> {
    this.inputMethodEnabled = false; // Cannot reliably check in this API without system permissions
  }

  openInputMethodSettings(): void {
    // API 23 yêu cầu InputMethodProperty object và có thể yêu cầu quyền system.
    // Mở trực tiếp Settings của hệ thống để user bật thủ công là an toàn nhất.
    this.openSettingsFallback();
  }

  async openSettingsFallback(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    const settingsAttempts: Want[] = [
      {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
      } as Want,
      {
        bundleName: 'com.huawei.settings',
        abilityName: 'com.huawei.settings.MainAbility',
      } as Want,
      {
        action: 'action.settings.INPUT_METHOD_SETTINGS',
      } as Want
    ];

    for (const want of settingsAttempts) {
      try {
        await ctx.startAbility(want);
        break; // Dừng lại nếu mở thành công
      } catch (e) {
        // Tiếp tục thử cái tiếp theo
      }
    }

    // Luôn hiện dialog hướng dẫn thủ công
    this.showGuideDialog = true;
  }

  async openAppPermissionSettings(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    const bundleName = ctx.abilityInfo.bundleName.length > 0 ? ctx.abilityInfo.bundleName : GTV_BUNDLE_NAME;
    const settingsAttempts: Want[] = [
      {
        action: APP_DETAILS_ACTION,
        parameters: {
          'packageName': bundleName,
          'bundleName': bundleName,
          'package': bundleName
        }
      } as Want,
      {
        action: APP_DETAILS_ACTION,
        uri: 'package:' + bundleName
      } as Want,
      {
        action: MANAGE_APPLICATIONS_ACTION
      } as Want,
      {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility'
      } as Want,
      {
        bundleName: 'com.huawei.settings',
        abilityName: 'com.huawei.settings.MainAbility'
      } as Want
    ];

    for (const want of settingsAttempts) {
      try {
        await ctx.startAbility(want);
        return;
      } catch (e) {
        // Tiếp tục thử đích cài đặt kế tiếp
      }
    }
  }

  async refreshPermissionStatus(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const tokenId = ctx.applicationInfo.accessTokenId;
      this.permissionVoice = await this.hasAllPermissions(tokenId, PERMISSION_VOICE);
      this.permissionMedia = await this.hasAllPermissions(tokenId, PERMISSION_MEDIA);
      this.permissionFile = await this.hasAllPermissions(tokenId, PERMISSION_FILE);
      this.permissionNetwork = await this.hasAllPermissions(tokenId, PERMISSION_NETWORK);
      this.permissionStartup = await this.hasAllPermissions(tokenId, PERMISSION_STARTUP);
    } catch (e) {
      this.permissionVoice = false;
      this.permissionMedia = false;
      this.permissionFile = false;
      this.permissionNetwork = false;
      this.permissionStartup = false;
    }
  }

  async hasAllPermissions(tokenId: number, permissions: Permissions[]): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    for (const permissionName of permissions) {
      try {
        const status = await atManager.checkAccessToken(tokenId, permissionName);
        if (status !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  showDeveloping(feature: string): void {
    this.openedFeature = '';
    this.developingFeature = feature;
    this.showDevelopingPopup = true;
  }

  closeDevelopingPopup(): void {
    this.showDevelopingPopup = false;
  }

  beginKeyboardResize(): void {
    this.resizeStartHeight = this.keyboardWindowHeight;
    this.resizeStartWidthPercent = this.keyboardPreviewWidthPercent;
  }

  clampNumber(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  updateKeyboardResize(handle: string, offsetX: number, offsetY: number): void {
    let nextHeight = this.resizeStartHeight;
    let nextWidth = this.resizeStartWidthPercent;
    if (handle.indexOf('top') >= 0) {
      nextHeight = this.resizeStartHeight - Math.round(offsetY * 2);
    }
    if (handle.indexOf('bottom') >= 0) {
      nextHeight = this.resizeStartHeight + Math.round(offsetY * 2);
    }
    if (handle.indexOf('left') >= 0) {
      nextWidth = this.resizeStartWidthPercent - Math.round(offsetX / 3);
    }
    if (handle.indexOf('right') >= 0) {
      nextWidth = this.resizeStartWidthPercent + Math.round(offsetX / 3);
    }

    this.keyboardWindowHeight = Math.round(this.clampNumber(nextHeight, 180, 420));
    this.keyboardPreviewWidthPercent = Math.round(this.clampNumber(nextWidth, 72, 100));
  }

  getKeyboardPreviewHeight(): number {
    return Math.round(this.clampNumber(this.keyboardWindowHeight * 0.38, 78, 160));
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // === Main content ===
      Column() {
        this.buildHeader()
        this.buildTabBar()
        Scroll() {
          Column() {
            if (this.selectedTab === 0) {
          Scroll() {
            this.buildMainSettings()
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else if (this.selectedTab === 1) {
              this.buildGuide()
            } else {
              this.buildAbout()
            }
          }
          .width('100%')
          .padding({ bottom: 40 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
        .height('100%')
        .backgroundColor(this.bg)

      if (this.showDevelopingPopup) {
        this.buildDevelopingPopup()
      }

      // === Dialog hướng dẫn kích hoạt thủ công ===
      if (this.showGuideDialog) {
        Column() {
          Column() {
            Text('📋 Cách kích hoạt bàn phím')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#EAEAEA')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 16 })

            Text('1️⃣  Vào Cài đặt máy')
              .fontSize(14).fontColor('#CCCCEE').width('100%').padding({ bottom: 8 })
            Text('2️⃣  Tìm "Ngôn ngữ & nhập liệu"')
              .fontSize(14).fontColor('#CCCCEE').width('100%').padding({ bottom: 8 })
            Text('3️⃣  Chọn "Bàn phím & phương thức nhập"')
              .fontSize(14).fontColor('#CCCCEE').width('100%').padding({ bottom: 8 })
            Text('4️⃣  Bật GoTiếngViệt trong danh sách')
              .fontSize(14).fontColor('#CCCCEE').width('100%').padding({ bottom: 8 })
            Text('5️⃣  Chọn làm bàn phím mặc định')
              .fontSize(14).fontColor('#CCCCEE').width('100%').padding({ bottom: 16 })

            Text('💡 Gợi ý: Cài đặt → Hệ thống → Ngôn ngữ & phương pháp nhập → Bàn phím mặc định')
              .fontSize(12)
              .fontColor('#8888AA')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 20 })

            Button('Đã hiểu')
              .width('100%')
              .height(44)
              .backgroundColor('#E94560')
              .fontColor(Color.White)
              .borderRadius(22)
              .onClick(() => {
                this.showGuideDialog = false;
                this.checkInputMethodStatus();
              })
          }
          .width('88%')
          .backgroundColor('#1A1A38')
          .borderRadius(20)
          .padding(24)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000AA')
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.showGuideDialog = false; })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildDevelopingPopup() {
    Column() {
      Column() {
        Text('Đang phát triển')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })
        Text(this.developingFeature.length > 0 ? this.developingFeature : 'Chức năng')
          .fontSize(13)
          .fontColor(this.textSecondary)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 18 })
        Button('Đóng')
          .width('100%')
          .height(40)
          .fontColor(Color.White)
          .backgroundColor(this.accentColor)
          .borderRadius(20)
          .onClick(() => {
            this.closeDevelopingPopup();
          })
      }
      .width('78%')
      .backgroundColor('#1A1A38')
      .borderRadius(18)
      .padding(22)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000AA')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.closeDevelopingPopup();
    })
  }

  @Builder
  buildHeader() {
    Column() {
      Row() {
        // Logo / Icon
        Column() {
          Text('🇻🇳')
            .fontSize(36)
        }
        .width(60)
        .height(60)
        .borderRadius(16)
        .backgroundColor('#1A1040')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 16 })

        Column() {
          Text('GoTiếngViệt')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)

          Text('Bàn phím tiếng Việt thông minh')
            .fontSize(13)
            .fontColor(this.textSecondary)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .padding({ top: 50, bottom: 20, left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)

      // Kích hoạt button
      Button() {
        Text(this.inputMethodEnabled ? '✓ Đã kích hoạt' : '⚡ Kích hoạt bàn phím')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width('90%')
      .height(50)
      .backgroundColor(this.inputMethodEnabled ? '#1A6A40' : this.accentColor)
      .borderRadius(25)
      .margin({ bottom: 20 })
      .onClick(() => {
        this.openInputMethodSettings();
      })
    }
    .width('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#0A0A1E' as ResourceColor, 0.0], ['#12082A' as ResourceColor, 1.0]]
    })
  }

  @Builder
  buildTabBar() {
    Row() {
      this.buildTab('⚙️ Cài đặt', 0)
      this.buildTab('📖 Hướng dẫn', 1)
      this.buildTab('ℹ️ Về app', 2)
    }
    .width('100%')
    .height(48)
    .backgroundColor(this.cardBg)
    .border({ width: { bottom: 1 }, color: this.divider })
  }

  @Builder
  buildTab(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor(this.selectedTab === index ? this.accentColor : this.textSecondary)
        .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)

      if (this.selectedTab === index) {
        Divider()
          .width(40)
          .height(2)
          .color(this.accentColor)
          .margin({ top: 4 })
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.selectedTab = index; })
  }


  getDemoKeyScale(): number {
    if (this.fontWeightLevel === 'Nhỏ') return 0.88;
    if (this.fontWeightLevel === 'Lớn') return 1.14;
    return 1.0;
  }
  
  getDemoKeyHeight(): number {
    return 40 * (this.keyboardWindowHeight / 260) * this.getDemoKeyScale();
  }
  
  getDemoKeyFontSize(baseSize: number): number {
    return baseSize * this.getDemoKeyScale();
  }

  @Builder
  buildDemoKeyboard() {
    Column() {
      Row() {
        ForEach(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'], (key: string) => {
          Text(key)
            .layoutWeight(1)
            .height(this.getDemoKeyHeight())
            .margin(2)
            .backgroundColor(this.keyBaseColor)
            .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
            .fontSize(this.getDemoKeyFontSize(16))
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        })
      }.width('100%').padding({ left: 2, right: 2 })
      
      Row() {
        ForEach(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'], (key: string) => {
          Text(key)
            .layoutWeight(1)
            .height(this.getDemoKeyHeight())
            .margin(2)
            .backgroundColor(this.keyBaseColor)
            .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
            .fontSize(this.getDemoKeyFontSize(16))
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        })
      }.width('90%').padding({ left: 2, right: 2 })
      
      Row() {
        Text('⇧')
          .width(45)
          .height(this.getDemoKeyHeight())
          .margin(2)
          .backgroundColor(this.darkMode ? '#3D3D3D' : '#B0B4C0')
          .fontColor(this.darkMode ? '#FFFFFF' : '#000000')
          .fontSize(this.getDemoKeyFontSize(16))
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          
        ForEach(['Z', 'X', 'C', 'V', 'B', 'N', 'M'], (key: string) => {
          Text(key)
            .layoutWeight(1)
            .height(this.getDemoKeyHeight())
            .margin(2)
            .backgroundColor(this.keyBaseColor)
            .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
            .fontSize(this.getDemoKeyFontSize(16))
            .textAlign(TextAlign.Center)
            .borderRadius(4)
        })
        
        Text('⌫')
          .width(45)
          .height(this.getDemoKeyHeight())
          .margin(2)
          .backgroundColor(this.darkMode ? '#3D3D3D' : '#B0B4C0')
          .fontColor(this.darkMode ? '#FFFFFF' : '#000000')
          .fontSize(this.getDemoKeyFontSize(16))
          .textAlign(TextAlign.Center)
          .borderRadius(4)
      }.width('100%').padding({ left: 2, right: 2 })
      
      Row() {
        Text('?123')
          .layoutWeight(1)
          .height(this.getDemoKeyHeight())
          .margin(2)
          .backgroundColor(this.darkMode ? '#3D3D3D' : '#B0B4C0')
          .fontColor(this.darkMode ? '#FFFFFF' : '#000000')
          .fontSize(this.getDemoKeyFontSize(14))
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          
        Text('GoTiengViet')
          .layoutWeight(4)
          .height(this.getDemoKeyHeight())
          .margin(2)
          .backgroundColor(this.keyBaseColor)
          .fontColor(this.textBaseColor ? this.textBaseColor : this.getKeyTextColor(this.keyBaseColor))
          .fontSize(this.getDemoKeyFontSize(14))
          .textAlign(TextAlign.Center)
          .borderRadius(4)
          
        Text('⏎')
          .layoutWeight(1)
          .height(this.getDemoKeyHeight())
          .margin(2)
          .backgroundColor('#4A90D9')
          .fontColor('#FFFFFF')
          .fontSize(this.getDemoKeyFontSize(16))
          .textAlign(TextAlign.Center)
          .borderRadius(4)
      }.width('100%').padding({ left: 2, right: 2 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(this.bgBaseColor)
    .borderRadius(8)
    .margin({ top: 10, bottom: 10 })
    .opacity(this.backgroundOpacity / 100)
  }

  @Builder
  buildMainSettings() {
    Column() {
      // 1. Quản lý giao diện
      this.buildSectionTitle('Quản lý giao diện')
      Column() {
        TextInput({ placeholder: 'Gõ thử bàn phím...' })
          .width('90%')
          .height(40)
          .margin({ top: 10, bottom: 10 })
          .backgroundColor('#202040')
          .fontColor(this.textPrimary)
          .placeholderColor(this.textSecondary)
        
        this.buildDemoKeyboard()
        this.buildToggleRow('Chế độ Tối / Sáng', '◐', this.darkMode, (val: boolean) => {
          this.darkMode = val;
          this.saveSetting(GTV_DARK_MODE_KEY, val);
        })
        
        Text('Màu nền').fontSize(14).fontColor(this.textPrimary).width('100%').padding({ left: 20, top: 8, bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .margin(6)
                .border({ width: this.bgBaseColor === color ? 3 : 0, color: '#4FC3F7' })
                .onClick(() => {
                  this.bgBaseColor = color;
                  this.saveSetting(GTV_BG_COLOR_KEY, color);
                })
            })
          }.width('100%').padding({ left: 14, right: 14 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

        Text('Màu phím').fontSize(14).fontColor(this.textPrimary).width('100%').padding({ left: 20, top: 8, bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .margin(6)
                .border({ width: this.keyBaseColor === color ? 3 : 0, color: '#4FC3F7' })
                .onClick(() => {
                  this.keyBaseColor = color;
                  this.saveSetting(GTV_KEY_COLOR_KEY, color);
                })
            })
          }.width('100%').padding({ left: 14, right: 14 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)


        Text('Màu chữ phím').fontSize(14).fontColor(this.textPrimary).width('100%').padding({ left: 20, top: 8, bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .margin(6)
                .border({ width: this.textBaseColor === color ? 3 : 0, color: '#4FC3F7' })
                .onClick(() => {
                  this.textBaseColor = color;
                  this.saveSetting(GTV_TEXT_COLOR_KEY, color);
                })
            })
          }.width('100%').padding({ left: 14, right: 14 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

        this.buildActionRow('Chọn hình nền', 'Chưa có hình nền', () => {
          this.showDeveloping('Chọn hình nền (làm sau)');
        })

        this.buildSliderSetting('Độ trong suốt nền', `${this.backgroundOpacity}%`, this.backgroundOpacity, 10, 100, 1, (value: number) => {
          this.backgroundOpacity = Math.round(value);
          this.saveSetting(GTV_BG_OPACITY_KEY, this.backgroundOpacity);
        })
        
        this.buildSliderSetting('Độ trong suốt phím', `${this.keyOpacity}%`, this.keyOpacity, 10, 100, 1, (value: number) => {
          this.keyOpacity = Math.round(value);
          this.saveSetting(GTV_KEY_OPACITY_KEY, this.keyOpacity);
        })

        this.buildSliderSetting(this.isLandscapeOrientation ? 'Chiều cao chữ (ngang)' : 'Chiều cao chữ (dọc)', `${this.keyboardWindowHeight}vp`, this.keyboardWindowHeight, 180, 450, 5, (value: number) => {
          const nextHeight = Math.round(value);
          this.keyboardWindowHeight = nextHeight;
          if (this.isLandscapeOrientation) {
            this.keyboardLandscapeHeight = nextHeight;
            this.saveSetting(GTV_KEYBOARD_HEIGHT_LANDSCAPE_VP_KEY, nextHeight);
          } else {
            this.keyboardPortraitHeight = nextHeight;
            this.saveSetting(GTV_KEYBOARD_HEIGHT_PORTRAIT_VP_KEY, nextHeight);
          }
        })
        this.buildSettingNote('Chiều cao trên là chiều cao cơ bản (5 hàng). Bật hàng số sẽ tự động cộng thêm chiều cao 1 hàng để phím chữ không lùn đi.')
        
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .clip(true)
      .margin({ bottom: 20 })

      // 2. Quản lý nhập liệu
      this.buildSectionTitle('Quản lý nhập liệu')
      Column() {
        this.buildToggleRow('Bật hàng phím số', '123', this.numberRowEnabled, (val: boolean) => {
          this.numberRowEnabled = val;
          this.saveSetting(GTV_SHOW_NUMBER_ROW_KEY, val);
        })

        this.buildToggleRow('Clipboard', '📋', this.clipboardDailyStore, (val: boolean) => {
          this.clipboardDailyStore = val;
          this.saveSetting(GTV_CLIPBOARD_ENABLED_KEY, val);
        })

        this.buildToggleRow('Long-press', '⏱️', this.longPressEnabled, (val: boolean) => {
          this.longPressEnabled = val;
          this.saveSetting(GTV_LONG_PRESS_ENABLED_KEY, val);
        })

        this.buildToggleRow('Gợi ý từ (Candidate)', '💡', this.textSuggestion, (val: boolean) => {
          this.textSuggestion = val;
          this.saveSetting(GTV_SUGGESTION_ENABLED_KEY, val);
        })

        this.buildToggleRow('Vuốt phím cách để di con trỏ', '↔️', this.swipeSpaceEnabled, (val: boolean) => {
          this.swipeSpaceEnabled = val;
          this.saveSetting(GTV_SWIPE_SPACE_ENABLED_KEY, val);
        })

        this.buildToggleRow('Viết hoa chữ cái đầu (làm sau)', '🔠', this.autoCapitalize, (val: boolean) => {
          this.autoCapitalize = val;
          this.saveSetting(GTV_AUTO_CAPITALIZE_KEY, val);
        })

        this.buildToggleRow('Âm thanh khi ấn phím (làm sau)', '🔊', this.sound, (val: boolean) => {
          this.sound = val;
          this.saveSetting(GTV_SOUND_ENABLED_KEY, val);
        })

        this.buildToggleRow('Rung khi ấn phím (làm sau)', '📳', this.vibration, (val: boolean) => {
          this.vibration = val;
          this.saveSetting(GTV_VIBRATION_ENABLED_KEY, val);
        })

        this.buildToggleRow('Popup khi ấn phím (làm sau)', '💬', this.keyPopupPreview, (val: boolean) => {
          this.keyPopupPreview = val;
          this.saveSetting(GTV_KEY_POPUP_PREVIEW_KEY, val);
        })

        this.buildToggleRow('Dịch ngôn ngữ (làm sau)', '🌐', this.translateEnabled, (val: boolean) => {
          this.translateEnabled = val;
          this.saveSetting(GTV_TRANSLATION_ENABLED_KEY, val);
        })

        this.buildToggleRow('Tự động sửa lỗi', '✏️', this.autocorrect, (val: boolean) => {
          this.autocorrect = val;
          this.saveSetting(GTV_AUTOCORRECT_ENABLED_KEY, val);
        })
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .clip(true)
      .margin({ bottom: 20 })

      // 3. Quản lý ngôn ngữ
      this.buildSectionTitle('Quản lý ngôn ngữ')
      Column() {
        this.buildActionRow('Ngôn ngữ (làm sau)', 'Tiếng Việt', () => {
          this.showDeveloping('Chọn ngôn ngữ');
        })
        this.buildChoiceRow('Kiểu gõ (làm sau)', ['Telex', 'VNI'], 'Telex', (value: string) => {
          this.showDeveloping('Chọn kiểu gõ: ' + value);
        })
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .clip(true)
      .margin({ bottom: 20 })

      // 4. Quản lý từ điển
      this.buildSectionTitle('Quản lý từ điển')
      Column() {
        this.buildToggleRow('Bật tắt nhập tắt (làm sau)', '⚡', this.shorthandEnabled, (val: boolean) => {
          this.shorthandEnabled = val;
          this.saveSetting(GTV_SHORTHAND_ENABLED_KEY, val);
        })
        this.buildActionRow('Danh sách từ viết tắt (làm sau)', '0 từ', () => {
          this.showDeveloping('Quản lý danh sách viết tắt');
        })
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .clip(true)
      .margin({ bottom: 20 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 16 })
  }

  @Builder
  buildSliderSetting(label: string, valueLabel: string, value: number, min: number, max: number, step: number,
    onChange: (value: number) => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor(this.textPrimary)
          .layoutWeight(1)
        Text(valueLabel)
          .fontSize(12)
          .fontColor(this.accentLight)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      Slider({ value: value, min: min, max: max, step: step, style: SliderStyle.OutSet })
        .width('100%')
        .selectedColor(this.accentColor)
        .trackColor('#25254A')
        .blockColor('#FFFFFF')
        .onChange((sliderValue: number, _mode: SliderChangeMode) => {
          onChange(sliderValue);
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 11 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildChoiceRow(label: string, choices: string[], selected: string, onSelect: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(this.textPrimary)
        .width('100%')
        .margin({ bottom: 8 })

      Scroll() {
        Row() {
          ForEach(choices, (choice: string) => {
            this.buildChoiceChip(choice, selected === choice, () => {
              onSelect(choice);
            })
          }, (choice: string) => choice + '_' + (selected === choice).toString())
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 11 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildChoiceChip(label: string, active: boolean, onClick: () => void) {
    Button(label)
      .height(30)
      .fontSize(11)
      .fontColor(active ? Color.White : this.textSecondary)
      .backgroundColor(active ? this.accentColor : '#202040')
      .borderRadius(15)
      .padding({ left: 10, right: 10 })
      .margin({ right: 6, bottom: 6 })
      .onClick(() => {
        onClick();
      })
  }

  @Builder
  buildSavedThemeRow() {
    Column() {
      Text('Giao diện đã lưu')
        .fontSize(14)
        .fontColor(this.textPrimary)
        .width('100%')
        .margin({ bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_THEME_PRESETS, (preset: KeyboardThemePreset) => {
              this.buildChoiceChip(preset.label, this.isDraftThemePreset(preset), () => {
                this.applyThemePreset(preset);
              })
            }, (preset: KeyboardThemePreset) => preset.label + '_' + this.isDraftThemePreset(preset).toString())
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 11 })
  }

  @Builder
  buildInstalledLanguageRow(item: InputLanguageOption, index: number) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(14)
          .fontColor(this.inputLanguageIndex === index ? this.accentLight : this.textPrimary)
          .fontWeight(this.inputLanguageIndex === index ? FontWeight.Bold : FontWeight.Regular)
        Text(item.subtitle)
          .fontSize(11)
          .fontColor(this.textSecondary)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.inputLanguageIndex === index ? 'Đang dùng' : 'Chọn')
        .fontSize(12)
        .fontColor(this.inputLanguageIndex === index ? this.accentLight : this.textSecondary)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.inputLanguageIndex === index ? '#1A1A38' : 'transparent')
    .borderRadius(10)
    .onClick(() => {
      this.inputLanguageIndex = index;
    })
  }

  @Builder
  buildActionRow(title: string, subtitle: string, onClick?: () => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(14)
          .fontColor(this.textPrimary)
        Text(subtitle)
          .fontSize(11)
          .fontColor(this.textSecondary)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(22)
        .fontColor(this.textSecondary)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 11 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (onClick) {
        onClick();
      }
    })
  }

  @Builder
  buildSettingNote(message: string) {
    Text(message)
      .fontSize(11)
      .fontColor(this.textSecondary)
      .lineHeight(16)
      .width('100%')
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
  }

  @Builder
  buildToggleRow(label: string, icon: string, value: boolean, onChange: (val: boolean) => void) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })

      Text(label)
        .fontSize(15)
        .fontColor(this.textPrimary)
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#4FC3F7')
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildSectionTitle(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor(this.textSecondary)
      .fontWeight(FontWeight.Medium)
      .width('90%')
      .padding({ left: 4, bottom: 8 })
      .textCase(TextCase.UpperCase)
  }

  @Builder
  buildGuide() {
    // Dữ liệu guide dưới dạng GuideRow[] với type rõ ràng
    Column() {
      this.buildSectionTitle('Cách gõ TELEX')
      this.buildGuideCard(this.getTelexVowelRows())

      this.buildSectionTitle('Dấu thanh TELEX')
      this.buildGuideCard(this.getTelexToneRows())

      this.buildSectionTitle('Cách gõ VNI')
      this.buildGuideCard(this.getVniRows())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 16, bottom: 20 })
  }

  private getTelexVowelRows(): GuideRow[] {
    const rows: GuideRow[] = [];
    rows.push({ key: 'aa', result: 'â', example: 'baas → bás' });
    rows.push({ key: 'aw', result: 'ă', example: 'bawn → băn' });
    rows.push({ key: 'oo', result: 'ô', example: 'toos → tốt' });
    rows.push({ key: 'ow', result: 'ơ', example: 'cowm → cơm' });
    rows.push({ key: 'uw', result: 'ư', example: 'buwu → bưu' });
    rows.push({ key: 'ee', result: 'ê', example: 'bees → bế' });
    rows.push({ key: 'dd', result: 'đ', example: 'ddof → đồ' });
    return rows;
  }

  private getTelexToneRows(): GuideRow[] {
    const rows: GuideRow[] = [];
    rows.push({ key: 's', result: 'sắc ´', example: 'as → á' });
    rows.push({ key: 'f', result: 'huyền `', example: 'af → à' });
    rows.push({ key: 'r', result: 'hỏi ả', example: 'ar → ả' });
    rows.push({ key: 'x', result: 'ngã ã', example: 'ax → ã' });
    rows.push({ key: 'j', result: 'nặng ạ', example: 'aj → ạ' });
    return rows;
  }

  private getVniRows(): GuideRow[] {
    const rows: GuideRow[] = [];
    rows.push({ key: 'a + 6', result: 'â', example: 'a6 → â' });
    rows.push({ key: 'a + 8', result: 'ă', example: 'a8 → ă' });
    rows.push({ key: 'o + 6', result: 'ô', example: 'o6 → ô' });
    rows.push({ key: 'o + 7', result: 'ơ', example: 'o7 → ơ' });
    rows.push({ key: 'u + 7', result: 'ư', example: 'u9 → ư' });
    rows.push({ key: 'd + 9', result: 'đ', example: 'd0 → đ' });
    rows.push({ key: '1-5', result: 'dấu thanh', example: 'a1→á, a2→à' });
    return rows;
  }

  @Builder
  buildGuideCard(rows: GuideRow[]) {
    Column() {
      Row() {
        Text('Gõ')
          .fontSize(12)
          .fontColor(this.textSecondary)
          .fontWeight(FontWeight.Bold)
          .width('25%')
        Text('Kết quả')
          .fontSize(12)
          .fontColor(this.textSecondary)
          .fontWeight(FontWeight.Bold)
          .width('25%')
        Text('Ví dụ')
          .fontSize(12)
          .fontColor(this.textSecondary)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 8 })
      .backgroundColor('#0A0A20')

      ForEach(rows, (row: GuideRow, idx: number) => {
        Row() {
          Text(row.key)
            .fontSize(14)
            .fontColor(this.accentLight)
            .fontFamily('monospace')
            .width('25%')
          Text(row.result)
            .fontSize(14)
            .fontColor(this.textPrimary)
            .width('25%')
          Text(row.example)
            .fontSize(13)
            .fontColor(this.textSecondary)
            .layoutWeight(1)
        }
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor(idx % 2 === 0 ? 'transparent' : '#0D0D20')
      })
    }
    .width('90%')
    .backgroundColor(this.cardBg)
    .borderRadius(16)
    .clip(true)
    .margin({ bottom: 20 })
  }

  @Builder
  buildAbout() {
    Column() {
      Column() {
        Text('🇻🇳')
          .fontSize(60)
          .margin({ bottom: 12, top: 20 })

        Text('GoTiếngViệt')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textPrimary)

        Text('Phiên bản 1.0.0')
          .fontSize(14)
          .fontColor(this.textSecondary)
          .margin({ top: 6, bottom: 20 })
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 16, bottom: 20 })

      Column() {
        this.buildAboutRow('🎯', 'Mục tiêu', 'Bàn phím tiếng Việt tốt nhất cho HarmonyOS')
        Divider().color(this.divider).margin({ left: 20, right: 20 })
        this.buildAboutRow('⚙️', 'Hệ thống', 'HarmonyOS 6.1 (API 23)')
        Divider().color(this.divider).margin({ left: 20, right: 20 })
        this.buildAboutRow('💡', 'Phương pháp', 'Telex, VNI, English')
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .margin({ bottom: 20 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildAboutRow(icon: string, label: string, value: string) {
    Row() {
      Text(icon)
        .fontSize(18)
        .margin({ right: 12 })
      Column() {
        Text(label)
          .fontSize(13)
          .fontColor(this.textSecondary)
        Text(value)
          .fontSize(14)
          .fontColor(this.textPrimary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
  }
}
