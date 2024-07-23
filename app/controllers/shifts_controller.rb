class ShiftsController < ApplicationController
  skip_before_action :require_login, only: [:create_schedule]
  skip_before_action :verify_authenticity_token, only: [:create_schedule]
  
  def index
    Rails.logger.debug "Calling set_month_data in ShiftsController#index"
    set_month_data(params[:year], params[:month])
    @employees = Employee.all
    @shifts = Shift.all.group_by(&:employee_id)
    @memos = Memo.where(date: @start_date..@end_date).index_by(&:date)
    @shift_counts = sum_shift_counts(@employees, @shifts, @calendar)
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
    set_month_data(params[:year], params[:month])
    @schedule_output = @schedule_output || {}
  end

  def update_schedule
    set_month_data(params[:year], params[:month])
    @employees = Employee.all
    @schedule_output = @schedule_output || {}
    @memos = Memo.where(date: @start_date..@end_date).index_by(&:date)
    @shifts = Shift.where(date: @start_date..@end_date).group_by(&:employee_id)
    
    ActiveRecord::Base.transaction do
      params[:shifts].each do |employee_id, shifts|
        shifts.each do |date, shift_type|
          formatted_shift_type = format_shift_type(shift_type)
          shift = Shift.find_or_initialize_by(employee_id: employee_id, date: date)
          shift.shift_type = formatted_shift_type
          unless shift.save
            flash[:danger] = 'シフトの保存に失敗しました'
            raise ActiveRecord::Rollback
          end
        end
      end
    
      params[:memos].each do |date, content|
        memo = Memo.find_by(date: date)
        if content.blank?
          memo&.destroy
        else
          memo ||= Memo.new(date: date, user: current_user)
          memo.content = content
          unless memo.save
            flash[:danger] = 'メモの保存に失敗しました'
            raise ActiveRecord::Rollback
          end
        end
      end
    end
    
    flash[:success] = 'シフトを変更しました'
    redirect_to shifts_path(year: params[:year], month: params[:month])
  end  

  def create
    params[:shifts].each do |shift_params|
      shift = Shift.new(shift_params.permit(:date, :shift_type, :employee_id))
      shift.user = current_user
      unless shift.save
        flash[:danger] = 'シフトの保存に失敗しました'
      end
    end
    flash[:success] = 'シフトを保存しました'
    redirect_to shifts_path
  end

  def create_schedule
    Rails.logger.debug "Calling set_month_data in ShiftsController#create_schedule"
    set_month_data(params[:year], params[:month]) 
    @employees = Employee.all
    @memos = Memo.where(date: @start_date..@end_date).index_by(&:date)

    employees = Employee.all
    dates = (@start_date..@end_date).to_a
    shift_requests = ShiftRequest.where(date: @start_date..@end_date).group_by(&:employee_id)

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
          employee_type: e.employee_type,
          shift_requests: shift_requests[e.id]&.map { |sr| { date: sr.date.to_s, shift_type: sr.shift_type } } || []
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
      if parsed_output.key?("Error")
        clear_shift_requests_and_memos(@start_date, @end_date)
        flash[:danger] = 'シフトを作成できませんでした。勤務希望を再度調整してください。またはスタッフを追加してください'
        redirect_to new_shift_request_path(year: params[:year], month: params[:month]) and return
      end
      @schedule_output = parsed_output.empty? ? {}: parsed_output
    rescue JSON::ParserError => e
      Rails.logger.error "JSON Parse Error: #{e.message}"
      Rails.logger.error "Failed output: #{output}"
      @schedule_output = {}
    end

    Rails.logger.info "Parsed schedule output: #{@schedule_output.inspect}"

    flash.now[:success] = 'シフトを作成しました'
    render :edit, status: :unprocessable_entity
  end

  def edit_schedule
    set_month_data(params[:year], params[:month])
    @employees = Employee.all
    @memos = Memo.where(date: @start_date..@end_date).index_by(&:date)
    @shifts = Shift.where(date: @start_date..@end_date).group_by(&:employee_id)
    @shifts.default = [] 
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

  def export_excel
    set_month_data(params[:year], params[:month])
    @employees = Employee.all
    @shifts = Shift.where(date: @start_date..@end_date).group_by(&:employee_id)
    @memos = Memo.where(date: @start_date..@end_date).index_by(&:date)
  
    respond_to do |format|
      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=shifts_#{params[:year]}_#{params[:month]}.xlsx"
      }
    end
  end

  private

  def shift_params
    params.require(:shift).permit(:date, :shift_type, :employee_id)
  end

  def sum_shift_counts(employees, shifts, calendar)
    counts = {}
    employees.each do |employee|
      counts[employee.id] = { early: 0, day: 0, late: 0, night: 0, off: 0 }
      calendar.each do |date|
        next unless shifts[employee.id]
        shift = shifts[employee.id].find { |s| s.date == date }
        next unless shift
        case shift.shift_type
        when "早番"
          counts[employee.id][:early] += 1
        when "日勤"
          counts[employee.id][:day] += 1
        when "遅番"
          counts[employee.id][:late] += 1
        when "夜勤"
          counts[employee.id][:night] += 1
        when "休み"
          counts[employee.id][:off] += 1
        end
      end
    end
    counts
  end

  def format_shift_type(shift_type)
    case shift_type
    when 'H' then '早番'
    when 'N' then '日勤'
    when 'O' then '遅番'
    when 'Y' then '夜勤'
    when '明け' then '夜勤明け'
    when '⚫️' then '休み'
    else shift_type
    end
  end

  def clear_shift_requests_and_memos(start_date, end_date)
    ShiftRequest.where(date: start_date..end_date).destroy_all
    Memo.where(date: start_date..end_date).destroy_all
  end
end
