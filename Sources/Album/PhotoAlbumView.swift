//
//  PhotoAlbumView.swift
//  ImagePickerProject
//
//  Created by ty on 16/7/6.
//  Copyright © 2016年 ty. All rights reserved.
//

import UIKit

protocol PhotoAlbumViewDelegate: NSObjectProtocol {
  
  func photoAlbumView(_ photoAlbumView: PhotoAlbumView, didSelectAtIndex index: Int)
  
}

class PhotoAlbumView: UIView {
  
  fileprivate var tableView: UITableView!
  fileprivate weak var delegate: PhotoAlbumViewDelegate?
  
  let identifier = "PhotoAlbumCell"
  
  init(frame: CGRect, delegate: PhotoAlbumViewDelegate) {
    
    self.delegate = delegate
    
    super.init(frame: frame)
    
    setupUI()
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  /******************************************************************************
   *  private  Implements
   ******************************************************************************/
  //MARK: - private Implements
  
  func setupUI(){
    
    tableView = UITableView(frame: CGRect.zero, style: .plain)
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.backgroundColor = UIColor.white
    tableView.tableFooterView = UIView()
    tableView.dataSource = self
    tableView.delegate = self
    let nibCell = UINib(nibName: identifier, bundle: Bundle(for: PhotoAlbumView.self))
    tableView.register(nibCell, forCellReuseIdentifier: identifier)
    tableView.separatorColor = UIColor.separatorColor
    tableView.rowHeight = 60.0
    addSubview(tableView)
    tableView.snp.makeConstraints { (make) in
      make.top.left.right.bottom.equalToSuperview()
    }
    tableView.reloadData()
    
  }
  
}

extension PhotoAlbumView: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return PhotosManager.sharedInstance.getAlbumCount()
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PhotoAlbumCell
    
    guard let collection = PhotosManager.sharedInstance.getAlbumWith(indexPath.row) else  { return cell }
    
    cell.titleLabel.text = "\(collection.localizedTitle!) (\(PhotosManager.sharedInstance.getFetchResult(with: collection, resourceOption: PhotosManager.sharedInstance.resourceOption).count))"
    
    PhotosManager.sharedInstance.fetchImage(with: indexPath.row, imageIndex: 0, sizeType: .thumbnail) { (image, _) -> Void in
      
      if image == nil {
        cell.thumbImageView.image = self.ImageResourcePath("default_pic")
      }else{
        cell.thumbImageView.image = image
        
        }
    }
    
    cell.separatorInset = UIEdgeInsets.zero
    
    return cell
  }
}

extension PhotoAlbumView: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    if let indexPath = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: indexPath, animated: true)
    }
    PhotosManager.sharedInstance.currentAlbumIndex = indexPath.row
    
    delegate?.photoAlbumView(self, didSelectAtIndex: indexPath.row)
  }
  
}

