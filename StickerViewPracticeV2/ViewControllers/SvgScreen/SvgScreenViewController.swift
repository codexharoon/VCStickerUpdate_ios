//
//  SvgScreenViewController.swift
//  StickerViewPracticeV2
//
//  Created by haroon on 01/01/2026.
//

import UIKit
import SVGKit

class SvgScreenViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var svgCollectionView: UICollectionView!
    
    var svgs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        svgCollectionView.delegate = self
        svgCollectionView.dataSource = self
        
        loadData()
    }
    
    
    func getSVGFiles() -> [String] {
        let paths = Bundle.main.paths(forResourcesOfType: "svg", inDirectory: nil)
        return paths.map { ($0 as NSString).lastPathComponent }
    }
    
    func loadData(){
        self.svgs = getSVGFiles()
        self.svgCollectionView.reloadData()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return svgs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SvgScreenCollectionViewCell", for: indexPath) as! SvgScreenCollectionViewCell
        
        let item = self.svgs[indexPath.item]
        
        if let path = Bundle.main.path(forResource: item, ofType: nil) {
            let svgImage = SVGKImage(contentsOfFile: path)
            cell.imageView.image = svgImage?.uiImage
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.width) / 2 - 10, height: 180)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.svgs[indexPath.item]
        
        let MainVC = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        
        MainVC.svgName = item.split(separator: ".")[0].description
        
        MainVC.modalPresentationStyle = .fullScreen
        self.present(MainVC, animated: true)
    }

}
