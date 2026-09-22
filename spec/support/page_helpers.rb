# Markup anchors for request specs: rows and notices are located through data-* hooks, never class strings.
module PageHelpers
  def page_doc(body)
    Nokogiri::HTML(body)
  end

  def error_notice(body)
    page_doc(body).at_css('p[role="alert"][data-notice="error"]')
  end

  def error_notice_text(body)
    error_notice(body)&.text&.strip
  end

  def rows(body, name)
    page_doc(body).css(%(li[data-row="#{name}"]))
  end

  def row(body, name, **attrs)
    selector = attrs.map { |key, value| %([data-#{key.to_s.tr('_', '-')}="#{value}"]) }.join
    page_doc(body).at_css(%(li[data-row="#{name}"]#{selector}))
  end

  def rows_html(body, name)
    rows(body, name).map(&:to_html)
  end
end

RSpec.configure do |config|
  config.include PageHelpers
end
