import json

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/AppScope/app.json5', 'r') as f:
    data = json.load(f)

data['app']['dataGroupIds'] = ['gtv_shared_group']

with open('/Users/hongviet/DevecostudioProjects/GOTIENGVIET/AppScope/app.json5', 'w') as f:
    json.dump(data, f, indent=2)

print("Done patching app.json5")
