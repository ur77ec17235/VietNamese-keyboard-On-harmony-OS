with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/ui/KeyboardTheme.ets', 'r') as f:
    content = f.read()
content = content.replace('keyColor: string;\n  bgOpacity: number;', 'keyColor: string;\n  textColor?: string;\n  bgOpacity: number;')
with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/telex/ui/KeyboardTheme.ets', 'w') as f:
    f.write(content)

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'r') as f:
    content = f.read()
content = content.replace(
    'this.draftKeyBaseColor = preset.keyColor;',
    'this.draftKeyBaseColor = preset.keyColor;\n    this.textBaseColor = preset.textColor || "";\n    this.saveSetting(GTV_TEXT_COLOR_KEY, this.textBaseColor);'
)
with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/Stage/src/main/ets/pages/Index.ets', 'w') as f:
    f.write(content)
print("Done patching presets")
