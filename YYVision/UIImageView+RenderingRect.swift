//
//  UIImageView+RenderingRect.swift
//  YYVision
//
//  Created by YYLittleCat on 2023/12/4.
//

import UIKit

extension UIImageView {
    func renderingRectForImage() -> CGRect? {
        guard let image = self.image else {
            return CGRect.zero
        }
        
        // 获取 UIImageView 的显示区域
        let imageViewBounds = self.frame
        
        // 获取图片的实际大小
        let imageSize = image.size
        
        // 获取 contentMode 和 contentScaleFactor 属性
        let contentMode = self.contentMode
        let contentScaleFactor = self.contentScaleFactor
        
        // 计算图片在 UIImageView 中的渲染区域
        var renderingRect = CGRect.zero
        
        switch contentMode {
        case .scaleToFill:
            renderingRect = imageViewBounds
            
        case .scaleAspectFit:
            let scale = min(imageViewBounds.width / imageSize.width, imageViewBounds.height / imageSize.height)
            let width = imageSize.width * scale
            let height = imageSize.height * scale
            renderingRect.size = CGSize(width: width, height: height)
            renderingRect.origin.x = (imageViewBounds.width - width) / 2
            renderingRect.origin.y = (imageViewBounds.height - height) / 2
            
        case .scaleAspectFill:
            let scale = max(imageViewBounds.width / imageSize.width, imageViewBounds.height / imageSize.height)
            let width = imageSize.width * scale
            let height = imageSize.height * scale
            renderingRect.size = CGSize(width: width, height: height)
            renderingRect.origin.x = (imageViewBounds.width - width) / 2
            renderingRect.origin.y = (imageViewBounds.height - height) / 2
            
        case .center:
            renderingRect.size = imageSize
            renderingRect.origin.x = (imageViewBounds.width - imageSize.width) / 2
            renderingRect.origin.y = (imageViewBounds.height - imageSize.height) / 2
            
        // 其他 contentMode 类型可以根据需要进行扩展
        
        default:
            break
        }
        
        // 考虑 contentScaleFactor
        renderingRect.origin.x *= contentScaleFactor
        renderingRect.origin.y *= contentScaleFactor
        renderingRect.size.width *= contentScaleFactor
        renderingRect.size.height *= contentScaleFactor
        
        return renderingRect
    }
}
