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
    set_month_data(params[:year], params[:month])
    @employees = Employee.all
    @shift_requests = ShiftRequest.where("extract(year from date) = ? AND extract(month from date) = ?", @year, @month).group_by(&:employee_id)
    set_month_data(@year, @month)
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

  private

  def shift_params
    params.require(:shift).permit(:date, :shift_type, :employee_id)
  end
end
