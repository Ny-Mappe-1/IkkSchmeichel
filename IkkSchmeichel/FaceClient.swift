import Foundation
import Alamofire
import Dollar

let base = "https://westeurope.api.cognitive.microsoft.com/face/v1.0"
let headers = ["Ocp-Apim-Subscription-Key": Secrets.fetch("AZURE_FACE_KEY"), "Accept": "application/json"]
let octetHeaders = `$`.merge(headers, ["Content-Type": "application/octet-stream"])
let groupId = "not-schmeichel"
let schmeichelId = "cd09bae0-399c-45e7-a7c6-ca6dc483537b"

class FaceClient {
    struct Result {
        let face: Bool
        let identical: Bool
        let confidence: Float
        let json: Any?
    }
    
    static func check(data: Data, progressHandler: ((Progress) -> Void)?, handler: @escaping ((Result) -> Void)) -> Void {
        let url = "\(base)/detect?returnFaceId=true&faceLandmarks=true&returnFaceAttributes=age,gender,headPose,smile,facialHair,glasses,emotion,hair,makeup,occlusion,accessories,blur,exposure,noise"
        Alamofire.upload(data, to: url, method: .post, headers: octetHeaders)
            .uploadProgress { progress in
                if progressHandler != nil {
                    progressHandler!(progress)
                }
            }
            .responseJSON { data in
                guard let json = data.result.value as? [[String: Any]] else { debugPrint(data); return }
                
                print(json)
                
                guard json.count > 0 else {
                    handler(FaceClient.Result(face: false, identical: false, confidence: 1, json: json))
                    return
                }
                
                let id = json[0]["faceId"]!
                let params = [
                    "faceId": id,
                    "personGroupId": groupId,
                    "personId": schmeichelId
                ]
                
                Alamofire.request("\(base)/verify", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { data in
                    guard let verifyJson = data.result.value as? [String : Any] else { debugPrint(data); return }
                    
                    print(verifyJson)
                    
                    handler(
                        FaceClient.Result(
                            face: true,
                            identical: (verifyJson["isIdentical"] as! Int) == 1,
                            confidence: verifyJson["confidence"] as! Float,
                            json: json
                        )
                    )
                }
        }
    }
}
