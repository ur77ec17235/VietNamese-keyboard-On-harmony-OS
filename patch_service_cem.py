import re

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'r') as f:
    content = f.read()

# Add import commonEventManager
if 'import commonEventManager' not in content:
    content = "import commonEventManager from '@ohos.commonEventManager';\n" + content

# Add the subscription in onCreate
cem_sub = """
    // Lắng nghe sự kiện THEME_CHANGED từ App chính
    let subscriber: commonEventManager.CommonEventSubscriber;
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ['com.example.gotiengviet.THEME_CHANGED']
    };
    commonEventManager.createSubscriber(subscribeInfo, (err, sub) => {
      if (!err) {
        subscriber = sub;
        commonEventManager.subscribe(subscriber, (err, data) => {
          if (!err) {
            console.info('[GoTiengViet] Nhận được THEME_CHANGED từ App, tiến hành load lại giao diện...');
            this.loadAppearanceSettings(true).catch((e: Error) => console.error(e.message));
          }
        });
      }
    });

    const ima = inputMethodEngine.getInputMethodAbility();
"""
content = content.replace(
    '    const ima = inputMethodEngine.getInputMethodAbility();',
    cem_sub
)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/service/GoTiengVietService.ets', 'w') as f:
    f.write(content)

print("Done patching Service for CEM")
