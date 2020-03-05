//
//  Effect.swift
//  GestureRecognizerWithARKit
//
//  Created by FelixZhao on 2019/10/20.
//  Copyright © 2019 FelixZhao. All rights reserved.
//
import ARKit
import SceneKit

// MARK: 场景
public class Scene: SCNNode {
    var particle: SCNParticleSystem!
    var node: SCNNode!
    init(type: EffectType) {
        super.init()
        switch type {
        case .dream:
            particle = SCNParticleSystem(named: "dream.scnp", inDirectory: nil)!
            node = SCNNode()
            node.position = SCNVector3(x: 0, y: 0, z: -5)
        case .snow:
            particle = SCNParticleSystem(named: "snow.scnp", inDirectory: nil)!
            node = SCNNode()
            node.position = SCNVector3(x: 0, y: 5, z: 0)
            node.eulerAngles = SCNVector3(x: -Float.pi / 2, y: 0, z: 0)
        case .twinkle:
            particle = SCNParticleSystem(named: "twinkle.scnp", inDirectory: nil)!
            node = SCNNode()
            node.position = SCNVector3(x: 0, y: 0, z: 0)
       
        }
        node.addParticleSystem(particle)
        self.addChildNode(node)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum EffectType {
    case dream,twinkle,snow
}


// MARK: - 扩展
extension SCNVector3 {
    // 获取相机位置
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}
