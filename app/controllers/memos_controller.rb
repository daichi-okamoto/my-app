class MemosController < ApplicationController
  def create
    @memo = current_user.memos.new(memo_params)
    @memo.save
    redirect_to new_shift_path(year: params[:memo][:year], month: params[:memo][:month])
  end
end
