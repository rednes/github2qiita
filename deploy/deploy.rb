require "rubygems"
require "bundler/setup"
require "qiita"
require "json"

PARAMS_FILE_PATH = 'item/params.json'
ITEM_ID_FILE_PATH = 'item/ITEM_ID'
BODY_FILE_PATH = 'item/README.md'

client = Qiita:: Client.new(access_token: ENV['QIITA_TOKEN'])

params = File.open(PARAMS_FILE_PATH) do |file|
  JSON.load(file)
end
headers = {'Content-Type' => 'application/json'}

body = File.open(BODY_FILE_PATH) do |file|
  file.read
end

params['body'] = body

if File.exist?(ITEM_ID_FILE_PATH) then
  item_id = File.open(ITEM_ID_FILE_PATH) do |file|
    file.read
  end
  p client.update_item(item_id, params, headers)
else
  p client.create_item(params, headers)
end
