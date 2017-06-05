//
//  ViewController.swift
//  App Icon Generator
//
//  Created by David Frischknecht on 8/27/16.
//  Copyright © 2017 David Frischknecht. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate, NSMenuDelegate {
	@IBOutlet weak var pathSourceImage: NSPathControl!
	@IBOutlet weak var pathDestinationFolder: NSPathControl!
	@IBOutlet weak var txtImageBaseName: NSTextField!
	@IBOutlet weak var btnProcessImages: NSButton!
	@IBOutlet weak var cmbAppType: NSPopUpButton!
	var imageSizesDict: Dictionary<String, AnyObject>!

	override func viewDidLoad() {
		super.viewDidLoad()
		txtImageBaseName.delegate = self
		cmbAppType.menu?.delegate = self
		let path = Bundle.main.path(forResource: "IconSizes", ofType: "plist")
		let url = URL(fileURLWithPath: path!)
		let data = try! Data(contentsOf: url)
		let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
		imageSizesDict = plist as! Dictionary<String, AnyObject>
		pathSourceImage.url = nil
		pathDestinationFolder.url = nil
	}

	override var representedObject: Any? {
		didSet {
		}
	}
	
	@IBAction func browseForSourceImageWasTapped(_ sender: NSButton) {
		let choosePanel = NSOpenPanel()
		choosePanel.allowsMultipleSelection = false
		choosePanel.canChooseDirectories = false
		choosePanel.canCreateDirectories = false
		choosePanel.canChooseFiles = true
		choosePanel.title = "Source Image"
		choosePanel.allowedFileTypes = ["png", "jpg", "gif"]
		choosePanel.prompt = "Choose"
		let response = choosePanel.runModal()
		if response == NSApplication.ModalResponse.OK {
			pathSourceImage.url = choosePanel.urls[0]
			checkProcessButtonStatus()
		}
	}
	
	@IBAction func browseForDestinationFolderWasTapped(_ sender: NSButton) {
		let choosePanel = NSOpenPanel()
		choosePanel.allowsMultipleSelection = false
		choosePanel.canChooseDirectories = true
		choosePanel.canChooseFiles = false
		choosePanel.canCreateDirectories = true
		choosePanel.title = "Destination Folder"
		choosePanel.prompt = "Choose"
		let response = choosePanel.runModal()
		if response == NSApplication.ModalResponse.OK {
			pathDestinationFolder.url = choosePanel.urls[0]
			checkProcessButtonStatus()
		}
	}
	
	override func controlTextDidChange(_ notification: Notification) {
		checkProcessButtonStatus()
	}
	
	func menuDidClose(_ menu: NSMenu) {
		checkProcessButtonStatus()
	}
	
	@IBAction func processImagesWasTapped(_ sender: NSButton) {
		let sourceImage = NSImage(byReferencing: pathSourceImage.url!)
		let selectedAppType = cmbAppType.selectedItem?.title
		let destFolder = pathDestinationFolder.url!
		var filesInFolder: [URL] = []
		do {
			filesInFolder = try FileManager.default.contentsOfDirectory(at: destFolder, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
		} catch let error as NSError {
			print(error.localizedDescription)
		}
		NSWorkspace.shared.recycle(filesInFolder, completionHandler: nil)
		var imageSizesArray: [Int32] = []
		if let tmp = imageSizesDict[selectedAppType!] as! NSArray? {
			for value in tmp {
				imageSizesArray.append((value as AnyObject).intValue)
			}
		}
		var imageFiles: [URL] = []
		for size in imageSizesArray {
			let imageURL = destFolder.appendingPathComponent("\(txtImageBaseName.stringValue)\(size).png")
			let newSize = NSSize(width: Int(size), height: Int(size))
			let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSColorSpaceName.calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)
			rep?.size = newSize
			NSGraphicsContext.saveGraphicsState()
			NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep!)
			sourceImage.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
			NSGraphicsContext.restoreGraphicsState()
			let imageData = rep?.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
			try! imageData?.write(to: imageURL)
			imageFiles.append(imageURL)
		}
		NSWorkspace.shared.activateFileViewerSelecting(imageFiles)
	}
	
	func checkProcessButtonStatus() {
		var ok = true
		ok = ok && pathSourceImage.url != nil
		ok = ok && pathDestinationFolder.url != nil
		ok = ok && txtImageBaseName.stringValue.characters.count > 0
		ok = ok && cmbAppType.selectedItem?.title != ""
		btnProcessImages.isEnabled = ok
	}
}
