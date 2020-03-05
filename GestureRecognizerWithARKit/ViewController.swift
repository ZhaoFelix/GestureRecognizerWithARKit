//
//  ViewController.swift
//  GestureRecognizerWithARKit
//
//  Created by FelixZhao on 2019/10/18.
//  Copyright © 2019 FelixZhao. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision //导入视觉处理库
import SpriteKit

class ViewController: UIViewController, ARSCNViewDelegate,ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var resultView: UITextView!
    var visionRequest = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.felix.dispatchqueueml") // 创建一个线程队列
    var planeNode:SCNNode?
    var predictTimer:Timer?
    var nodeArr:[SCNNode] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        //设置代理
        sceneView.delegate = self
        // 是否显示运行信息
        sceneView.showsStatistics = false
        // 创建一个场景
        let scene = SCNScene()
        // 将视图添加到场景中
        sceneView.scene = scene
        //设置一个灯光效果
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        //模型加载
        getMLModel()
    }
    //MARK:- 获取模型并创建模型请求
    func getMLModel() {
        //获取模型
        guard let selectedModel = try? VNCoreMLModel(for: HandGesture().model) else {
            fatalError("模型获取失败")
        }
        //创建模型请求
        let classificationRequest = VNCoreMLRequest(model: selectedModel,completionHandler:completeHandler(request:error:))
        classificationRequest.imageCropAndScaleOption = .centerCrop //对图片进行裁切
        visionRequest = [classificationRequest]
        
        //持续更新CoreML
        loopCoreMLUpdate()
    }
    
    //循环更新MLModel
    func loopCoreMLUpdate() {
        dispatchQueueML.async {
            self.updateCoreML()
            self.loopCoreMLUpdate()
        }
    }
    
    //实时更新CoreML
    func updateCoreML() {
        //通过相机获取图片
        let pixbuff = sceneView.session.currentFrame?.capturedImage
        
        guard let pixBuff = pixbuff else {return}
        let ciImage = CIImage(cvPixelBuffer: pixBuff)
        //设置传给模型图片的参数
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        //运行模型
        do {
            try imageRequestHandler.perform(self.visionRequest)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //对识别后的结果进行处理
    func completeHandler(request:VNRequest,error:Error?) {
        if error != nil {
            print("Error: " + (error!.localizedDescription))
            return
        }
        guard let observations = request.results  else {
            print("未识别到对象")
            return
        }
        
        let classification = observations[0...1] //获取识别结果的前两个
            .compactMap({$0 as? VNClassificationObservation})
            .map({"\($0.identifier) \(String(format: "- %.2f", $0.confidence))"})
            .joined(separator: "\n")
        
        let results = observations[0...1]
            .compactMap({$0 as? VNClassificationObservation})
        DispatchQueue.main.async {
            //在顶部的视图上显示预测的结果
            var result = "识别的结果为：\n"
            result += classification
            self.resultView.text = result
            self.responseRecongnizeResult(result: results.map({$0.identifier})[0], confidence: results.map({$0.confidence})[0])
        }
    }
    
    
    //响应识别后的结果
    func responseRecongnizeResult(result:String,confidence:Float) {
        //当识别的对象为Spider的概率大于90%时
        if result == "spider" &&  confidence  > 0.95 {
            if predictTimer == nil {
                var index = 0
                predictTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (t) in
                    index += 1
                    if index == 3 {
                        print("spider持续两秒")
                        //添加识别后的AR效果
                        self.addCoolEffect(type: "spider")
                        //关闭计时器
                        t.invalidate()
                        self.predictTimer = nil
                    }
                })
                
            }
            
        }
            //当识别的对象为zero的概率大于90%时
        else if result == "zero" && confidence > 0.95 {
            print("zero")
            if predictTimer == nil {
                var index = 0
                predictTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (t) in
                    index += 1
                    if index == 3 {
                        print("zero持续两秒")
                        self.addCoolEffect(type: "zero")
                        t.invalidate()
                        self.predictTimer = nil
                    }
                })
            }
        }
            //当识别的对象为none的概率大于95%时
        else if result == "none" && confidence > 0.95{
            if predictTimer != nil {
                predictTimer?.invalidate()
                predictTimer = nil
            }
        }
    }
    
    //根据结果添加效果
    func addCoolEffect(type:String) {
        // 获取当前相机状态
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            return
        }
        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
        if !nodeArr.isEmpty {
            nodeArr.map({$0.removeFromParentNode()})
        }
        switch type {
        case "spider":
            //设置AR效果的类型，type可分别设置为：.brem,.snow,.twinkle
            let node = Scene(type: .dream)
            node.position = cameraPos
            sceneView.scene.rootNode.addChildNode(node)
            nodeArr.append(node)
        case "zero":
            let node = Scene(type: .snow)
            node.position = cameraPos
            sceneView.scene.rootNode.addChildNode(node)
            nodeArr.append(node)
        default:
            return
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 创建世界追踪
        let configuration = ARWorldTrackingConfiguration()
        // 运行AR会话
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 当视图消失时停止会话
        sceneView.session.pause()
    }
    
    //隐藏顶部的状态栏
    override var prefersStatusBarHidden: Bool {
        return  true
    }
}
