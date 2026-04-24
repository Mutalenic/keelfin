class DpoPayService
  BASE_URL = 'https://secure.3gdirectpay.com/API/v6/'.freeze
  COMPANY_TOKEN = ENV.fetch('DPO_COMPANY_TOKEN', '')

  Result = Struct.new(:success?, :transaction_token, :redirect_url, :error, keyword_init: true)

  def initialize(user:, plan_name:, amount:)
    @user = user
    @plan_name = plan_name
    @amount = amount.to_f
  end

  def create_token
    return Result.new(success?: false, error: 'DPO_COMPANY_TOKEN not configured') if COMPANY_TOKEN.blank?

    xml_body = build_create_token_xml
    response = post_xml('createToken', xml_body)
    parse_create_token_response(response)
  rescue StandardError => e
    Rails.logger.error "DpoPayService#create_token error: #{e.message}"
    Result.new(success?: false, error: e.message)
  end

  def verify_payment(transaction_token)
    return Result.new(success?: false, error: 'DPO_COMPANY_TOKEN not configured') if COMPANY_TOKEN.blank?

    xml_body = build_verify_xml(transaction_token)
    response = post_xml('verifyToken', xml_body)
    parse_verify_response(response)
  rescue StandardError => e
    Rails.logger.error "DpoPayService#verify_payment error: #{e.message}"
    Result.new(success?: false, error: e.message)
  end

  private

  def post_xml(endpoint, body)
    require 'net/http'
    uri = URI("#{BASE_URL}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 15
    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/xml')
    request.body = body
    http.request(request)
  end

  def build_create_token_xml
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <API3G>
        <CompanyToken>#{COMPANY_TOKEN}</CompanyToken>
        <Request>createToken</Request>
        <Transaction>
          <PaymentAmount>#{format('%.2f', @amount)}</PaymentAmount>
          <PaymentCurrency>ZMW</PaymentCurrency>
          <CompanyRef>KEELFIN-#{@user.id}-#{@plan_name}-#{Time.now.to_i}</CompanyRef>
          <RedirectURL>#{Rails.application.routes.url_helpers.dpo_callback_subscription_url(host: ENV.fetch('APP_HOST', 'localhost:3000'))}</RedirectURL>
          <BackURL>#{Rails.application.routes.url_helpers.plans_subscription_url(host: ENV.fetch('APP_HOST', 'localhost:3000'))}</BackURL>
          <TransactionSource>keelfin-web</TransactionSource>
        </Transaction>
        <Services>
          <Service>
            <ServiceType>3854</ServiceType>
            <ServiceDescription>Keelfin #{@plan_name.capitalize} Plan — 1 month</ServiceDescription>
            <ServiceDate>#{Date.current.strftime('%Y/%m/%d %H:%M')}</ServiceDate>
          </Service>
        </Services>
      </API3G>
    XML
  end

  def build_verify_xml(token)
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <API3G>
        <CompanyToken>#{COMPANY_TOKEN}</CompanyToken>
        <Request>verifyToken</Request>
        <TransactionToken>#{token}</TransactionToken>
      </API3G>
    XML
  end

  def parse_create_token_response(response)
    require 'rexml/document'
    doc = REXML::Document.new(response.body)
    result_code = doc.elements['API3G/Result']&.text
    token = doc.elements['API3G/TransToken']&.text

    if result_code == '000' && token.present?
      redirect_url = "https://secure.3gdirectpay.com/payv2.php?ID=#{token}"
      Result.new(success?: true, transaction_token: token, redirect_url: redirect_url)
    else
      explanation = doc.elements['API3G/ResultExplanation']&.text || 'Unknown DPO error'
      Result.new(success?: false, error: "DPO #{result_code}: #{explanation}")
    end
  end

  def parse_verify_response(response)
    require 'rexml/document'
    doc = REXML::Document.new(response.body)
    result_code = doc.elements['API3G/Result']&.text

    if result_code == '000'
      Result.new(success?: true)
    else
      explanation = doc.elements['API3G/ResultExplanation']&.text || 'Payment not verified'
      Result.new(success?: false, error: explanation)
    end
  end
end
