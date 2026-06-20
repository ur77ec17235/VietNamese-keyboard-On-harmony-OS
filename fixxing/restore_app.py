import json

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/AppScope/app.json5', 'r') as f:
    data = json.load(f)

del data['app']['dataGroupIds']

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/AppScope/app.json5', 'w') as f:
    json.dump(data, f, indent=2)

print("Done restoring app.json5")
