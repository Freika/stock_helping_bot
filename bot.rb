require 'telegram/bot'
require 'net/http'
require 'json'
require 'byebug'
require 'dotenv/load'


class Bot
  TELEGRAM_TOKEN = ENV['TELEGRAM_TOKEN']
  IEXCLOUD_TOKEN = ENV['IEXCLOUD_TOKEN']

  p 'Bot just started'

  def start
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.listen do |message|
        if message&.text
          if extract_tickers(message).any?
            p "[#{Time.now}] Message from #{message.from.first_name}: #{message.text}"
            responses_array = prepare_respond_for(message)
            p "[#{Time.now} Response: #{responses_array}"

            responses_array.each do |response|
              bot.api.sendMessage(chat_id: message.chat.id, text: response, parse_mode: 'Markdown')
            end

            # case message.text
            # when '/start'
            #   text = "Hello, #{message.from.first_name}"
            #   p text
            #   bot.api.sendMessage(chat_id: message.chat.id, text: text)

            # end
          end
        end
      end
    end
  end

  private

  def prepare_respond_for(message)
    tickers = extract_tickers(message)

    tickers.map do |ticker|
      json = company_json(ticker)

      if json.is_a?(String) && json == 'Company not found'
        "#{ticker}: #{json}"
      else
        successful_response_text(json)
      end
    end
  end

  def extract_tickers(message)
    tickers = message.text.scan(/\$[A-Z]{1,5}/)
    tickers.map { |t| t.delete!('$') }
  end

  def company_json(ticker)
    uri     = URI("https://cloud.iexapis.com/stable/stock/#{ticker}/company?token=#{IEXCLOUD_TOKEN}")
    result  = Net::HTTP.get(uri)

    JSON.parse(result) rescue "Company not found"
  end

  def successful_response_text(json)
    link_text = "https://finance.yahoo.com/quote/#{json['symbol']}"
    company_description = json['description'][0..255]

    "#{link_text}\n\n#{company_description}..."
  end
end

Bot.new.start
