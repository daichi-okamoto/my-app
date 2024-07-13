class ShiftsController < ApplicationController
  skip_before_action :require_login, only: [:create_schedule]
  skip_before_action :verify_authenticity_token, only: [:create_schedule]
  
  def index
    Rails.logger.debug "Calling set_month_data in ShiftsController#index"
    set_month_data(params[:year], params[:month])
    @employees = Employee.all
    @shifts = Shift.all.group_by(&:employee_id)
  end

  def new
    @year = params[:year]
    @month = params[:month]
    
    set_month_data(@year, @month)
    @employees = Employee.all

    # ここでシフトリクエストを取得します
    @shift_requests = ShiftRequest.where(date: @start_date..@end_date).group_by(&:employee_id)
    @memos = Memo.where(date: @start_date..@end_date).index_by(&:date)
  end

  def edit
    Rails.logger.debug "Calling set_month_data in ShiftsController#edit"
    set_month_data(params[:year], params[:month])
    @schedule_output = @schedule_output || {}
  end

  def update
  end

  def create
    params[:shifts].each do |shift_params|
      shift = Shift.new(shift_params.permit(:date, :shift_type, :employee_id))
      shift.user = current_user
      unless shift.save
        flash[:error] = 'シフトの保存に失敗しました'
      end
    end
    redirect_to shifts_path
  end

  def create_schedule
    Rails.logger.debug "Calling set_month_data in ShiftsController#create_schedule"
    set_month_data(params[:year], params[:month])
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

  def destroy_all
    start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
    end_date = start_date.end_of_month
  
    ActiveRecord::Base.transaction do
      # シフトを削除
      Shift.where(date: start_date..end_date).destroy_all
      
      # シフトリクエストを削除
      ShiftRequest.where(date: start_date..end_date).destroy_all
      
      # メモを削除
      Memo.where(date: start_date..end_date).destroy_all
    end
    
    redirect_to shifts_path(year: params[:year], month: params[:month]), success: 'シフトを削除しました'
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to shifts_path(year: params[:year], month: params[:month]), alert: "削除に失敗しました: #{e.message}"
  end

  private

  def shift_params
    params.require(:shift).permit(:date, :shift_type, :employee_id)
  end
end
