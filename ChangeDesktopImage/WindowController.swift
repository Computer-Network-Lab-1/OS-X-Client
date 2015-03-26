//
//  WindowController.swift
//  ChangeDesktopImage
//
//  Created by cuty-lewiwi on 3/21/15.
//  Copyright (c) 2015 cuty-lewiwi. All rights reserved.
//

import Cocoa
import Quartz

class MyImageObject : NSObject
{
    var url : NSURL = NSURL()
    var title : String = ""
    
    // MARK: - Item data source protocol
    override func imageRepresentationType() -> String! {
        return IKImageBrowserNSURLRepresentationType
    }
    
    override func imageRepresentation() -> AnyObject! {
        return self.url
    }
    
    override func imageUID() -> String! {
        return String(format: "%p", self)
    }
    
    override func imageTitle() -> String! {
        return self.title
    }
}

class WindowController: NSWindowController {

    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var imageScalingSelector: NSPopUpButton!
    @IBOutlet weak var imageBrowserView: IKImageBrowserView!
    @IBOutlet weak var applyButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var downLoadIndicator: NSProgressIndicator!
    @IBOutlet weak var downLoadLabel: NSTextField!
    @IBOutlet weak var zoomingPercentageLabel: NSTextField!
    @IBOutlet weak var zoomingSlider: NSSlider!
    
    var originBackgroundImageURL : NSURL?
    //var selectURL: NSURL?
    var options : Dictionary<NSObject, AnyObject>?
    var images : Array<MyImageObject> = []
    var imageBrowserZoom : Float {
        set{
            //self.zoomingSlider.floatValue = newValue
            self.zoomingPercentageLabel.stringValue = String(format: "%.0f", newValue * 100.0)
            self.zoomingPercentageLabel.stringValue += "%"
            self.imageBrowserView.setZoomValue(newValue)
            println(newValue)
        }
        get{
            return self.zoomingSlider.floatValue
        }
    }
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override func awakeFromNib() {
        self.originBackgroundImageURL = NSWorkspace.sharedWorkspace().desktopImageURLForScreen(NSScreen.mainScreen()!)
        //println(self.originBackgroundImageURL)
        self.searchFilesAtApplicationSupport()
        println(self.imageBrowserView.zoomValue())
        //self.imageBrowserZoom = self.zoomingSlider.floatValue
    }
    
    // MARK: - IBActions
    @IBAction func searchButtonClicked(sender: AnyObject) {
        println("search")
        self.downLoadLabel.hidden = false
        self.downLoadIndicator.hidden = false
        self.downLoadIndicator.startAnimation(nil)
        var color : NSColor = self.colorWell.color
        var red : Int = Int(Double(color.redComponent) * 255)
        var green : Int = Int(Double(color.greenComponent) * 255)
        var blue : Int = Int(Double(color.blueComponent) * 255)
        var urlString : String = String(format: "http://photo.yangjunrui.com/color?r=%d&g=%d&b=%d", red, green, blue)
        println(urlString)
        var error : NSError?
        var imageUrlString : String? = String(contentsOfURL: NSURL(string: urlString)!, encoding: NSUTF8StringEncoding, error: &error)
        if error != nil{
            println(error)
            self.downLoadIndicator.stopAnimation(nil)
            self.downLoadIndicator.hidden = true
            self.downLoadLabel.hidden = true
            self.alertForError(error!)
            return
        }
        println(imageUrlString)
        self.downloadImage(NSURL(string: imageUrlString!)!)
    }

    @IBAction func zomming(sender: AnyObject) {
        //self.imageBrowserView.setZoomValue(sender.floatValue)
        self.imageBrowserZoom = sender.floatValue
    }
    
    @IBAction func applyButtonClicked(sender: AnyObject) {
        println("apply")
        //NSWorkspace.sharedWorkspace().setDesktopImageURL(self.selectURL!, forScreen: NSScreen.mainScreen()!, options: nil, error: nil)
        var selectedIndex = self.imageBrowserView.selectionIndexes().firstIndex
        self.originBackgroundImageURL = self.images[selectedIndex].url
        // terminate the application
        //NSApplication.sharedApplication().terminate(self)
        self.applyButton.enabled = false
        self.cancelButton.enabled = false
    }
    
    @IBAction func cancelButtonClicked(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().setDesktopImageURL(self.originBackgroundImageURL!, forScreen: NSScreen.mainScreen()!, options: self.options, error: nil)
        self.applyButton.enabled = false
        self.cancelButton.enabled = false
    }
    
    // MARK: - Alert
    func alertForError(error: NSError){
        var alert : NSAlert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.messageText = "Internet Access Failed"
        alert.beginSheetModalForWindow((NSApplication.sharedApplication().delegate as AppDelegate).window, completionHandler: { (response: NSModalResponse) -> Void in
            return
        })
    }
    
    // MARK: - Network Downloading
    func downloadImage(URL: NSURL) {
        println("download")
        let sessionIdentifier : String = "downloadConfigurationInChangeDesktopImage"
        var request : NSURLRequest = NSURLRequest(URL: URL)
        //var sessionConfiguration : NSURLSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfiguration(sessionIdentifier)
        var session : NSURLSession = NSURLSession.sharedSession()
        var downloadTask : NSURLSessionDownloadTask = session.downloadTaskWithRequest(request,
            completionHandler: {
                (Location : NSURL!, LocaleResponse : NSURLResponse!, Error : NSError!) -> Void in
                var fm : NSFileManager = NSFileManager.defaultManager()
                var url : NSURL = fm.URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as NSURL
                url = url.URLByAppendingPathComponent("DesktopImages")
                url = url.URLByAppendingPathComponent("desktopImages")
                url = url.URLByAppendingPathComponent(LocaleResponse.suggestedFilename!)
                println(url.path!)
                var data : NSData? = NSData(contentsOfURL: Location)
                NSFileManager.defaultManager().createFileAtPath(url.path!, contents: data, attributes: nil)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.downLoadIndicator.stopAnimation(nil)
                    self.downLoadIndicator.hidden = true
                    self.downLoadLabel.hidden = true
                    self.searchFilesAtApplicationSupport()
                    //self.imageBrowserView.reloadData()
                })
                println("end")
                //return url.URLByAppendingPathComponent(Response.URL.lastPathComponent)
        })
        downloadTask.resume()
    }
    
    // MARK: - File Systems
    func isImage(URL: NSURL) -> Bool {
        var isImage = false
        var utiValue : AnyObject?
        URL.getResourceValue(&utiValue, forKey: NSURLTypeIdentifierKey, error: nil)
        if utiValue != nil{
            isImage = UTTypeConformsTo(utiValue as CFStringRef, kUTTypeImage) != 0
        }
        return isImage
    }
    
    func searchFilesAtApplicationSupport() {
        self.images.removeAll(keepCapacity: false)
        var fm : NSFileManager = NSFileManager.defaultManager()
        var url : NSURL = fm.URLsForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as NSURL
        url = url.URLByAppendingPathComponent("DesktopImages")
        //println(url.path!)
        var isExist : Bool = fm.fileExistsAtPath(url.path!)
        
        if !isExist {
            isExist = fm.createDirectoryAtPath(url.path!, withIntermediateDirectories: true, attributes: nil, error: nil)
            if !isExist {
                println("could not create folder at application")
            }
        }
        
        url = url.URLByAppendingPathComponent("desktopImages")
        var isDir : ObjCBool = false
        isExist = fm.fileExistsAtPath(url.path!, isDirectory: &isDir)
        
        if !isDir {
            fm.removeItemAtPath(url.path!, error: nil)
            isExist = false
        }
        if !isExist {
            fm.createDirectoryAtPath(url.path!, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
        
        var content = fm.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, error: nil)! as Array<AnyObject>
        var imageUrl : NSURL = NSURL()
        for imageUrl in content as Array<NSURL> {
            var imageObjs : MyImageObject = MyImageObject()
            imageObjs.title = imageUrl.lastPathComponent!
            imageObjs.url = imageUrl as NSURL
            self.images.append(imageObjs)
        }
        self.imageBrowserView.reloadData()
    }
    
    // MARK: - IKImageBrowserDataSource
    override func numberOfItemsInImageBrowser(aBrowser: IKImageBrowserView!) -> Int {
        return self.images.count
    }
    
    override func imageBrowser(aBrowser: IKImageBrowserView!, itemAtIndex index: Int) -> AnyObject! {
        return self.images[index]
    }
    
    // MARK: - IKImageBrowserDelegate
    override func imageBrowserSelectionDidChange(aBrowser: IKImageBrowserView!) {
        var selectedIndexSet : NSIndexSet = aBrowser.selectionIndexes()
        var screen : NSScreen = NSScreen.mainScreen()!
        var screenObtions = NSWorkspace.sharedWorkspace().desktopImageOptionsForScreen(screen)
        if selectedIndexSet.count > 0{
            var selectedURL : NSURL = self.images[selectedIndexSet.firstIndex].url
            NSWorkspace.sharedWorkspace().setDesktopImageURL(selectedURL, forScreen: screen, options: screenObtions, error: nil)
        }
        self.applyButton.enabled = true
        self.cancelButton.enabled = true
        //self.imageBrowserView.reloadData()
    }
}
