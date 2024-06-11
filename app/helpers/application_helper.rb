module ApplicationHelper
  def flash_design(type)
    case type.to_sym
    when :success then "bg-whitesmoke text-gray rouded px-7 py-6"
    when :danger then "bg-beige text-gray rouded px-7 py-6"
    else "bg-gray"
    end
  end
end
