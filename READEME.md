---
title: 一码归一码
date: 2023-11-21 18:12:32
tags: [iOS]
---

---

## Barcode

&#8195;&#8195;"Barcode"（条形码）是一种用于储存和检索数据的图形标识符。它通常由一系列宽度和间隙不同的条和空组成，用于表示数字、字母和其他字符。条形码在商业、物流、库存管理和其他领域广泛应用，以提高数据的追踪和管理效率。

条形码的主要类型包括一维码（1D Barcode）和二维码（2D Barcode）。

1. **一维码（1D Barcode）：** 一维码是由一系列宽度和间隙不同的条和空组成的图形，用于表示线性的数据。一维码主要用于表示数字、字母和其他特定字符。常见的一维码类型包括Code 39、Code 128、UPC、EAN等。
2. **二维码（2D Barcode）：** 二维码是由一系列黑白块组成的图形，可以在水平和垂直方向上表示数据。相比一维码，二维码可以存储更多的信息，包括文本、链接、图像等。常见的二维码类型包括QR Code、Data Matrix、Aztec Code等。

&#8195;&#8195;生活中我们提到“条形码”，其实多数场景指的是一维的。之前接入的厂商问我最常用的条形码是哪种，确实问着我了，哈哈哈。

&#8195;&#8195;条形码是一种用于储存和获取信息的编码方式，不同的应用场景和需求导致了多种类型的条形码的产生。以下是一些常见的条形码类型：

1. **UPC (Universal Product Code):** 通用产品代码，主要用于零售业，尤其是在北美地区。UPC 通常用于标识商品。
2. **EAN (International Article Number):** 国际商品编码，与UPC类似，也用于商品标识。EAN 通常是 13 位的数字码，当然也有 8 位的。
3. **Code 39:** 一种常见的线性条形码，支持字母、数字和一些特殊字符。常用于工业、物流和标签打印。
4. **Code 128:** 另一种常见的线性条形码，具有更高的数据密度和字符集支持。广泛用于物流和制造业。
5. **QR Code (Quick Response Code):** 二维码，可以存储更多的信息，包括文本、链接、图像等。常见于广告、移动支付、票务等领域。
6. **Aztec Code：**另一种二维码，阿兹特克码，常用于需要高密度数据存储的场景，例如票务、身份证、支付系统等。
7. **Data Matrix:** 另一种二维码，可以存储大量数据，特别适用于小空间。常用于电子元件、制造业和医疗设备。
8. **PDF417:** 一种堆叠式的二维码，可以存储大量信息。通常用于身份证、驾驶证等证件。

&#8195;&#8195;这只是一小部分常见的条形码类型，实际上还有许多其他类型，每种都有其特定的用途和应用领域。选择条形码类型通常取决于需要存储的信息量、可读性要求以及应用的具体要求。

## QR Scanner

&#8195;&#8195;往常扫码的需求不多，多数场景仅需要扫描二维码，所以直接通过 `AVFoundation` 来扫描并识别条码，`AVMetadataObject.ObjectType` 支持的条码类型包含了大部分常见的类型:

```swift
AVMetadataObjectTypeUPCECode
AVMetadataObjectTypeCode39Code
AVMetadataObjectTypeCode39Mod43Code
AVMetadataObjectTypeEAN13Code
AVMetadataObjectTypeEAN8Code
AVMetadataObjectTypeCode93Code
AVMetadataObjectTypeCode128Code
AVMetadataObjectTypePDF417Code
AVMetadataObjectTypeQRCode
AVMetadataObjectTypeAztecCode
AVMetadataObjectTypeInterleaved2of5Code
AVMetadataObjectTypeITF14Code
AVMetadataObjectTypeDataMatrixCode
```

&#8195;&#8195;对于识别图片中的条形码，这个库使用的是
```swift
CIDetector(ofType: CIDetectorTypeQRCode, context: context)
```

，关于条形码支持的类型也很直白 - CIDetectorTypeQRCode，只支持二维码...所以想从照片中识别一维码，要换个思路了。

## Vision

&#8195;&#8195;苹果从 ios11.0 开始支持 FaceID，相应推出了 Vision 框架。Vision 是一个用于图像和视觉处理的框架，它提供了一系列的工具和功能，涵盖了多个领域，包括面部识别、文本识别、物体追踪等。

以下是一些 Vision 框架的主要功能：

1. **面部识别（Face Recognition）：** Vision 框架可以检测图像中的面部，识别面部的特征，例如眼睛、嘴巴、鼻子等。它还能够进行面部追踪，跟踪在视频中移动的面部。
2. **文本识别（Text Recognition）：** Vision 框架支持对图像中的文本进行识别。这对于从照片或摄像头中捕捉到的文本进行实时处理很有用。
3. **物体追踪（Object Tracking）：** Vision 框架可以追踪图像或视频中的物体，使得你能够跟踪物体的位置随时间的变化。
4. **图像分类和识别（Image Classification）：** Vision 框架支持通过机器学习模型对图像进行分类和识别。你可以使用预训练的模型，也可以集成自己训练的模型。
5. **图像分割（Image Segmentation）：** Vision 框架允许对图像进行分割，将图像中的不同区域标记为不同的对象。

讲真，之前在工作中一个也没用上...所以不再敢称自己为开发者了，iOSer 秒变 Ioser，懂得都懂。🤧

言归正传：

&#8195;&#8195;翻一翻框架包含 detect 字样的 API，很多 “Vision/VNDetect--”，有一个 **VNDetectBarcodesRequest** 看上去非常符合我们的需求。发送图像识别请求，需要通过 **VNImageRequestHandler**，这个类型用于处理单个图像上的 Vision 请求。

### VNImageRequestHandler

&#8195;&#8195;尝试了几个 API、在 OC 中不小心造了个僵尸、抓僵尸抓了半天😈，最终选择用 CVPixelBuffer 来创建请求，其他使用 CGImage 的方式占用的内存似乎比较高？，因为我拿一张单反相机拍的略大艺术照做测试，挂掉了...

```swift
func detectBarcodeFromImg(_ oriImg: UIImage, _ completion: @escaping (Barcode) -> Void) {
		...
    DispatchQueue.init(label: "com.yydetector.session.queue").async { [self] in                                                                     
        guard let buffer = pixelBuffer(from: oriImg!) else {
            print("Image type not support!")
            return
        }
                                                                     
        let requestHandler = VNImageRequestHandler.init(cvPixelBuffer: buffer)
        do {
            let detectRequest = VNDetectBarcodesRequest { [self] request, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                if request.results!.isEmpty {
                    print("No result of request!")
                    return
                }

                for case let barcode as VNBarcodeObservation in request.results! {
                    if barcode.payloadStringValue != nil {
                        let formatter = printBarcode(barcode)
                        print(formatter)
                    } else {
                        print("No payload string value!")
                    }
                }
            }

            try requestHandler.perform([detectRequest])
        } catch {
          	print(error.localizedDescription)
        }
    }
}
```

&#8195;&#8195;识别到的结果会通过 VNBarcodeObservation 类型来返回，里面的属性非常详细，打印了几个，其他的不在这里罗列了：

```swift
✅ VNBarcodeObservation:
 〽️value = http://weixin.qq.com/r/cHVyahfEvErDrVMJ9yBi, 
 〽️type = VNBarcodeSymbologyQR, 
 〽️confidence = 1.0, 
 〽️boundingBox = 
	 x = 0.267, 
	 y = 0.407, 
	 w = 0.130, 
	 h = 0.060, 
 〽️desc : 
	 symbolVersion = 3, 
	 maskPattern = 2, 
	 errorCorrectionLevel = 76, 
	 errorCorrectedPayload =  
```

payloadStringValue(value) - 条码内容；
symbology(type) - 条码类型；
confidence - 表明了识别这个码的信心，0.6~1 貌似比较多，太低的话框架也就不识别了、或者不建议使用；
boundingBox - 是条形码的识别区域；
errorCorrectionLevel - 纠错级别；

### 条形码的背景色

&#8195;&#8195;原本以为写到这里作为一个补充功能也算是够用了，直到测试拿出了下面这张图：用在线工具随便生成了一个条形码、保存到手机相册、识别，扫码可以扫出来，但识别不出来[Emm][Emm]...

<center>
	<div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_4.jpg 300%}</div>
</center>

&#8195;&#8195;码看着是个正经码，但是为什么识别不出来呢？左右两侧的边缘处贴边了？PC 上截图再保存，也是可以识别出来的，那估计就是贴边导致的...说到这里，你可以随手拿起一个身边有条码的物品，不论物品的外包装是什么颜色的，条码一般都会单独有一个白色（浅色）的、码的四周有空白的背景区域，目的就是为了扫码的时候可以识别的快一点。看到有个外国网友提问：“自己在帮一个彩色水笔的公司做扫码功能，他们水笔的外包装是偏暗黑色的、水笔的条形码是...五颜六色的彩色，结账扫码时总是很慢，如何提到扫码的效率？”咱就是说，换个外包装呢😶...

&#8195;&#8195;那影响扫码效率的因素都有哪些，除了码的形状(复杂度)，是不是还有背景色或者说对比度？本来想尝试一下“抠图”，把这个贴边的条形码扣到一个白色背景上，结果算法没整明白，抠出来一个莫名其妙的效果：

<center>
	<div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_6.PNG 200%}</div>
	<div style="display:inline-block;margin-left:10px;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_7.PNG 200%}</div>
</center>

so...放弃。抠它干嘛呢，直接画到一个白色的背景图片上呢？为了避免再出现这种贴边的图、镂空的图，先是画了一个比原图的宽高都大 10 的白色图片，然后把原图放到白色背景板的中心，再识别，就成功了。

```swift
func imageFromColor(_ color: UIColor, size: CGSize) -> UIImage! {
    let rect = CGRect(x: 0, y: 0, width: size.width + 10, height: size.height + 10)

    UIGraphicsBeginImageContext(rect.size)
    guard let context = UIGraphicsGetCurrentContext() else {
        return UIImage(named: "scan_bg")
    }

    context.setFillColor(color.cgColor)
    context.fill(rect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
}

func drawImage(_ oriImg: CGImage, toCenter bgImg: CGImage) -> UIImage? {
    let targetSize = CGSize(width: CGFloat(bgImg.width), height: CGFloat(bgImg.height))

    UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)

    let bottomImage = UIImage(cgImage: bgImg)
    bottomImage.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))

    let scaledSize = CGSize(width: CGFloat(oriImg.width), height: CGFloat(oriImg.height))
    let destinationRect = CGRect(
        x: (targetSize.width - scaledSize.width) / 2,
        y: (targetSize.height - scaledSize.height) / 2,
        width: scaledSize.width,
        height: scaledSize.height
    )

    let centeredImage = UIImage(cgImage: oriImg)
    centeredImage.draw(in: destinationRect)

    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return finalImage
}
```

```swift
✅ VNBarcodeObservation:
 〽️value = 304329G00015157, 
 〽️type = VNBarcodeSymbologyCode128, 
 〽️confidence = 0.8, 
 〽️boundingBox = 
	 x = 0.015, 
	 y = 0.116, 
	 w = 0.970, 
	 h = 0.024, 
 〽️desc :  
```

### 律动的小箭头

&#8195;&#8195;当看到 Vision 返回了 boundingBox 时，又想到了一个需求：如果图片上有多个条码时，在每个可识别的区域加一个小箭头🔜，让用户自己选择使用哪个结果。效果如下：

<center>
	<div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_1.jpg 200%}</div>
	<div style="display:inline-block;margin-left:10px;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_2.jpg 200%}</div>
  <div style="display:inline-block;margin-left:10px;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_3.jpg 200%}</div>
</center>
思路是：

1. 识别到每个条码的 **boundingBox**，注意坐标系是 (0,1) 坐标，先简称为 CI 坐标系吧；
2. 图片在 ImageView 上的预览模式是 UIView.ContentMode = **scaleAspectFit**，想准确放置小箭头，那需要先拿到图片基于 ImageView 的区域，这里称为 UI 坐标系：（此片段来自 ChatGPT，哈哈。讲真，代码规范比我们某些同志的代码都干净）

```swift
extension UIImageView {
    func renderingRectForImage() -> CGRect? {
      ...
            
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
 	 ...
        
        return renderingRect
    }
}
```

3. 得到图片区域以后，把基于 CI 坐标的 boundingBox 转换为 UI 坐标，用来添加 view：

```swift
func convertCIBoundingRectToUIRect(_ ci: CGRect) -> CGRect {
    let renderingRect = imgV.renderingRectForImage()

    let w = ci.size.width * renderingRect!.size.width
    let h = ci.size.height * renderingRect!.size.height
    let x = ci.origin.x * renderingRect!.size.width + renderingRect!.origin.x
    let y = ci.origin.y * renderingRect!.size.height + renderingRect!.origin.y

    return CGRectMake(x, y, w, h)
}
```

4. 基于转换后的坐标创建抖动的绿色小箭头，告诉用户“点我~点我~”。到这一步基本上已经达到上图的目的了。

But...
But...
But...

&#8195;&#8195;上面的小箭头其实是经过一次“变态”转换之后的效果。用过 CI 坐标的都知道，在 CoreImage 中或者说读到内存中的图片，坐标系的原点和图片方向是有关系的，并不是单纯和 UI 坐标上下反过来的关系。正常情况下图片的方向是 **CGImagePropertyOrientation.up**，想模拟其他方向可以把手机横着或者倒过来拍照试试，还用上面的多条码图片举例，按照我们 1-4 步骤出来的效果其实是这样的;

<center>
	<div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_8.PNG 200%}</div>
</center>

很明显，识别区域都是有的，但坐标方向是不准确的。可以看一下 **CGImagePropertyOrientation** 的注解，对每个方向的原点位置都做了说明：

```swift
@frozen public enum CGImagePropertyOrientation : UInt32, @unchecked Sendable {
    
    case up = 1 // 0th row at top,    0th column on left   - default orientation
...
}
```

下一步，

5. 需要把图片方向“指定”一下，坐标转换时加一次“变态”转换 - **CGAffineTransform**：

```swift
func detectBarcodeFromImg(_ oriImg: UIImage, _ completion: @escaping (Barcode) -> Void) {
		...
    DispatchQueue.init(label: "com.yydetector.session.queue").async { [self] in                                                                     
        guard let buffer = pixelBuffer(from: oriImg!) else {
            print("Image type not support!")
            return
        }
                                                                     
        let tempOrientation = getCGImagePropertyOrientation(from: oriImg.imageOrientation)
        let requestHandler = VNImageRequestHandler.init(cvPixelBuffer: buffer, orientation: tempOrientation)
        ...
    }
}

func convertCIBoundingRectToUIRect(_ cii: CGRect) -> CGRect {
    let renderingRect = imgV.renderingRectForImage()

    let ci = cii.applying(getCGAffineTransform(from: orientation!))

    let w = ci.size.width * renderingRect!.size.width
    let h = ci.size.height * renderingRect!.size.height
    let x = ci.origin.x * renderingRect!.size.width + renderingRect!.origin.x
    let y = ci.origin.y * renderingRect!.size.height + renderingRect!.origin.y

    return CGRectMake(x, y, w, h)
}

func getCGAffineTransform(from orientation: CGImagePropertyOrientation) -> CGAffineTransform {
    switch orientation {
    case .up, .down:
        return CGAffineTransform(scaleX: 1, y: 1).translatedBy(x: 0, y: 0)
    default:
        return CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1)
    }
}
```

<center>
	<div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_9.PNG 200%}</div>
</center>

到这里应该可以了吧？

But...
But...
But...

### 我的小情怀

&#8195;&#8195;我个人对某些机型或者系统有自己奇奇怪怪的情怀，很少以旧换新。例如有台 iPhone 5s 是第一代指纹识别的 HOME 键，让它的系统一直停留在了 ios9；又例如有台 iPhone 12 边框是方的所以喜欢，让它停在了 ios15.4，也因为莫名其妙觉得它比较省电。这不是重点，重点是同样的 API、同样的律动小箭头、同样的一个贴边儿条形码，在这台 iPhone 12 上，识别出来是这样的，具体识别出来了几个，我也没数🤷‍♀️：

<center>
	<div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_5.jpg 200%}</div>
</center>

...
...

<center>
	<div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_10.jpg 80%}</div>
  <div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_10.jpg 80%}</div>
  <div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_10.jpg 80%}</div>
  <div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_10.jpg 80%}</div>
  <div style="display:inline-block;">{%img https://yyblog-images-1258406742.cos.ap-beijing.myqcloud.com/vision_10.jpg 80%}</div>
</center>




&#8195;&#8195;哪个坏人总说客户端简单的？打你哦。

&#8195;&#8195;正经人谁做客户端开发啊。

&#8195;&#8195;关机，保命，再见。

## 代码

最后一句，[代码在这里](https://github.com/ATommyGirl/Vision.git)，需要自取。

---
