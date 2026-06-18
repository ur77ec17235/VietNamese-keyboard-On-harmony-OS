/**
 * Index.ets - Settings Page của GoTiếngViệt
 * Giao diện cài đặt đẹp với dark theme
 */

import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import preferences from '@ohos.data.preferences';
import { KeyboardBridge } from '../telex/service/KeyboardBridge';
import { InputLanguageOption, INSTALLED_INPUT_LANGUAGES } from '../telex/core/InputLanguageCatalog';
import { PreferencesManager } from '../telex/core/PreferencesManager';
import { DEFAULT_KEYBOARD_BG_COLOR, DEFAULT_KEYBOARD_DARK_MODE, DEFAULT_KEYBOARD_KEY_COLOR,
  DEFAULT_KEYBOARD_KEY_OPACITY, DEFAULT_KEYBOARD_OPACITY, getKeyboardTextColor, GTV_BG_COLOR_KEY,
  GTV_BG_OPACITY_KEY, GTV_DARK_MODE_KEY, GTV_KEY_COLOR_KEY, GTV_KEY_OPACITY_KEY,
  GTV_SHOW_NUMBER_ROW_KEY, KEYBOARD_COLOR_PALETTE, KEYBOARD_THEME_PRESETS, KeyboardThemePreset,
  normalizeKeyboardOpacity } from '../telex/ui/KeyboardTheme';

const GTV_BUNDLE_NAME = 'com.example.gotiengviet';
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
  @State draftBackgroundOpacity: number = DEFAULT_KEYBOARD_OPACITY;
  @State draftKeyOpacity: number = DEFAULT_KEYBOARD_KEY_OPACITY;
  @State draftBgBaseColor: string = DEFAULT_KEYBOARD_BG_COLOR;
  @State draftKeyBaseColor: string = DEFAULT_KEYBOARD_KEY_COLOR;
  @State draftDarkMode: boolean = DEFAULT_KEYBOARD_DARK_MODE;
  @State appearanceSavedMessage: string = '';
  @State fontWeightLevel: string = 'Vừa';
  @State keyboardWindowHeight: number = 280;
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

  // Theme colors
  private bg: string = '#0A0A1E';
  private cardBg: string = '#12122A';
  private accentColor: string = '#E94560';
  private accentLight: string = '#FF6B80';
  private textPrimary: string = '#EAEAEA';
  private textSecondary: string = '#8888AA';
  private divider: string = '#1E1E3A';

  aboutToAppear(): void {
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
    this.darkMode = await PreferencesManager.get(GTV_DARK_MODE_KEY, DEFAULT_KEYBOARD_DARK_MODE) as boolean;
    this.syncAppearanceDrafts();
  }

  async saveSetting(key: string, value: preferences.ValueType): Promise<void> {
    await PreferencesManager.set(key, value);
    AppStorage.setOrCreate(key, value);
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
    await this.saveSetting(GTV_BG_OPACITY_KEY, this.backgroundOpacity);
    await this.saveSetting(GTV_KEY_OPACITY_KEY, this.keyOpacity);
    await this.saveSetting(GTV_BG_COLOR_KEY, this.bgBaseColor);
    await this.saveSetting(GTV_KEY_COLOR_KEY, this.keyBaseColor);
    await this.saveSetting(GTV_DARK_MODE_KEY, this.darkMode);
    // Thông báo cho bàn phím
    KeyboardBridge.sendThemeChanged();
    this.appearanceSavedMessage = 'Đã lưu và áp dụng giao diện';
  }

  applyThemePreset(preset: KeyboardThemePreset): void {
    this.draftBgBaseColor = preset.bgColor;
    this.draftKeyBaseColor = preset.keyColor;
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
              this.buildMainSettings()
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

  @Builder
  buildMainSettings() {
    Column() {
      // this.buildPermissionCard()

      this.buildSectionTitle('Danh sách chức năng')

      Column() {
        ForEach(this.getFeatureEntries(), (feature: FeatureEntry, index: number) => {
          this.buildFeatureListItem(feature, index)
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

  private getFeatureEntries(): FeatureEntry[] {
    const rows: FeatureEntry[] = [];
    rows.push({
      id: 'appearance',
      title: 'Quản lý giao diện',
      subtitle: 'Màu nền, màu phím, độ trong, hàng số, kiểu chữ, giao diện đã lưu',
      icon: '🎨'
    });
    rows.push({
      id: 'size',
      title: 'Thay đổi kích thước',
      subtitle: 'Cỡ chữ, độ đậm, chiều cao cửa sổ phím và kéo bàn phím',
      icon: '↕️'
    });
    rows.push({
      id: 'language',
      title: 'Bộ quản lý ngôn ngữ',
      subtitle: 'Danh sách tiếng, kiểu gõ, tải thêm hoặc xoá gói ngôn ngữ',
      icon: '🌐'
    });
    rows.push({
      id: 'typing',
      title: 'Phương pháp gõ',
      subtitle: 'Enter, tự viết hoa, dấu cách, gợi ý, sửa lỗi, dịch, clipboard',
      icon: '⌨️'
    });
    rows.push({
      id: 'button',
      title: 'Cài đặt nút',
      subtitle: 'Âm thanh, rung, pop-up phím và thời gian giữ phím',
      icon: '🔘'
    });
    rows.push({
      id: 'sticker',
      title: 'Quản lý sticker',
      subtitle: 'Chèn GIF từ file và lưu thành bộ sticker',
      icon: '🖼️'
    });
    rows.push({
      id: 'voice',
      title: 'Nhập bằng giọng nói',
      subtitle: 'Chỉ tiếng Việt, chọn model nhanh và bật tắt nhập giọng nói',
      icon: '🎙️'
    });
    return rows;
  }

  // @Builder
  // buildPermissionCard() {
  //   this.buildSectionTitle('Cấp quyền')
  //
  //   Column() {
  //     this.buildPermissionRow('🎙️', 'Voice', 'Micro cho nhập bằng giọng nói', this.permissionVoice)
  //     Divider().color(this.divider).margin({ left: 20, right: 20 })
  //     this.buildPermissionRow('🖼️', 'Media', 'Ảnh, GIF và âm thanh phím', this.permissionMedia)
  //     Divider().color(this.divider).margin({ left: 20, right: 20 })
  //     this.buildPermissionRow('📁', 'File', 'Chọn file sticker, âm phím và ảnh nền', this.permissionFile)
  //     Divider().color(this.divider).margin({ left: 20, right: 20 })
  //     this.buildPermissionRow('🌍', 'Mạng', 'Dịch, tải model và tải gói ngôn ngữ', this.permissionNetwork)
  //     Divider().color(this.divider).margin({ left: 20, right: 20 })
  //     this.buildPermissionRow('🚀', 'Mở cùng với máy', 'Chuẩn bị dịch vụ bàn phím sau khi khởi động', this.permissionStartup)
  //
  //     Button('Mở cài đặt app GoTiếngViệt')
  //       .width('88%')
  //       .height(42)
  //       .backgroundColor(this.accentColor)
  //       .fontColor(Color.White)
  //       .borderRadius(21)
  //       .margin({ top: 12, bottom: 16 })
  //       .onClick(() => {
  //         this.openAppPermissionSettings();
  //       })
  //   }
  //   .width('90%')
  //   .backgroundColor(this.cardBg)
  //   .borderRadius(16)
  //   .clip(true)
  //   .margin({ bottom: 20 })
  // }

  @Builder
  buildFeatureListItem(feature: FeatureEntry, index: number) {
    Column() {
      Row() {
        Text(feature.icon)
          .fontSize(20)
          .margin({ right: 12 })

        Column() {
          Text(feature.title)
            .fontSize(15)
            .fontColor(this.textPrimary)
            .fontWeight(FontWeight.Medium)
          Text(feature.subtitle)
            .fontSize(11)
            .fontColor(this.textSecondary)
            .margin({ top: 3 })
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.openedFeature === feature.id ? '⌄' : '›')
          .fontSize(22)
          .fontColor(this.openedFeature === feature.id ? this.accentLight : this.textSecondary)
      }
      .width('100%')
      .padding({ left: 18, right: 16, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.openedFeature === feature.id ? '#171735' : 'transparent')
      .onClick(() => {
        this.openedFeature = this.openedFeature === feature.id ? '' : feature.id;
      })

      if (this.openedFeature === feature.id) {
        Divider().color(this.divider).margin({ left: 20, right: 20 })
        this.buildFeatureDetail(feature.id)
      }

      Divider().color(this.divider).margin({ left: 20, right: 20 })
    }
    .width('100%')
  }

  @Builder
  buildFeatureDetail(featureId: string) {
    Column() {
      if (featureId === 'appearance') {
        this.buildAppearanceSettings()
      } else if (featureId === 'size') {
        this.buildSizeSettings()
      } else if (featureId === 'language') {
        this.buildLanguageSettings()
      } else if (featureId === 'typing') {
        this.buildTypingSettings()
      } else if (featureId === 'button') {
        this.buildButtonSettings()
      } else if (featureId === 'sticker') {
        this.buildStickerSettings()
      } else if (featureId === 'voice') {
        this.buildVoiceSettings()
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 16 })
    .backgroundColor('#101026')
  }

  @Builder
  buildPermissionRow(icon: string, title: string, subtitle: string, value: boolean) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ right: 12 })

      Column() {
        Text(title)
          .fontSize(15)
          .fontColor(this.textPrimary)
        Text(subtitle)
          .fontSize(11)
          .fontColor(this.textSecondary)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(value ? '✓' : '')
        .fontSize(15)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(28)
        .height(28)
        .backgroundColor(value ? '#1A6A40' : '#252545')
        .border({ width: 1.5, color: value ? '#5EF29B' : '#4A4A68' })
        .borderRadius(14)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 13, bottom: 13 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openAppPermissionSettings();
    })
  }

  @Builder
  buildAppearanceSettings() {
    Column() {
      // Keyboard Preview
      Column() {
        Text("Xem trước bàn phím")
          .fontSize(12).fontColor(this.textSecondary).margin({bottom: 8})
        
        Stack() {
          Row({ space: 6 }) {
            Button("Q").type(ButtonType.Normal).borderRadius(6).backgroundColor(this.draftKeyBaseColor).fontColor(this.getKeyTextColor(this.draftKeyBaseColor)).opacity(normalizeKeyboardOpacity(this.draftKeyOpacity)).width(36).height(46)
            Button("W").type(ButtonType.Normal).borderRadius(6).backgroundColor(this.draftKeyBaseColor).fontColor(this.getKeyTextColor(this.draftKeyBaseColor)).opacity(normalizeKeyboardOpacity(this.draftKeyOpacity)).width(36).height(46)
            Button("E").type(ButtonType.Normal).borderRadius(6).backgroundColor(this.draftKeyBaseColor).fontColor(this.getKeyTextColor(this.draftKeyBaseColor)).opacity(normalizeKeyboardOpacity(this.draftKeyOpacity)).width(36).height(46)
            Button("R").type(ButtonType.Normal).borderRadius(6).backgroundColor(this.draftKeyBaseColor).fontColor(this.getKeyTextColor(this.draftKeyBaseColor)).opacity(normalizeKeyboardOpacity(this.draftKeyOpacity)).width(36).height(46)
          }
          .width('100%').height(70)
          .backgroundColor(this.draftBgBaseColor)
          .opacity(normalizeKeyboardOpacity(this.draftBackgroundOpacity))
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          }.width('90%').margin({bottom: 24}).backgroundColor('#000000').borderRadius(8)
        }.width('100%')

        this.buildToggleRow('Chế độ tối cho bàn phím', '◐', this.draftDarkMode, (val: boolean) => {
          this.draftDarkMode = val;
          this.appearanceSavedMessage = '';
        })

        // Nền sau phím
        Column() {
          Text('Nền sau phím').fontSize(14).fontColor(this.textPrimary).width('100%').margin({ bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Button().width(36).height(36).backgroundColor(color).borderRadius(18).margin({ right: 12 })
                .border({ width: this.draftBgBaseColor === color ? 2 : 1, color: this.draftBgBaseColor === color ? '#5EF29B' : '#FFFFFF33' })
                .onClick(() => {
                  this.draftBgBaseColor = color;
                  this.appearanceSavedMessage = '';
                })
            })
          }
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      }.width('100%').margin({ bottom: 20 })

      // Màu phím
      Column() {
        Text('Màu phím').fontSize(14).fontColor(this.textPrimary).width('100%').margin({ bottom: 8 })
        Scroll() {
          Row() {
            ForEach(KEYBOARD_COLOR_PALETTE, (color: string) => {
              Button().width(36).height(36).backgroundColor(color).borderRadius(18).margin({ right: 12 })
                .border({ width: this.draftKeyBaseColor === color ? 2 : 1, color: this.draftKeyBaseColor === color ? '#5EF29B' : '#FFFFFF33' })
                .onClick(() => {
                  this.draftKeyBaseColor = color;
                  this.appearanceSavedMessage = '';
                })
            })
          }
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      }.width('100%').margin({ bottom: 20 })
      this.buildSliderSetting('Độ trong nền', `${this.draftBackgroundOpacity}%`, this.draftBackgroundOpacity, 10, 100, 1, (value: number) => {
        this.draftBackgroundOpacity = Math.round(value);
        this.appearanceSavedMessage = '';
      })
      this.buildSliderSetting('Độ trong phím', `${this.draftKeyOpacity}%`, this.draftKeyOpacity, 10, 100, 1, (value: number) => {
        this.draftKeyOpacity = Math.round(value);
        this.appearanceSavedMessage = '';
      })
      Button('Lưu cài đặt')
        .width('90%')
        .height(42)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor(this.accentColor)
        .borderRadius(21)
        .margin({ top: 8, bottom: 8 })
        .onClick(() => {
          this.applyAppearanceSettings().catch((err: Error) => {
            console.error('[GoTiengViet] save appearance failed:', err.message);
          });
        })
      if (this.appearanceSavedMessage.length > 0) {
        Text(this.appearanceSavedMessage)
          .fontSize(11)
          .fontColor('#5EF29B')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })
      }
        this.buildToggleRow('Bật hàng phím số', '123', this.numberRowEnabled, (val: boolean) => {
          this.numberRowEnabled = val;
          this.saveSetting(GTV_SHOW_NUMBER_ROW_KEY, val);
        })
      this.buildToggleRow('Chữ trên bàn phím dạng hoa', 'Aa', this.uppercaseLabels, (val: boolean) => {
        this.uppercaseLabels = val;
      })
      this.buildSavedThemeRow()
    }
    .width('100%')
  }

  @Builder
  buildSizeSettings() {
    Column() {
      this.buildSliderSetting('Cỡ font chữ', `${this.fontSizeValue}sp`, this.fontSizeValue, 12, 24, 1, (value: number) => {
        this.fontSizeValue = Math.round(value);
      })
      this.buildChoiceRow('Độ đậm font', ['Mỏng', 'Vừa', 'Đậm'], this.fontWeightLevel, (value: string) => {
        this.fontWeightLevel = value;
      })
      this.buildSliderSetting('Chiều cao cửa sổ phím', `${this.keyboardWindowHeight}vp`, this.keyboardWindowHeight, 180, 420, 1, (value: number) => {
        this.keyboardWindowHeight = Math.round(value);
      })
      this.buildToggleRow('Cho kéo mép trên/dưới bàn phím', '↕️', this.resizableKeyboard, (val: boolean) => {
        this.resizableKeyboard = val;
      })
      this.buildKeyboardResizePreview()
      this.buildSettingNote('Kéo các tay nắm ở cạnh, góc và giữa mép trên/dưới để chỉnh vùng bàn phím mô phỏng.')
    }
    .width('100%')
  }

  @Builder
  buildKeyboardResizePreview() {
    Column() {
      Row() {
        Text('Kích thước bàn phím')
          .fontSize(14)
          .fontColor(this.textPrimary)
          .layoutWeight(1)
        Text(`${this.keyboardPreviewWidthPercent}% • ${this.keyboardWindowHeight}vp`)
          .fontSize(11)
          .fontColor(this.accentLight)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 10 })

      Stack({ alignContent: Alignment.Center }) {
        Stack({ alignContent: Alignment.Center }) {
          Column() {
            Row() {
              ForEach(['1','2','3','4','5','6','7','8','9','0'], (key: string) => {
                this.buildMiniKey(key)
              })
            }
            .width('100%')
            .height(24)
            Row() {
              ForEach(['q','w','e','r','t','y','u','i','o','p'], (key: string) => {
                this.buildMiniKey(key)
              })
            }
            .width('100%')
            .height(24)
            Row() {
              ForEach(['a','s','d','f','g','h','j','k','l'], (key: string) => {
                this.buildMiniKey(key)
              })
            }
            .width('92%')
            .height(24)
            Row() {
              this.buildMiniWideKey('⇧', 1.35)
              ForEach(['z','x','c','v','b','n','m'], (key: string) => {
                this.buildMiniKey(key)
              })
              this.buildMiniWideKey('⌫', 1.35)
            }
            .width('100%')
            .height(24)
            Row() {
              this.buildMiniWideKey('123', 1.4)
              this.buildMiniWideKey(',', 0.8)
              this.buildMiniWideKey('Tiếng Việt', 4)
              this.buildMiniWideKey('.', 0.8)
              this.buildMiniWideKey('↵', 1.4)
            }
            .width('100%')
            .height(26)
          }
          .width('100%')
          .height('100%')
          .padding({ left: 6, right: 6, top: 7, bottom: 7 })
          .backgroundColor('#EEF2F7')
          .border({ width: 2, color: '#38A7FF' })
          .borderRadius(8)

          this.buildResizeHandle('top-left', 18, 18, 9, Alignment.TopStart)
          this.buildResizeHandle('top', 54, 12, 6, Alignment.Top)
          this.buildResizeHandle('top-right', 18, 18, 9, Alignment.TopEnd)
          this.buildResizeHandle('left', 12, 48, 6, Alignment.Start)
          this.buildResizeHandle('right', 12, 48, 6, Alignment.End)
          this.buildResizeHandle('bottom-left', 18, 18, 9, Alignment.BottomStart)
          this.buildResizeHandle('bottom', 54, 12, 6, Alignment.Bottom)
          this.buildResizeHandle('bottom-right', 18, 18, 9, Alignment.BottomEnd)
        }
        .width(`${this.keyboardPreviewWidthPercent}%`)
        .height(this.getKeyboardPreviewHeight())
      }
      .width('100%')
      .height(188)
      .backgroundColor('#0B0B20')
      .borderRadius(12)
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
  }

  @Builder
  buildResizeHandle(handle: string, width: number, height: number, radius: number, align: Alignment) {
    Row() {
    }
    .width(width)
    .height(height)
    .backgroundColor(this.resizableKeyboard ? '#E94560' : '#5B5B72')
    .borderRadius(radius)
    .border({ width: 2, color: '#FFFFFF' })
    .align(align)
    .opacity(this.resizableKeyboard ? 1 : 0.45)
    .gesture(
      PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
        .onActionStart((_event: GestureEvent) => {
          if (this.resizableKeyboard) {
            this.beginKeyboardResize();
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.resizableKeyboard) {
            this.updateKeyboardResize(handle, event.offsetX, event.offsetY);
          }
        })
    )
  }

  @Builder
  buildMiniKey(label: string) {
    Text(label)
      .fontSize(9)
      .fontColor('#566070')
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(4)
      .margin({ left: 1, right: 1, top: 2, bottom: 2 })
  }

  @Builder
  buildMiniWideKey(label: string, weight: number) {
    Text(label)
      .fontSize(9)
      .fontColor('#566070')
      .textAlign(TextAlign.Center)
      .layoutWeight(weight)
      .height(21)
      .backgroundColor('#FFFFFF')
      .borderRadius(4)
      .margin({ left: 1, right: 1, top: 2, bottom: 2 })
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  buildLanguageSettings() {
    Column() {
      ForEach(INSTALLED_INPUT_LANGUAGES, (item: InputLanguageOption, index: number) => {
        this.buildInstalledLanguageRow(item, index)
      })
      this.buildActionRow('Tải thêm gói ngôn ngữ', 'Ngôn ngữ và kiểu gõ bổ sung', () => {
        this.showDeveloping('Tải ngôn ngữ');
      })
      this.buildSettingNote('Danh sách này dùng chung với nút Ngôn ngữ trong layout cài đặt nhanh của bàn phím.')
    }
    .width('100%')
  }

  @Builder
  buildTypingSettings() {
    Column() {
      this.buildToggleRow('Enter để gửi thay vì xuống dòng', '↵', this.enterToSend, (val: boolean) => {
        this.enterToSend = val;
      })
      this.buildToggleRow('Tự viết hoa sau dấu câu/xuống dòng/đầu văn bản', 'A', this.autoCapitalize, (val: boolean) => {
        this.autoCapitalize = val;
      })
      this.buildToggleRow('Tự thêm dấu cách sau . , : ? ! ...', '␠', this.autoSpaceAfterPunctuation, (val: boolean) => {
        this.autoSpaceAfterPunctuation = val;
      })
      this.buildToggleRow('Bật gợi ý văn bản', '💬', this.textSuggestion, (val: boolean) => {
        this.textSuggestion = val;
      })
      this.buildToggleRow('Tự động sửa lỗi', '✏️', this.autocorrect, (val: boolean) => {
        this.autocorrect = val;
      })
      this.buildSettingNote('Khi tự sửa lỗi bật, thanh trên bàn phím sẽ có nút khôi phục cạnh nút chọn kiểu gõ trong bước làm taskbar.')
      this.buildToggleRow('Dịch ngôn ngữ Việt - Anh', '⇄', this.translateEnabled, (val: boolean) => {
        this.translateEnabled = val;
        this.showDeveloping('Dịch');
      })
      this.buildToggleRow('Lưu clipboard trong ngày', '📋', this.clipboardDailyStore, (val: boolean) => {
        this.clipboardDailyStore = val;
        this.showDeveloping('Clipboard');
      })
      this.buildChoiceRow('Giữ clipboard trong khoảng', ['1 tiếng', '3 tiếng', '6 tiếng', '8 tiếng', '24 tiếng'], this.clipboardKeepHours, (value: string) => {
        this.clipboardKeepHours = value;
        this.showDeveloping('Clipboard');
      })
      this.buildSettingNote('Lưu text, ảnh và file trong clipboard lâu hơn có thể tăng dùng RAM, bộ nhớ nền và pin.')
    }
    .width('100%')
  }

  @Builder
  buildButtonSettings() {
    Column() {
      this.buildToggleRow('Âm thanh khi ấn phím', '🔊', this.sound, (val: boolean) => {
        this.sound = val;
      })
      this.buildSliderSetting('Âm lượng phím', `${this.keySoundVolume}%`, this.keySoundVolume, 0, 100, 1, (value: number) => {
        this.keySoundVolume = Math.round(value);
      })
      this.buildChoiceRow('Loại âm phát ra', ['Mặc định', 'Cơ học', 'Từ file'], this.keySoundType, (value: string) => {
        this.keySoundType = value;
      })
      this.buildActionRow('Chèn âm từ thư mục', 'Chọn file âm thanh dùng cho nút')
      this.buildToggleRow('Rung khi ấn phím', '📳', this.vibration, (val: boolean) => {
        this.vibration = val;
      })
      this.buildSliderSetting('Cường độ rung', `${this.vibrationStrength}/3`, this.vibrationStrength, 1, 3, 1, (value: number) => {
        this.vibrationStrength = Math.round(value);
      })
      this.buildToggleRow('Pop-up nút khi ấn phím', '▣', this.keyPopupPreview, (val: boolean) => {
        this.keyPopupPreview = val;
      })
      this.buildSliderSetting('Thời gian giữ phím', `${this.longPressDelay}ms`, this.longPressDelay, 100, 800, 10, (value: number) => {
        this.longPressDelay = Math.round(value);
      })
    }
    .width('100%')
  }

  @Builder
  buildStickerSettings() {
    Column() {
      this.buildToggleRow('Bật bộ sticker GIF', 'GIF', this.stickerGifEnabled, (val: boolean) => {
        this.stickerGifEnabled = val;
        this.showDeveloping('Sticker');
      })
      this.buildActionRow('Chèn sticker từ file GIF', 'Lưu vào bộ quản lý sticker', () => {
        this.showDeveloping('Sticker');
      })
      this.buildActionRow('Bộ sticker đã lưu', 'Danh sách sticker người dùng thêm vào', () => {
        this.showDeveloping('Sticker');
      })
    }
    .width('100%')
  }

  @Builder
  buildVoiceSettings() {
    Column() {
      this.buildToggleRow('Bật nhập bằng giọng nói', '🎙️', this.voiceInputEnabled, (val: boolean) => {
        this.voiceInputEnabled = val;
        this.showDeveloping('Voice');
      })
      this.buildChoiceRow('Model nhận diện tiếng Việt', ['Nhẹ', 'Cân bằng', 'Chính xác hơn'], this.voiceModel, (value: string) => {
        this.voiceModel = value;
        this.showDeveloping('Voice');
      })
      this.buildSettingNote('Chỉ hỗ trợ tiếng Việt. Tiêu chí model: trả kết quả nhanh và độ chính xác mục tiêu khoảng 0.8 trở lên; cần benchmark thật trên máy trước khi chốt mặc định.')
    }
    .width('100%')
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
          })
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
            })
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
