# frozen_string_literal: true

# 用 GitHub App 私钥签发 JWT，换取 installation access token 并输出到 stdout。
# 供 azure-pipelines.yml 的 "Push to Github Pages" 步骤使用，替代会过期的 PAT。
#
# 依赖环境变量：
#   GITHUB_APP_ID        GitHub App 的 App ID
#   GITHUB_APP_KEY_PATH  GitHub App 私钥（PEM）文件路径
#   GITHUB_USERNAME      目标仓库所属账号（用于定位 installation）
#   GITHUB_APP_INSTALLATION_ID  （可选）直接指定 installation ID，跳过查询

require 'openssl'
require 'base64'
require 'json'
require 'net/http'
require 'uri'

def b64url(data)
  Base64.urlsafe_encode64(data).delete('=')
end

def github_api(method, path, jwt, body = nil)
  uri = URI("https://api.github.com#{path}")
  req = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{jwt}"
  req['Accept'] = 'application/vnd.github+json'
  req['X-GitHub-Api-Version'] = '2022-11-28'
  req['User-Agent'] = 'azure-pipelines-github-app-auth'
  req['Content-Type'] = 'application/json'
  req.body = JSON.generate(body) if body

  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  unless res.code.start_with?('2')
    warn "GitHub API #{method.to_s.upcase} #{path} failed: #{res.code} #{res.body}"
    exit 1
  end
  JSON.parse(res.body)
end

app_id   = ENV.fetch('GITHUB_APP_ID')
key_path = ENV.fetch('GITHUB_APP_KEY_PATH')
owner    = ENV.fetch('GITHUB_USERNAME')

key = OpenSSL::PKey::RSA.new(File.read(key_path))

# JWT：iat 回拨 60 秒容忍时钟偏差，exp 最长 10 分钟
now     = Time.now.to_i
header  = b64url(JSON.generate(alg: 'RS256', typ: 'JWT'))
payload = b64url(JSON.generate(iat: now - 60, exp: now + 9 * 60, iss: app_id))
sig     = b64url(key.sign(OpenSSL::Digest.new('SHA256'), "#{header}.#{payload}"))
jwt     = "#{header}.#{payload}.#{sig}"

installation_id = ENV['GITHUB_APP_INSTALLATION_ID']
if installation_id.nil? || installation_id.empty?
  installations = github_api(:get, '/app/installations', jwt)
  inst = installations.find { |i| i.dig('account', 'login') == owner }
  abort("No GitHub App installation found for account '#{owner}'") unless inst
  installation_id = inst['id']
end

token = github_api(:post, "/app/installations/#{installation_id}/access_tokens", jwt,
                   { permissions: { contents: 'write' } })

# 只把 token 写到 stdout，供调用方捕获；勿在其他地方打印
puts token.fetch('token')
