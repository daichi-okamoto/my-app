import pulp
import json
import sys

# 従業員とシフト、および日数を定義
# employees = ['岡本', '吉川', '市沢', '寺澤', '高原', '北原', '山宮', '湯沢', '荒牧', '伊坪']
# shifts = ["早番", "日勤", "遅番", "夜勤", "夜勤明け"]
# days = range(1, 31)  # 1ヶ月分の日数

# 標準入力からデータを読み込む
input_data = sys.stdin.read()
data = json.loads(input_data)

# JSONデータから従業員と日付を取得
employees_data = data['employees']
dates_data = data['dates']

# 従業員の名前リストを作成
employees = [employee['name'] for employee in employees_data]

# 日付リストを作成
days = range(1, len(dates_data) + 1)  # 日数の範囲を1から日付リストの長さに設定

# シフトのリスト
shifts = ["早番", "日勤", "遅番", "夜勤", "夜勤明け"]

# 例として、データの確認
# print("従業員リスト:", employees)
# print("日数の範囲:", list(days))
# print("シフトリスト:", shifts)

# 各従業員の勤務可能シフトを表示
# for employee in employees_data:
#     print(f"{employee['name']}の勤務可能シフト:")
#     for shift, available in employee.items():
#         if shift in ['early_shift', 'day_shift', 'late_shift', 'night_shift'] and available:
#             print(f"  {shift}: {available}")

# 問題の定義
prob = pulp.LpProblem("ShiftScheduling", pulp.LpMinimize)

# 変数の定義
assignment = pulp.LpVariable.dicts("assign", (employees, shifts, days), cat='Binary')
rest_days = pulp.LpVariable.dicts("rest_days", employees, lowBound=0, cat='Integer')
rest_deviation = pulp.LpVariable.dicts("rest_deviation", employees, lowBound=0)
night_shift_penalty = pulp.LpVariable.dicts("night_shift_penalty", employees, lowBound=0, cat='Integer')
early_late_penalty = pulp.LpVariable.dicts("early_late_penalty", employees, lowBound=0, cat='Integer')
shift_deviation = pulp.LpVariable.dicts("shift_deviation", (employees, ["早番", "遅番"]), lowBound=0, cat='Continuous')

# 目的関数：休日の偏りとペナルティの最小化
prob += (
    pulp.lpSum(rest_deviation[e] for e in employees) +
    50 * pulp.lpSum(night_shift_penalty[e] for e in employees) +
    5 * pulp.lpSum(early_late_penalty[e] for e in employees) +
    100 * pulp.lpSum(shift_deviation[e][s] for e in employees for s in ["早番", "遅番"])
), "Minimize total deviation and penalties"

# 各従業員の休日数を計算
for e in employees:
    prob += rest_days[e] == len(days) - pulp.lpSum([assignment[e][s][d] for s in shifts for d in days])

# 休日数の範囲を設定
for employee in employees_data:
    e = employee['name']
    if employee['employee_type'] == '正社員':
        prob += rest_days[e] >= 9
        prob += rest_days[e] <= 11
    elif employee['employee_type'] == 'パート':
        prob += rest_days[e] >= 11
        prob += rest_days[e] <= 13  

# 基本的な制約条件の追加

# 1. 1日のうち、各シフトに最低1人割り当て
for d in days:
    for s in shifts:
        prob += pulp.lpSum([assignment[e][s][d] for e in employees]) >= 1

# 2. 早番、遅番、夜勤、夜勤明けは1人のみ
for d in days:  # 各日に対して
    for s in ["早番", "遅番", "夜勤", "夜勤明け"]: # 早番、遅番、夜勤、夜勤明けの各シフトに対して
        prob += pulp.lpSum([assignment[e][s][d] for e in employees]) <= 1

# 3. 夜勤と夜勤明けはセット
for e in employees:
    for d in range(1, len(days)):  # 最後の日を考慮
        if d + 1 in days:
            prob += assignment[e]["夜勤"][d] == assignment[e]["夜勤明け"][d+1]

# 4. 最大4連勤
for e in employees:
    for d in range(1, len(days) - 4 + 1):  # 連続する5日間を考慮
        prob += pulp.lpSum([assignment[e][s][day] for s in shifts for day in range(d, d + 5)]) <= 4

# 5. 夜勤明けの翌日は必ず休み
for e in employees:  # 全従業員について
    for d in range(1, len(days)):  # 最後の日を除く（翌日が存在する範囲内）
        # 夜勤明けの日の翌日にシフトが入っている場合にペナルティを課す
        prob += night_shift_penalty[e] >= assignment[e]["夜勤明け"][d] + pulp.lpSum([assignment[e][s][d+1] for s in shifts]) - 1

# 6. 遅番の翌日に早番はNG
for e in employees:
    for d in range(1, len(days)):  # 最後の日を除く
        if d + 1 in days:
            # 遅番の翌日に早番が入っている場合にペナルティを課す
            prob += early_late_penalty[e] >= assignment[e]["早番"][d+1] + assignment[e]["遅番"][d] - 1

# 7. 1日に1つのシフトのみ割り当て
for e in employees:
    for d in days:
        prob += pulp.lpSum([assignment[e][s][d] for s in shifts]) <= 1

# 8. 日勤のみの従業員に制約を追加
for employee in employees_data:
    if employee.get('day_shift', False) and not any(employee.get(shift, False) for shift in ['early_shift', 'late_shift', 'night_shift']):
        e = employee['name']
        for d in days:
            prob += assignment[e]["日勤"][d] <= 1  # 日勤に割り当て
            prob += pulp.lpSum([assignment[e][s][d] for s in ["早番", "遅番", "夜勤", "夜勤明け"]]) == 0  # 他のシフトには割り当てられない


# 9. 山宮、湯沢、荒牧、伊坪は日勤のみ
# day_shift_only_employees = ['山宮沙耶香', '湯沢ほなみ', '荒牧かおり', '伊坪裕美']
# for e in day_shift_only_employees:
#     for d in days:
#         prob += assignment[e]["日勤"][d] <= 1  # 日勤に割り当てられる場合
#         for s in ["早番", "遅番", "夜勤", "夜勤明け"]:
#             prob += assignment[e][s][d] == 0  # 他のシフトには割り当てられない

# 10. 早番と遅番は連続2日まで
for e in employees:
    for d in range(1, len(days) - 2 + 1):  # 連続する3日間を考慮
        if d + 2 in days:
            prob += assignment[e]["早番"][d] + assignment[e]["早番"][d+1] + assignment[e]["早番"][d+2] <= 2
            prob += assignment[e]["遅番"][d] + assignment[e]["遅番"][d+1] + assignment[e]["遅番"][d+2] <= 2

# 11. 各従業員の夜勤の回数を最大6回まで
for e in employees:
    prob += pulp.lpSum([assignment[e]["夜勤"][d] for d in days]) <= 6


# 問題を解く
prob.solve(pulp.PULP_CBC_CMD(msg=False))

# 結果の保存
schedule = {e: ["休み"] * len(days) for e in employees}

if pulp.LpStatus[prob.status] == "Optimal":
    for e in employees:
        for d in days:
            assigned_shifts = [s for s in shifts if assignment[e][s][d].value() == 1]
            if assigned_shifts:
                schedule[e][d - 1] = ", ".join(assigned_shifts)
else:
    schedule = {"Error": "Solution not found"}

# 結果をJSON形式で出力
print(json.dumps(schedule, ensure_ascii=False))


# 結果の表示
# print("Status:", pulp.LpStatus[prob.status])

# if pulp.LpStatus[prob.status] == "Optimal":
#     for e in employees:
#         early_shift_count = 0
#         day_shift_count = 0
#         late_shift_count = 0
#         night_shift_count = 0
        
#         print(f"\n{e}のシフト:")
#         rest_count = 0
#         for d in days:
#             assigned_shifts = [s for s in shifts if assignment[e][s][d].value() == 1]
#             if assigned_shifts:
#                 print(f"Day {d}: {', '.join(assigned_shifts)}")
#                 if "早番" in assigned_shifts:
#                     early_shift_count += 1
#                 if "日勤" in assigned_shifts:
#                     day_shift_count += 1
#                 if "遅番" in assigned_shifts:
#                     late_shift_count += 1
#                 if "夜勤" in assigned_shifts:
#                     night_shift_count += 1
#             else:
#                 print(f"Day {d}: 休み")
#                 rest_count += 1
        
#         print(f"休日数: {rest_count}")
#         print(f"早番: {early_shift_count}")
#         print(f"日勤: {day_shift_count}")
#         print(f"遅番: {late_shift_count}")
#         print(f"夜勤: {night_shift_count}")
# else:
#     print("Solution not found")