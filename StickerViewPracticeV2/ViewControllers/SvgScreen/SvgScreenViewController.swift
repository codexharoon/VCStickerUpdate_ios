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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if targetEnvironment(simulator)
            self.loadData()
        #endif
    }
    
    
    @IBAction func draftBtnAction(_ sender: Any) {
        let draftVC = self.storyboard?.instantiateViewController(withIdentifier: "DraftScreenViewController") as! DraftScreenViewController
        
        draftVC.modalPresentationStyle = .fullScreen
        
        present(draftVC, animated: true)
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
            let data = svgImage?.uiImage.jpegData(compressionQuality: 0.3)
            if let d = data {
                let img = UIImage(data: d)
                cell.imageView.image = img
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let items: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        let width = (collectionView.frame.width - 10) / items
        return CGSize(width: width, height: width * 1.3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.svgs[indexPath.item]
        
        let MainVC = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        
        MainVC.svgName = item.split(separator: ".")[0].description
        
        MainVC.modalPresentationStyle = .fullScreen
        self.present(MainVC, animated: true)
    }

}
