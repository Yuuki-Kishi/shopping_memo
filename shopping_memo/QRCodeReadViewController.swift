//
//  QRCodeReadViewController.swift
//  shopping_memo
//
//  Created by 岸　優樹 on 2023/09/14.
//

import UIKit
import AVFoundation
import FirebaseAuth
import FirebaseDatabase

class QRCodeReadViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var ref = DatabaseReference()
    var userIdString: String!
    var roomIdString: String!
    
    var userIdArray = [String]()

    //カメラ用のAVsessionインスタンス作成
    private let AVsession = AVCaptureSession()
    //カメラ画像を表示するレイヤー
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    // カメラの設定
    // 今回は背面カメラなのでposition: .back
    let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "QRコードリーダー"
        cameraInit()
        userIdString = Auth.auth().currentUser?.uid
        ref = Database.database().reference()
        ref.child("rooms").child(roomIdString).child("members").observe(.childAdded, with: { snapshot in
            let userId = snapshot.key
            self.userIdArray.append(userId)
        })
    }
    
    func cameraInit(){
        //カメラデバイスの取得
        let devices = discoverySession.devices
        
        //背面のカメラ情報を取得
        if let backCamera = devices.first {
            do {
                //カメラ入力をinputとして取得
                let input = try AVCaptureDeviceInput(device: backCamera)
                
                //Metadata情報（今回はQRコード）を取得する準備
                //AVssessionにinputを追加:既に追加されている場合を考慮してemptyチェックをする
                if AVsession.inputs.isEmpty {
                    AVsession.addInput(input)
                    //MetadataOutput型の出力用の箱を用意
                    let captureMetadataOutput = AVCaptureMetadataOutput()
                    //captureMetadataOutputに先ほど入力したinputのmetadataoutputを入れる
                    AVsession.addOutput(captureMetadataOutput)
                    //MetadataObjectsのdelegateに自己(self)をセット
                    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                    //Metadataの出力タイプをqrにセット
                    captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                    
                    //カメラ画像表示viewの準備とカメラの開始
                    //カメラ画像を表示するAVCaptureVideoPreviewLayer型のオブジェクトをsessionをAVsessionで初期化でプレビューレイヤを初期化
                    videoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: AVsession)
                    //カメラ画像を表示するvideoPreviewLayerの大きさをview（superview）の大きさに設定
                    videoPreviewLayer?.frame = view.layer.bounds
                    //カメラ画像を表示するvideoPreviewLayerをビューに追加
                    view.layer.addSublayer(videoPreviewLayer!)
                }
                //セッションの開始(今回はカメラの開始)
                DispatchQueue.global(qos: .background).async {
                    self.AVsession.startRunning()
                }
            } catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
            //カメラ画像にオブジェクトがあるか確認
            if metadataObjects.count == 0 {
                return
            }
            //オブジェクトの中身を確認
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            // metadataのtype： metadata.type
            // QRの中身： metadata.stringValue
            guard let value = metadata.stringValue else { return }
            //一旦て停止
            AVsession.stopRunning()
            
            if userIdArray.contains(value) {
                let alert: UIAlertController = UIAlertController(title: "招待する必要はありません。", message: "このユーザーはすでに招待されています。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler:  { action in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                let ac = UIAlertController(title: "読み取ったQRコード", message: value, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.userIdString = value
                    self.performSegue(withIdentifier: "toAMVC", sender: nil)
                }))
                ac.addAction(UIAlertAction(title: "リトライ", style: .cancel, handler: { _ in
                    self.AVsession.startRunning()
                }))
                self.present(ac, animated: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueのIDを確認して特定のsegueのときのみ動作させる
        if segue.identifier == "toAMVC" {
            let next = segue.destination as? AddMemberViewController
            next?.roomIdString = roomIdString
            next?.userIdString = userIdString
        }
    }
}
