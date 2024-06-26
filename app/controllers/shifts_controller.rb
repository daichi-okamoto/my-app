class ShiftsController < ApplicationController
  def index
    month
    @employees = Employee.all
  end

  def month
    # 現在の日付を取得
    date_now = Date.current

    # 曜日を取得
    @weeks = ["日", "月", "火", "水", "木", "金", "土"]

    month_names = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]

    @month = month_names[date_now.month - 1]

    # 月の最初の日と最後の日を取得
    first_day = date_now.beginning_of_month
    last_day = date_now.end_of_month

    # first_dayからlast_dayまでの日付を配列に格納
    @calendar = (first_day..last_day).to_a
  end
end
