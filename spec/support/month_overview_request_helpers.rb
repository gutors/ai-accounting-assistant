module MonthOverviewRequestHelpers
  def month_h2s(body)
    page_doc(body).css("h2").map { |node| node.text.strip }
  end

  def month_fold_summaries(body)
    page_doc(body).css("details.month-fold > summary").map { |node| node.text.strip }
  end

  def month_fold(body, title)
    page_doc(body).css("details.month-fold").find { |node| node.at_css("summary")&.text&.strip == title }
  end

  def month_chip_links(body)
    page_doc(body).at_css('[role="group"][aria-label="Conta bancária"]').css("a")
  end
end

RSpec.configure do |config|
  config.include MonthOverviewRequestHelpers, type: :request
end
