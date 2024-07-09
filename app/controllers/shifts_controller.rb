class ShiftsController < ApplicationController
  skip_before_action :require_login, only: [:create_schedule]
  skip_before_action :verify_authenticity_token, only: [:create_schedule]
  
  def index
    month(params[:year], params[:month])
    @employees = Employee.all
    @shifts = Shift.all.group_by(&:employee_id)
  end

  def new
  end

  def edit
    month(params[:year], params[:month])
    @schedule_output = @schedule_output || {}
  end

  def update
  end

  def create
    params[:shifts].each do |shift_params|
      shift = Shift.new(shift_params)
      shift.user = current_user
      unless shift.save
        flash[:error] = 'シフトの保存に失敗しました'
        redirect_to edit_shift_path and return
      end
    end

    flash[:success] = 'シフトが保存されました'
    redirect_to shifts_path
  end

  def create_schedule
    month(params[:year], params[:month])
    @employees = Employee.all

    employees = Employee.all
    dates = (@start_date..@end_date).to_a

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

    Rails.logger.info "Data for Python script: #{data.inspect}"
    json_data = data.to_json

    output = IO.popen("python3 #{Rails.root.join('lib', 'shift_test.py')}", "r+") do |f|
      f.puts json_data
      f.close_write
      f.read
    end

    Rails.logger.info "Python script output: #{output}"

    begin
      parsed_output = JSON.parse(output)
      @schedule_output = parsed_output.empty? ? nil : parsed_output
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error: #{e.message}"
      Rails.logger.error "Failed output: #{output}"
      @schedule_output = nil
    end

    Rails.logger.info "Parsed schedule output: #{@schedule_output.inspect}"

    flash.now[:success] = 'シフトを作成しました'
    render :edit, status: :unprocessable_entity
  end

  private

  def month(year = nil, month = nil)
    @year = year ? year.to_i : Date.current.year
    @month = month ? month.to_i : Date.current.month

    date_now = Date.new(@year, @month)
    @weeks = ["日", "月", "火", "水", "木", "金", "土"]

    month_names = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
    @month_name = month_names[date_now.month - 1]

    @start_date = date_now.beginning_of_month
    @end_date = date_now.end_of_month
    @calendar = (@start_date..@end_date).to_a
    @shift_calendar = "#{@start_date.year}年#{@start_date.month}月1日〜#{@end_date.month}月#{@end_date.day}日"
  end

  def shift_params
    params.require(:shift).permit(:date, :shift_type, :employee_id)
  end
end
