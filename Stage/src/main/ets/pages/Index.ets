/**
 * Index.ets - Settings Page của GoTiếngViệt
 * Giao diện cài đặt đẹp với dark theme
 */

import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import inputMethod from '@ohos.inputMethod';

// Khai báo interface rõ ràng (ArkTS yêu cầu)
interface GuideRow {
  key: string;
  result: string;
  example: string;
}

@Entry
@Component
struct SettingsPage {
  @State inputMethodEnabled: boolean = false;
  @State defaultMethod: string = 'telex';
  @State autocorrect: boolean = true;
  @State sound: boolean = false;
  @State vibration: boolean = true;
  @State selectedTab: number = 0;
  @State showGuideDialog: boolean = false;

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

    let success = false;
    for (const want of settingsAttempts) {
      try {
        await ctx.startAbility(want);
        success = true;
        break; // Dừng lại nếu mở thành công
      } catch (e) {
        // Tiếp tục thử cái tiếp theo
      }
    }

    // Luôn hiện dialog hướng dẫn thủ công
    this.showGuideDialog = true;
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

            Text('💡 Mate60Pro: Cài đặt → Hệ thống → Ngôn ngữ & phương pháp nhập → Bàn phím mặc định')
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
      // === Phương pháp gõ ===
      this.buildSectionTitle('Phương pháp gõ')

      Column() {
        this.buildMethodOption('Telex', 'telex', 'aa→â  aw→ă  dd→đ  s/f/r/x/j = dấu')
        Divider().color(this.divider).margin({ left: 20, right: 20 })
        this.buildMethodOption('VNI', 'vni', '6→â  7→ơ  8→ă  9→ư  0→đ  1-5 = dấu')
        Divider().color(this.divider).margin({ left: 20, right: 20 })
        this.buildMethodOption('English', 'en', 'Gõ tiếng Anh thông thường')
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .margin({ bottom: 20 })

      // === Tùy chỉnh ===
      this.buildSectionTitle('Tùy chỉnh')

      Column() {
        this.buildToggleRow('Tự động sửa lỗi', '✏️', this.autocorrect, (val: boolean) => {
          this.autocorrect = val;
        })
        Divider().color(this.divider).margin({ left: 20, right: 20 })
        this.buildToggleRow('Âm thanh bàn phím', '🔊', this.sound, (val: boolean) => {
          this.sound = val;
        })
        Divider().color(this.divider).margin({ left: 20, right: 20 })
        this.buildToggleRow('Rung khi nhấn phím', '📳', this.vibration, (val: boolean) => {
          this.vibration = val;
        })
      }
      .width('90%')
      .backgroundColor(this.cardBg)
      .borderRadius(16)
      .margin({ bottom: 20 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 16 })
  }

  @Builder
  buildMethodOption(name: string, id: string, description: string) {
    Row() {
      Column() {
        Text(name)
          .fontSize(16)
          .fontColor(this.textPrimary)
          .fontWeight(FontWeight.Medium)

        Text(description)
          .fontSize(12)
          .fontColor(this.textSecondary)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Radio({ value: id, group: 'inputMethod' })
        .checked(this.defaultMethod === id)
        .radioStyle({
          checkedBackgroundColor: this.accentColor,
          indicatorColor: Color.White,
        })
        .onChange((checked: boolean) => {
          if (checked) this.defaultMethod = id;
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .alignItems(VerticalAlign.Center)
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
    rows.push({ key: 'u + 9', result: 'ư', example: 'u9 → ư' });
    rows.push({ key: 'd + 0', result: 'đ', example: 'd0 → đ' });
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