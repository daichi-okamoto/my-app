from ortools.sat.python import cp_model

def main():
    # モデルの作成
    print("Creating model...")
    model = cp_model.CpModel()

    # 変数の定義
    num_vals = 3
    print("Defining variables...")
    x = model.NewIntVar(0, num_vals - 1, 'x')
    y = model.NewIntVar(0, num_vals - 1, 'y')
    z = model.NewIntVar(0, num_vals - 1, 'z')

    # 制約の追加
    print("Adding constraints...")
    # すべての変数が異なるようにする制約
    model.Add(x != y)
    model.Add(y != z)
    model.Add(x != z)

    # ソルバーの作成と実行
    print("Creating solver and solving model...")
    solver = cp_model.CpSolver()
    status = solver.Solve(model)

    # 結果の表示
    if status == cp_model.FEASIBLE or status == cp_model.OPTIMAL:
        print(f'x = {solver.Value(x)}')
        print(f'y = {solver.Value(y)}')
        print(f'z = {solver.Value(z)}')
    else:
        print("No feasible solution found.")

if __name__ == '__main__':
    main()

