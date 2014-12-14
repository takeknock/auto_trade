#TODO:リファクタリング。orderなどかぶっている機能をまとめて、buy、sellそれぞれに継承するようにする
#思考部分はDeep Learningで学習。RRDB使って高速化。思考部分はC++で書くべき


require "selenium-webdriver"
require "csv"

$PATH = ''

#楽天証券のIDとPW
$ID = ""
$PW = ""

#暗証番号
$ORDERNUM = ""

class RakutenSec
	def login_rakuten_sec
		driver = Selenium::WebDriver.for :firefox
		driver.navigate.to "https://www.rakuten-sec.co.jp/"

		element = driver.find_element(:name, 'loginid')
		element.send_keys $ID

		element2 = driver.find_element(:name, 'passwd')
		element2.send_keys $PW

		begin
			element2.submit
		rescue
			puts "ログインに失敗しました"
		else
			puts "ログインできました。"
		end
		driver
	end

end

class GetValueR
	def initialize
		@driver = login_rakuten_sec()
	end

end
class GetValues < RakutenSec
	def initialize
		@driver = login_rakuten_sec()
	end

	def get_favstock_value
	#お気に入りに登録している銘柄を一挙に
		driver = @driver

		#ホームに戻る
		driver.find_element(:xpath, '//*[@id="siteID"]/a').click

		#10番をクリック
		driver.find_element(:xpath, '//*[@id="home_favorite_paging"]/ul/li[10]/a')

	end


	def get_asset_value
		driver = @driver

		#ホームに戻る
		#driver.find_element(:xpath, '//*[@id="siteID"]/a').click

		#評価額合計取得
		asset_value =  driver.find_element(:xpath, '//*[@id="balancelist_tbody"]/tr[1]/td[1]/nobr/strong').text

		#数字のみ抽出
		asset_value = asset_value.gsub(/[^0-9]/,"").to_i

		a = [Time.now.strftime("%Y-%m-%d %H:%M:%S"), asset_value]
		driver.quit
		return a
	end
end

class AutoOrder < RakutenSec
	def initialize
		@driver = login_rakuten_sec()
	end


	def order_buy(sec_code)
		driver = @driver

		#ホームに戻る
		#driver.find_element(:xpath, '//*[@id="siteID"]/a').click

		begin
			driver.find_element(:xpath, '//*[@id="nav-main-menu"]/ul/li[3]/a').click
		rescue
			puts "画面遷移に失敗しました\n"
		else
			puts "国内株式画面に遷移成功"
		end

		#国内株式にて引数で受け取った銘柄コードを検索
		sec_form = driver.find_element(:xpath, '//*[@id="dscrCdNm2"]')
		sec_form.send_keys sec_code
		begin
			sec_form.submit
		rescue
			puts "銘柄検索に失敗\n"
		else
			puts sec_code.to_s+"の銘柄画面表示"
		end

		#買い注文画面に移動
		begin
			driver.find_element(:xpath, '//*[@id="auto_update_field_info_jp_stock_price"]/tbody/tr/td[1]/form[2]/div[2]/table[1]/tbody/tr/td[2]/div/div[2]/table/tbody/tr/td[1]/ul[1]/li[1]/a').click
		rescue
			puts "買い注文画面への遷移に失敗しました"
		else
			puts "買い注文画面に移動しました"
		end

		#最低単元を取得
		min_order = driver.find_element(:xpath, '//*[@id="pricetable1"]/tbody/tr[1]/td[2]/table/tbody/tr/td[2]/div').text.gsub(/[^0-9]/,"").to_i
		puts "最低単元: "+min_order.to_s
		number_form = driver.find_element(:xpath, '//*[@id="pricetable1"]/tbody/tr[1]/td[2]/table/tbody/tr/td[1]/table/tbody/tr/td[1]/div/input')
		#今は仮で最低単元だけ注文出す
		number_form.send_keys min_order

		#1:成行
		driver.find_element(:id, 'priceMarket').click
		#0:指値
		#value_form = driver.find_element(:xpath, '//*[@id="pricetable1"]/tbody/tr[2]/td/table/tbody/tr/td[1]/div/input[2]')
		#value_form.send_keys "143"

		#取引暗証番号入力
		a_form = driver.find_element(:xpath, '//*[@id="auto_update_field_stock_price"]/tbody/tr/td[1]/table[6]/tbody/tr/td/table[1]/tbody/tr/td/table/tbody/tr[1]/td[4]/nobr/input')
		a_form.send_keys $ORDERNUM

		#確認画面の省略	
		chkbox = driver.find_element(:xpath, '//*[@id="ormit_checkbox"]')
		chkbox.click

		#発注ボタンクリック
		begin
			#driver.find_element(:xpath, '//*[@id="ormit_sbm"]').click
		rescue
			puts "注文に失敗しました"
		else
			puts "注文が完了しました"
		end
		sleep 5
		#driver.quit
	end

	def order_sell(code, value)
		driver = @driver


	end


	def quit_browser()
		@driver.quit
	end

end

def get_nikkei(driver)
	#すでにbrowserが起動されてることを前提として使う
	begin
		driver.navigate.to 'http://stocks.finance.yahoo.co.jp/stocks/detail/?code=998407.O'
	rescue
		puts "画面遷移に失敗しました"
	end

	name = "日経平均株価"
	begin
		value = driver.find_element(:xpath, '//*[@id="main"]/div[2]/div[1]/div[2]/table/tbody/tr/td[2]').text
	rescue
		puts "日経平均株価の値の取得に失敗しました。"
	end

	puts name+": "+value
end

def get_sec_value(arr)
	puts Time.now.strftime("%Y-%m-%d %H:%M:%S")
	driver = Selenium::WebDriver.for :firefox
	driver.manage.window.resize_to(100,100)

	get_nikkei(driver)

	arr.each { |code| 
		#form = driver.find_element(:xpath, '//*[@id="searchText"]')
		#form.send_keys code
		code = code.to_s

		begin
			#driver.submit
			#driver.find_element(:xpath, '//*[@id="searchButton"]').click
			driver.navigate.to 'http://stocks.finance.yahoo.co.jp/stocks/detail/?code='+code+'.T'
		rescue
			puts code.to_s+"のページに遷移できませんでした"
			driver.quit
		end
		name = driver.find_element(:xpath, '//*[@id="main"]/div[3]/div[1]/div[2]/table/tbody/tr/th/h1').text
		value = driver.find_element(:xpath, '//*[@id="main"]/div[3]/div[1]/div[2]/table/tbody/tr/td[2]').text
		puts "["+code+"]"+name+": "+value

	}
	driver.quit
end

def seq_get_sec_value(arr)
	c=9000

	while c >= 0 do
		puts Time.now.strftime("%Y-%m-%d %H:%M:%S")
		driver = Selenium::WebDriver.for :firefox
		driver.manage.window.resize_to(100,100)
		i = 0

		get_nikkei(driver)
		t = Array.new()
		t.push(Time.now.strftime("%H:%M:%S"))
		arr.each { |code| 
			#form = driver.find_element(:xpath, '//*[@id="searchText"]')
			#form.send_keys code
			code = code.to_s

			begin
				#driver.submit
				#driver.find_element(:xpath, '//*[@id="searchButton"]').click
				driver.navigate.to 'http://stocks.finance.yahoo.co.jp/stocks/detail/?code='+code+'.T'
			rescue
				puts code.to_s+"のページに遷移できませんでした"
				driver.quit
			end
			name = driver.find_element(:xpath, '//*[@id="main"]/div[3]/div[1]/div[2]/table/tbody/tr/th/h1').text
			value = driver.find_element(:xpath, '//*[@id="main"]/div[3]/div[1]/div[2]/table/tbody/tr/td[2]').text
			t.push(value.to_i)
			puts "["+code+"]"+name+": "+value
		}
		c = c-300
		driver.quit
		sleep 5
	end
end

def save(arr)
	#TODO: 動くようにする
	outfile File.open('/Users/mmatthew_43/Dropbox/stock/seqvalue/test.csv', 'a')
	CSV::Writer.generate(outfile) do |writer|
		writer << arr
	end
end

#puts "現在の評価額合計: "+get_asset_value().to_s


#a= GetValues.new()
#i= a.get_asset_value()
#puts i[0]+"時点の資産評価額合計は"+i[1].to_s+"円です！"


#a.order_buy(9468)

#a = Array.new()
#kanshi = [9468, 7261]
#kanshi.each do |code|
#	a.push(code)
#end
#
#now = [8306]
#now.each do |code|
#	a.push(code)
#end
#get_sec_value(a)
#
