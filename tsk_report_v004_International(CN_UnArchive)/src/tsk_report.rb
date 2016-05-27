# coding: utf-8

require 'rubygems'
require 'nkf'
require 'net/http'
Net::HTTP.version_1_2
require 'rexml/document'
require 'time'
require 'digest/sha1'
require 'optparse'

require 'tenco_reporter/config_util'
include TencoReporter::ConfigUtil
require 'tenco_reporter/track_record_util'
include TencoReporter::TrackRecordUtil
# require './lib/tenco_reporter/stdout_to_cp932_converter'

# プログラム情報
PROGRAM_VERSION = '0.04'
PROGRAM_NAME = '天則観報告ツール'
PROGRAM_PATCH_VERSION = '1.1'
PROGRAM_PATCH_NAME = '天则观数据上传工具'
RECORD_SW_PATCH_NAME = '天则观'

# 設定
TRACKRECORD_POST_SIZE = 250   # 一度に送信する対戦結果数
DUPLICATION_LIMIT_TIME_SECONDS = 2   # タイムスタンプが何秒以内のデータを、重複データとみなすか
ACCOUNT_NAME_REGEX = /\A[a-zA-Z0-9_]{1,32}\z/
MAIL_ADDRESS_REGEX = /\A[\x01-\x7F]+@(([-a-z0-9]+\.)*[a-z]+|\[\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\])\z/ # メールアドレスチェック用正規表現
PLEASE_RETRY_FORCE_INSERT = "<Please Retry in Force-Insert Mode>"  # 強制インサートリトライのお願い文字列
HTTP_REQUEST_HEADER = {"User-Agent" => "Tensokukan Report Tool #{PROGRAM_VERSION}"}
RECORD_SW_NAME = '天則観' # 対戦記録ソフトウェア名
DB_TR_TABLE_NAME = 'trackrecord123' # DBの対戦結果テーブル名
WEB_SERVICE_NAME = 'Tenco!'  # サーバ側のサービス名

# デフォルト値
DEFAULT_GAME_ID = 2    # ゲームID
DEFAULT_DATABASE_FILE_PATH = '../*.db' # データベースファイルパス

# ログファイルパス
ERROR_LOG_PATH = 'error.txt'

# 送信設定
is_force_insert = false # 強制インサートモード。はじめは false。
is_all_report = false # 全件報告モード。サーバーからの最終対戦時刻をとらず、全件送信。

# 変数
latest_version = nil # クライアントの最新バージョン
trackrecord = [] # 対戦結果
is_read_trackrecord_warning = false # 対戦結果読み込み時に警告があったかどうか
is_warning_exist = false # 警告メッセージがあるかどうか

puts "*** #{PROGRAM_PATCH_NAME} ***"
puts "*** 国际版-简体中文#{PROGRAM_PATCH_VERSION} ***"
puts "兼容原版 ver.#{PROGRAM_VERSION}\n\n"

begin

  ### 設定読み込み ###

  # 設定ファイルパス
  config_file = 'config.yaml'
  config_default_file = 'config_default.yaml'
  env_file = 'env.yaml'

  # 設定ファイルがなければデフォルトをコピーして作成
  unless File.exist?(config_file) then
    open(config_default_file) do |s|
      open(config_file, "w") do |d|
        d.write(s.read)
      end
    end
  end

  # サーバー環境設定ファイルがなければ、エラー終了
  unless File.exist?(env_file) then
    raise "意外的没有找到 #{env_file} 。\n重新下载和解压整个程序来获得此文件。\n已下载的程序可能不完整。"
  end

  # 設定ファイル読み込み
  config = load_config(config_file) 
  env    = load_config(env_file)
      
  # config.yaml がおかしいと代入時にエラーが出ることに対する格好悪い対策
  config ||= {}
  config['account'] ||= {}
  config['database'] ||= {}

  account_name = config['account']['name'].to_s || ''
  account_password = config['account']['password'].to_s || ''

  # ゲームIDを設定ファイルから読み込む機能は -g オプションが必要
  game_id = DEFAULT_GAME_ID
  db_file_path = config['database']['file_path'].to_s || DEFAULT_DATABASE_FILE_PATH

  # proxy_host = config['proxy']['host']
  # proxy_port = config['proxy']['port']
  # last_report_time = config['last_report_time']
  # IS_USE_HTTPS = false

  SERVER_TRACK_RECORD_HOST = env['server']['track_record']['host'].to_s
  SERVER_TRACK_RECORD_PATH = env['server']['track_record']['path'].to_s
  SERVER_LAST_TRACK_RECORD_HOST = env['server']['last_track_record']['host'].to_s
  SERVER_LAST_TRACK_RECORD_PATH = env['server']['last_track_record']['path'].to_s
  SERVER_ACCOUNT_HOST = env['server']['account']['host'].to_s
  SERVER_ACCOUNT_PATH = env['server']['account']['path'].to_s
  CLIENT_LATEST_VERSION_HOST = env['client']['latest_version']['host'].to_s
  CLIENT_LATEST_VERSION_PATH = env['client']['latest_version']['path'].to_s
  CLIENT_SITE_URL = "http://#{env['client']['site']['host']}#{env['client']['site']['path']}"

  ### クライアント最新バージョンチェック ###

  # puts "★クライアント最新バージョン自動チェック"
  # puts 
  
  def get_latest_version(latest_version_host, latest_version_path)
    response = nil
    Net::HTTP.new(latest_version_host, 80).start do |s|
      response = s.get(latest_version_path, HTTP_REQUEST_HEADER)
    end  
    response.code == '200' ? response.body.strip : nil
  end
  
  begin
    latest_version = get_latest_version(CLIENT_LATEST_VERSION_HOST, CLIENT_LATEST_VERSION_PATH)
    
    case
    when latest_version.nil?
      # puts "！最新バージョンの取得に失敗しました。"
      # puts "スキップして続行します。"
    when latest_version > PROGRAM_VERSION then
      puts "★发现有新版本的#{PROGRAM_PATCH_NAME}可以使用。（ver.#{latest_version}）"
      puts "这是一个修改过的天则观数据上传工具，不支持内置自动更新。"
	  puts "请手动检查是否有新版本的国际版。"
	  puts "5秒后继续上传。"
	  sleep 5
    when latest_version <= PROGRAM_VERSION then
      # puts "お使いのバージョンは最新です。"
      # puts 
    end
    
  rescue => ex
    puts "！上传工具的自动检查更新意外失败。"
	puts "以下是详细错误信息"
	puts
    puts ex.to_s
    # puts ex.backtrace.join("\n")
    puts ex.class
    puts
	puts "现在无法连接到#{WEB_SERVICE_NAME}服务器，"
	puts "接下来的上传很可能会失败。"
    puts "跳过自动更新并继续。"
	sleep 5
    puts
  end
    
  ### メイン処理 ###

  ## オプション設定
  opt = OptionParser.new

  opt.on('-a') {|v| is_all_report = true} # 全件報告モード

  # 設定ファイルのゲームID設定を有効にする
  opt.on('-g') do |v|
    begin
      game_id = config['game']['id'].to_i
    rescue => ex
      raise "错误：无法从配置文件（#{config_file}）中读取用户ID。"
    end
    
    if game_id.nil? || game_id < 1 then
      raise "错误：配置文件（#{config_file}）中记录了不允许使用的ID。"
    end
    
    puts "★上传数据到ID： #{game_id} 。"  
  end

  # 設定ファイルのデータベースファイルパスをデフォルトに戻す
  opt.on('--database-filepath-default-overwrite') do |v|  
    puts "★重置配置文件#{RECORD_SW_PATCH_NAME}中保存的DB数据库文件路径"  
    puts "#{config_file} 中的#{RECORD_SW_PATCH_NAME}DB数据库文件路径更换为#{DEFAULT_DATABASE_FILE_PATH} ..."  
    config['database']['file_path'] = DEFAULT_DATABASE_FILE_PATH
    save_config(config_file, config)
    puts "配置文件已更新！"  
    puts
    exit
  end

  opt.parse!(ARGV)

  ## アカウント設定（新規アカウント登録／既存アカウント設定）処理
  unless (account_name && account_name =~ ACCOUNT_NAME_REGEX) then
    is_new_account = nil
    account_name = ''
    account_password = ''
    is_account_register_finish = false
    
    puts "★#{WEB_SERVICE_NAME} 新ID注册（首次使用时）\n"  
    puts "如果你第一次使用 #{WEB_SERVICE_NAME}，输入 1 之后按 Enter 键继续。"  
    puts "如果你之前注册过ID（例如绯行迹数据上传工具），输入 2 之后按 Enter 键登陆。\n"  
    puts
    print "> "
    
    while (input = gets)
      input.strip!
      if input == "1"
        is_new_account = true
        puts
        break
      elsif input == "2"
        is_new_account = false
        puts
        break
      end
      puts 
      puts "如果你第一次使用 #{WEB_SERVICE_NAME}，输入 1 之后按 Enter 键继续。"  
      puts "如果你之前注册过ID（例如绯行迹数据上传工具），输入 2 之后按 Enter 键登陆。\n"  
      puts
      print "> "
    end
    
    if is_new_account then
      
      puts "★ #{WEB_SERVICE_NAME} 新帐户注册\n"  
	  puts "注册过程相比原版修改了一些说明文字和注册建议。\n"
	  puts "请尽量按照以下说明进行注册而不是跟随原版说明。\n\n"
      
      while (!is_account_register_finish)
        # アカウント名入力
        puts "输入想要注册的帐户名称（Tenco! ID）\n"  
        puts "这个名称会作为你个人主页网址的一部分。\n"  
		puts "例如注册名称 nanashi 时，个人主页网址为\n"
		puts "http://tenco.info/game/2/account/nanashi/ \n\n"
        puts "（只能使用半角英文字母、数字和下划线 _ 。最长32位）\n\n"  
        print "帐户名> "  
        while (input = gets)
          input.strip!
          if input =~ ACCOUNT_NAME_REGEX then
            account_name = input
            puts 
            break
          else
            puts "！帐户名只能由半角英文字母、数字和下划线组成，并最长在32位，\n"
			puts "请输入符合要求的帐户名"
            print "帐户名> "  
          end
        end
        
        # パスワード入力
        puts "设置密码（长度8到16位，由半角英文字母、数字和下划线构成，不可以和帐户名相同）\n"  
        print "密码> "  
        while (input = gets)
          input.strip!
          if (input.length >= 4 and input.length <= 16 and input != account_name) then
            account_password = input
            break
          else
            puts "！密码只能由长度8到16位的半角英文字母、数字和下划线构成，不可以和帐户名相同，\n"
			puts "请输入符合要求的密码"
            print "密码> "  
          end
        end 
        
        print "确认密码> "  
        while (input = gets)
          input.strip!
          if (account_password == input) then
            puts 
            break
          else
            puts "！两次输入的密码不一致，请再检查一下\n"  
            print "确认密码> "  
          end
        end
        
        # メールアドレス入力
        puts "输入电子邮件地址（可选）\n"  
        puts "※只有忘记密码时才会用到电子邮件地址。\n"  
        puts "※如果不输入电子邮件，将无法在未来某天找回密码。\n"
		puts "直接按 Enter 键可以跳过这个步骤，但请一定保存好你的 config.yaml\n"
		puts "如果跳过，一旦忘记密码将无法挽回。\n"
        print "电子邮件地址> "  
        while (input = gets)
          input.strip!
          if (input == '') then
            account_mail_address = ''
            puts "未输入电子邮件地址。"  
            puts
            break
          elsif input =~ MAIL_ADDRESS_REGEX and input.length <= 256 then
            account_mail_address = input
            puts
            break
          else
            puts "！请输入正确格式、最长256位的电子邮件地址。"  
            print "メールアドレス> "  
          end
        end
        
        # 新規アカウントをサーバーに登録
        puts "帐户注册中...\n"  
        
        # アカウント XML 生成
        account_xml = REXML::Document.new
        account_xml << REXML::XMLDecl.new('1.0', 'UTF-8')
        account_element = account_xml.add_element("account")
        account_element.add_element('name').add_text(account_name)
        account_element.add_element('password').add_text(account_password)
        account_element.add_element('mail_address').add_text(account_mail_address)
        # サーバーに送信
        response = nil
        # http = Net::HTTP.new(SERVER_ACCOUNT_HOST, 443)
        # http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http = Net::HTTP.new(SERVER_ACCOUNT_HOST, 80)
        http.start do |s|
          response = s.post(SERVER_ACCOUNT_PATH, account_xml.to_s, HTTP_REQUEST_HEADER)
        end
        
        print "服务器返回了信息\n"  
        response.body.each_line do |line|
          puts "> #{line.encode('cp932', 'utf-8')}"
        end

        if response.code == '200' then
        # アカウント登録成功時
          is_account_register_finish = true
          config['account']['name'] = account_name
          config['account']['password'] = account_password
          
          save_config(config_file, config)
          
          puts 
          puts "帐户和凭据已保存到配置文件（密码将明文保存）。"
          puts "请确认一遍服务器返回的信息是否有异常。"
          puts
          puts "请按 Enter 键，将现有的天则观数据上传到刚刚注册的帐户..."
          gets
          
          puts "上传天则观数据..."
          puts
        else
        # アカウント登録失敗時
          puts "帐户注册意外失败，稍后再尝试一次...\n\n"
          sleep 1
        end
        
      end # while (!is_account_register_finish)
    else

      puts "★编辑配置文件\n"
      puts "#{WEB_SERVICE_NAME} 的帐户名和密码设置"
      puts "※如果不知道该怎样填写，在#{WEB_SERVICE_NAME}绯行迹数据上传工具等的#{config_file}中可以找到"
      puts 
      puts "输入你的 #{WEB_SERVICE_NAME} 帐户名"
      
      # アカウント名入力
      print "帐户名> "
      while (input = gets)
        input.strip!
        if input =~ ACCOUNT_NAME_REGEX then
          account_name = input
          puts 
          break
        else
            puts "！帐户名只能由半角英文字母、数字和下划线组成，并最长在32位，\n"
			puts "请输入符合要求的帐户名"
        end
        print "帐户名> "
      end
      
      # パスワード入力
      puts "输入你的帐户对应的密码\n"
      print "密码> "
      while (input = gets)
        input.strip!
        if (input.length >= 4 and input.length <= 16 and input != account_name) then
          account_password = input
          puts
          break
        else
            puts "！密码只能由长度8到16位的半角英文字母、数字和下划线构成，不可以和帐户名相同，\n"
			puts "请输入符合要求的密码"
        end
        print "密码> "
      end
      
      # 設定ファイル保存
      config['account']['name'] = account_name
      config['account']['password'] = account_password
      save_config(config_file, config)
      
      puts "帐户和凭据已保存到配置文件（密码将明文保存）。\n\n"
      puts "继续上传天则观数据...\n\n"
      
    end # if is_new_account
    
    sleep 2

  end

    
  ## 登録済みの最終対戦結果時刻を取得する
  unless is_all_report then
    puts "★获取最新一次的上传时间"
    puts "GET http://#{SERVER_LAST_TRACK_RECORD_HOST}#{SERVER_LAST_TRACK_RECORD_PATH}?game_id=#{game_id}&account_name=#{account_name}"

    http = Net::HTTP.new(SERVER_LAST_TRACK_RECORD_HOST, 80)
    response = nil
    http.start do |s|
      response = s.get("#{SERVER_LAST_TRACK_RECORD_PATH}?game_id=#{game_id}&account_name=#{account_name}", HTTP_REQUEST_HEADER)
    end

    if response.code == '200' or response.code == '204' then
      if (response.body and response.body != '') then
        last_report_time = Time.parse(response.body)
        puts "已上传的最后一次对战时间：#{last_report_time.strftime('%Y/%m/%d %H:%M:%S')}"
      else
        last_report_time = Time.at(0)
        puts "服务器上找不到已上传的对战结果"
      end
    else
      raise "获取最新一次的上传时间时发生无法处理的异常，程序将退出。"
    end
  else
    puts "★全部上传模式。不验证服务器上保存的最新上传时间，而直接上传数据库中记录的所有对战结果。"
    last_report_time = Time.at(0)
  end
  puts

  ## 対戦結果報告処理
  puts "★发送对战结果"
  puts ("从#{RECORD_SW_PATCH_NAME}的已保存记录中，上传" + last_report_time.strftime('%Y/%m/%d %H:%M:%S') + " 之后的对战结果。")
  puts

  # DBから対戦結果を取得
  db_files = Dir::glob(NKF.nkf('-Wsxm0 --cp932', db_file_path))

  if db_files.length > 0
    trackrecord, is_read_trackrecord_warning = read_trackrecord(db_files, last_report_time + 1)
    is_warning_exist = true if is_read_trackrecord_warning
  else
    raise <<-MSG
意外的没有找到#{config_file} 中设定的#{RECORD_SW_PATCH_NAME}数据库文件。
请确认#{PROGRAM_PATCH_NAME}的安装路径是否正确
　一般情况下，将整个#{PROGRAM_PATCH_NAME}目录放置在#{RECORD_SW_PATCH_NAME}所在的目录中。
如果手动修改过#{config_file} ，请再确认一遍是否存在错误。
    MSG
  end

  puts

  ## 報告対象データの送信処理

  # 報告対象データが0件なら送信しない
  if trackrecord.length == 0 then
    puts "没有发现需要上传的数据。"
  else
    
    # 対戦結果データを分割して送信
    0.step(trackrecord.length, TRACKRECORD_POST_SIZE) do |start_row_num|
      end_row_num = [start_row_num + TRACKRECORD_POST_SIZE - 1, trackrecord.length - 1].min
      response = nil # サーバーからのレスポンスデータ
      
      puts "发送#{trackrecord.length}中的#{start_row_num + 1}～#{end_row_num + 1}个对战结果#{is_force_insert ? "（Force Insert 模式）" : ""}...\n"
      
      # 送信用XML生成
      trackrecord_xml_string = trackrecord2xml_string(game_id, account_name, account_password, trackrecord[start_row_num..end_row_num], is_force_insert)
      File.open('./last_report_trackrecord.xml', 'w') do |w|
        w.puts trackrecord_xml_string
      end

      # データ送信
      # https = Net::HTTP.new(SERVER_TRACK_RECORD_HOST, 443)
      # https.use_ssl = true
      # https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      # https = Net::HTTP::Proxy(proxy_addr, proxy_port).new(SERVER_TRACK_RECORD_HOST,443)
      # https.ca_file = '/usr/share/ssl/cert.pem'
      # https.verify_depth = 5
      # https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http = Net::HTTP.new(SERVER_TRACK_RECORD_HOST, 80)
      http.start do |s|
        response = s.post(SERVER_TRACK_RECORD_PATH, trackrecord_xml_string, HTTP_REQUEST_HEADER)
      end
      
      # 送信結果表示
      puts "服务器返回的信息"
      response.body.each_line do |line|
        puts "> #{line.encode('cp932', 'utf-8')}"
      end
      puts
      
      if response.code == '200' then
        sleep 1
        # 特に表示しない
      else
        if response.body.index(PLEASE_RETRY_FORCE_INSERT)
          puts "尝试使用 Force Insert 模式上传，5秒后重试...\n\n"
          sleep 5
          is_force_insert = true
          redo
        else
          raise "上传过程中服务器发生无法处理的异常，程序将退出。"
        end
      end
    end
  end

  # 設定ファイル更新
  save_config(config_file, config)
      
  puts

  # 終了メッセージ出力
  if is_warning_exist then
    puts "对战结果上传已完成，但过程中出现了警告。"
    puts "请确认上传结果。"
    puts
    puts "按 Enter 键退出程序。"
    exit if gets
    puts
  else
    puts "对战结果已上传完成。"
  end

  sleep 3

### 全体エラー処理 ###
rescue => ex
  if config && config['account'] then
    config['account']['name']     = '<secret>' if config['account']['name']
    config['account']['password'] = '<secret>' if config['account']['password']
  end
  
  puts 
  puts "发生了无法处理的异常，程序将退出。\n"
  puts 
  puts '### 以下是详细错误信息 ###'
  puts
  puts ex.to_s
  puts ex.backtrace.join("\n")
  puts (config ? config.to_yaml : "")
  
  if response then
    puts
    puts "<服务器返回的信息>"
    puts "HTTP status code : #{response.code}"
    puts response.body
  end
  puts
  puts '### 以上是详细错误信息 ###'
  
  File.open(ERROR_LOG_PATH, 'a') do |log|
    log.puts "#{Time.now.strftime('%Y/%m/%d %H:%M:%S')} #{File::basename(__FILE__)} #{PROGRAM_VERSION}" 
    log.puts ex.to_s
    log.puts ex.backtrace.join("\n")
    log.puts config ? config.to_yaml : "config 还没有正确设置。"
    if response then
      log.puts "<服务器返回的信息>"
      log.puts "HTTP status code : #{response.code}"
      log.puts response.body
    end
    log.puts '********'
  end
  
  puts
  puts "以上错误内容已经保存到 #{ERROR_LOG_PATH} 。"
  puts
  
  puts "按 Enter 键结束上传。"
  exit if gets
end
