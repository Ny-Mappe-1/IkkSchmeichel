require 'bundler/setup'
Bundler.require(:default)
Dotenv.load!
require 'json'

GROUP_ID = ENV.fetch('GROUP_ID')
SCHMEICHEL_ID = ENV.fetch('PERSON_ID')
BASE_URL = "https://westeurope.api.cognitive.microsoft.com/face/v1.0/"

CONN = Faraday.new(url: BASE_URL) do |f|
  f.headers['Content-Type'] = 'application/json'
  f.headers['Ocp-Apim-Subscription-Key'] = ENV.fetch('SUB_ID')
  f.request :json
  f.response :json
  # f.response :logger
  f.adapter Faraday.default_adapter
end

def file_upload path
  ->(req) {
    req.headers['Content-Type'] = 'application/octet-stream'
    req.body = File.read(path)
  }
end

def learn_face person_id, path
  url = "persongroups/#{GROUP_ID}/persons/#{person_id}/persistedFaces" 
  CONN.post url, &file_upload(path)
end

def compare_face path
  detect = CONN.post('detect?returnFaceAttributes=age,gender,headPose,smile,facialHair,glasses,emotion,hair,makeup,occlusion,accessories,blur,exposure,noise', &file_upload(path)).body

  if detect.empty?
    puts detect.inspect
    exit 1
  end

  puts detect
  exit 0

  face_id = detect.first["faceId"]

  opts = {
    faceId: face_id,
    personGroupId: GROUP_ID,
    personId: SCHMEICHEL_ID
  }

  resp = CONN.post 'verify', opts

  resp.body
end

# Dir['fixtures/*.*'].each { |path| learn_face SCHMEICHEL_ID, path; puts path }

# puts compare_face 'fixtures/hjortshoej.png'
puts compare_face ARGV.shift || 'test.jpg'
