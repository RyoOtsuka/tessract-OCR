//
//  ViewController.swift
//  Painting
//
//  Created by 大塚　良 on 2019/06/18.
//  Copyright © 2019 Ryo Otsuka. All rights reserved.
//

import UIKit
import TesseractOCR

class ViewController: UIViewController, G8TesseractDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func SecoundButton(_ sender: Any) {
        handleChangeImage()
    }
    
    func analyze(pathImage: UIImage?) {
        
        if pathImage == nil{
            
            print("何もない")
        }else{
            
            var tesseract = G8Tesseract(language: "jpn")
            tesseract?.delegate = self
            tesseract?.image = pathImage!
            tesseract?.recognize()
            
            if tesseract?.recognizedText == nil{
                
//                print("nanimonai")
            }else{
//                OCRLabel.text = tesseract?.recognizedText as? String
                print(tesseract?.recognizedText as! String)
            }
        }
    }
    
    func shouldCancelImageRecognitionForTesseract(tesseract: G8Tesseract!) -> Bool {
        return false
    }
}

class DrawView: UIImageView{
    
    @IBAction func deleteButton(_ sender: Any) {
        
        removeWriting()
    }
    
    var penColor = UIColor.black
    var penSize: CGFloat = 3
    var path: UIBezierPath!
    private var lastDrawImage: UIImage?
    
    var temporaryPath: UIBezierPath!
    private var points = [CGPoint]()
    
    private var pointCount = 0
    private var snapshotImage: UIImage?
    
    private var isCallTouchMoved = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let currentPoint = touches.first!.location(in: self)
        path = UIBezierPath()
        path?.lineWidth = penSize
        path?.lineCapStyle = CGLineCap.round
        path?.lineJoinStyle = CGLineJoin.round
        path?.move(to: currentPoint)
        points = [currentPoint]
        pointCount = 0
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        isCallTouchMoved = true
        pointCount += 1
        let currentPoint = touches.first!.location(in: self)
        points.append(currentPoint)
        if points.count == 2 {
            temporaryPath = UIBezierPath()
            temporaryPath?.lineWidth = penSize
            temporaryPath?.lineCapStyle = .round
            temporaryPath?.lineJoinStyle = .round
            temporaryPath?.move(to: points[0])
            temporaryPath?.addLine(to: points[1])
            image = drawLine()
        }else if points.count == 3 {
            temporaryPath = UIBezierPath()
            temporaryPath?.lineWidth = penSize
            temporaryPath?.lineCapStyle = .round
            temporaryPath?.lineJoinStyle = .round
            temporaryPath?.move(to: points[0])
            temporaryPath?.addQuadCurve(to: points[2], controlPoint: points[1])
            image = drawLine()
        }else if points.count == 4 {
            temporaryPath = UIBezierPath()
            temporaryPath?.lineWidth = penSize
            temporaryPath?.lineCapStyle = .round
            temporaryPath?.lineJoinStyle = .round
            temporaryPath?.move(to: points[0])
            temporaryPath?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
            image = drawLine()
        }else if points.count == 5 {
            
            points[3] = CGPoint(x: (points[2].x + points[4].x) * 0.5, y: (points[2].y + points[4].y) * 0.5)
            
            if points[4] != points[3] {
                let length = hypot(points[4].x - points[3].x, points[4].y - points[3].y) / 2.0
                let angle = atan2(points[3].y - points[2].y, points[4].x - points[3].x)
                let controlPoint = CGPoint(x: points[3].x + cos(angle) * length, y: points[3].y + sin(angle) * length)
                
                temporaryPath = UIBezierPath()
                temporaryPath?.move(to: points[3])
                temporaryPath?.lineWidth = penSize
                temporaryPath?.lineCapStyle = .round
                temporaryPath?.lineJoinStyle = .round
                temporaryPath?.addQuadCurve(to: points[4], controlPoint: controlPoint)
            } else {
                
                temporaryPath = nil
            }
            
            path?.move(to: points[0])
            path?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
            points = [points[3], points[4]]
            image = drawLine()
        }
        
        if pointCount > 50 {
            temporaryPath = nil
            snapshotImage = drawLine()
            path.removeAllPoints()
            pointCount = 0
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let currentPoint = touches.first!.location(in: self)
        
        if !isCallTouchMoved { path?.addLine(to: currentPoint) }
        image = drawLine()
        lastDrawImage = image
        temporaryPath = nil
        snapshotImage = nil
        isCallTouchMoved = false
        ViewController().analyze(pathImage: lastDrawImage)
    }
    
    func drawLine() -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        
        if snapshotImage != nil {
            snapshotImage?.draw(at: CGPoint.zero)
        }else {
            lastDrawImage?.draw(at: CGPoint.zero)
        }
        
        penColor.setStroke()
        path?.stroke()
        temporaryPath?.stroke()
        
        let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return capturedImage
    }
    
    func uploadImage(dataImage: UIImage?) {
        
        image = dataImage
    }
    
    func removeWriting(){
        
        lastDrawImage = nil
        image = lastDrawImage
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func handleChangeImage(){
        
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            
            selectedImageFromPicker = editedImage
        }else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            selectedImageFromPicker = originalImage
            print(originalImage.size)
        }
        
        if let didseletedImage = selectedImageFromPicker{
            
            analyze(pathImage: didseletedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancel Picker")
        dismiss(animated: true, completion: nil)
    }
}

