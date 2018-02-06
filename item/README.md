Qiitaの記事はいつもローカルのテキストエディタで書いてコピペして投稿していました。

これがちょっとめんどくさい。

Qiitaの記事もGitで管理できた方が楽だよなーという思いもあって、
GitHubへのpushをトリガーにTravisCIを起動して、
Qiitaの記事を自動で投稿＆更新できるようにしました。


今回の記事を作成するにあたり、以下の記事を大いに参考にさせていただいています。

- [GitHub 上のマークダウンを Travis CI 経由で Qiita に記事として投稿する](https://qiita.com/miya0001/items/5702a6e4bba0535582f9)


この記事との違いはdeployスクリプトをrubyにしている点と、
自分が使いやすいように細かい部分を変えています。


## 環境イメージ

![configuration_image](https://raw.githubusercontent.com/rednes/github2qiita/master/item/image/configuration_image.png)

## Qiita個人用アクセストークン取得

まずはQiita APIを使用するため、Qiitaの個人用アクセストークンを取得してメモしておきます。

https://qiita.com/settings/applications


![qiita_token](https://raw.githubusercontent.com/rednes/github2qiita/master/item/image/qiita_token.png)

## Qiitaに投稿するスクリプトを作成

今回はRubyのQiita APIライブラリを使用しました。
必要なライブラリを`Gemfile`に書いておきます。

```ruby:Gemfile
gem 'qiita', '1.3.5'
gem 'json', '2.1.0'
```

デプロイ用のスクリプトも準備します。

```ruby:deploy/deploy.rb
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
```

タイトルやタグは`item/params.json`で定義します。

```json:item/params.json
{
    "title": "Qiitaの記事をGitHubで管理してTravisCI経由で自動投稿する",
    "tags": [
        {
            "name": "GitHub",
            "versions": []
        },
        {
            "name": "TravisCI",
            "versions": []
        }
    ],
    "coediting": false,
    "gist": false,
    "private": false,
    "tweet": false
}
```

`item/ITEM_ID`に更新したい記事のIDを保存しておくと、
そのIDの記事を更新するようにします。

```:item/ITEM_ID
2d76435434ac632fc6d4
```


デプロイ用のスクリプトでは以下の環境変数を使用しています。

- QIITA_TOKEN - 個人用アクセストークン

そのため、メモしておいたQiitaの個人用アクセストークンを環境変数としてQIITA_TOKENに設定すれば、
ローカル環境から`item/README.md`の記事を投稿できるようになります。

```sh
# 環境変数の設定
$ export QIITA_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

```sh
# デプロイ用スクリプトの実行
$ bundle exec ruby deploy/deploy.rb
```

次はTravisCIを利用して自動投稿できるようにしましょう。


## .travis.ymlの作成

`travis init`で`.travis.yml`の初期作成とTravis CIを有効化しましょう。

```sh
$ travis init
Main programming language used: |Ruby|
.travis.yml file created!
rednes/github2qiita: enabled :)
```

Qiitaの個人用アクセストークンは暗号化して`.travis.yml`に追加します。

```sh
$ travis encrypt QIITA_TOKEN=XXXXXX --add
```

先ほど作成したデプロイスクリプトが自動で動くように記述します。
ついでにプルリクの時は動かないようにしておきます。

```yaml
script:
  - 'if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then bundle exec ruby deploy/deploy.rb; fi'
```

ライブラリのインストールも記述しておきましょう。
何度もライブラリインストールするのも時間がかかるのでキャッシュを残すようにしておきます。

```yaml
install: bundle install
cache:
  directories: vendor/bundle
```

masterブランチ以外のコミットでは動かないようにしておきます。

```yaml
branches:
  only:
    - master
```

`.travis.yml`を全部書くとこんな感じになります。

```yaml:.travis.yml
language: ruby
rvm: 2.4.1
branches:
  only:
    - master
install: bundle install
cache:
  directories: vendor/bundle
script:
  - 'if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then bundle exec ruby deploy/deploy.rb; fi'
env:
  global:
    - secure: XXXXXX
```

最後にGitHubからTravisCI経由でQiitaに投稿される流れを確認しましょう。

## GitHubからTravisCI経由での投稿

`item/README.md`に記事が書けたらまとめてコミットしてgit pushします。

```sh
$ git add -A
$ git commit -m "Qiitaの記事をGitHubで管理してTravisCi経由で自動投稿する作成"
$ git push
```

GitHubへの`git push`をトリガーにTravisCIが動きます。

![TravisCI](https://raw.githubusercontent.com/rednes/github2qiita/master/item/image/travisci.png)

ビルドが終わるとQiitaに記事が投稿され、Qiitaへの自動投稿ができるようになりました。

![Qiita](https://raw.githubusercontent.com/rednes/github2qiita/master/item/image/qiita.png)


今回の記事は以下のGitHubリポジトリから自動投稿しています。
興味のある方はこちらもどうぞ。

https://github.com/rednes/github2qiita


