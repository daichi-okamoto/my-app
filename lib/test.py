import json
import sys

# 標準入力からデータを読み込む
input_data = sys.stdin.read()
data = json.loads(input_data)

# データを表示する
print("Received data:")
print(json.dumps(data, ensure_ascii=False, indent=2))