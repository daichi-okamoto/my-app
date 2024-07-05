class ShiftsController < ApplicationController
  skip_before_action :require_login, only: [:create_schedule]
  skip_before_action :verify_authenticity_token, only: [:create_schedule]
  
  def index
    month
    @employees = Employee.all
  end

  def new
    month
    
    @schedule_output = @schedule_output || {}
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

  def create_schedule
    month
    @employees = Employee.all

    # スタッフデータを取得
    employees = Employee.all

    # 日付データを取得（例: 1ヶ月分の日付）
    dates = (Date.today.beginning_of_month..Date.today.end_of_month).to_a

    # データをハッシュにまとめる
    data = {
      employees: employees.map do |e|
        shifts = {}
        shifts[:early_shift] = e.early_shift if e.early_shift
        shifts[:day_shift] = e.day_shift if e.day_shift
        shifts[:late_shift] = e.late_shift if e.late_shift
        shifts[:night_shift] = e.night_shift if e.night_shift
        {
          id: e.id,
          name: e.name,
          employee_type: e.employee_type
        }.merge(shifts)
      end,
      dates: dates.map(&:to_s)
    }

    # デバッグメッセージ
    Rails.logger.info "Data for Python script: #{data.inspect}"

    # データをJSON形式に変換
    json_data = data.to_json

    # Pythonスクリプトを実行し、標準入力でデータを渡す
    output = IO.popen("python3 #{Rails.root.join('lib', 'shift_test.py')}", "r+") do |f|
      f.puts json_data
      f.close_write
      f.read
    end

    # デバッグメッセージ
    Rails.logger.info "Python script output: #{output}"

    # Pythonスクリプトの出力をインスタンス変数に保存
    begin
      parsed_output = JSON.parse(output)
      @schedule_output = parsed_output.empty? ? nil : parsed_output
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error: #{e.message}"
      Rails.logger.error "Failed output: #{output}"
      @schedule_output = nil
    end

    # デバッグメッセージ
    Rails.logger.info "Parsed schedule output: #{@schedule_output.inspect}"

    flash.now[:success] = 'シフトを作成しました'
    # newビューをレンダリング
    render :new, status: :unprocessable_entity
  end
end
