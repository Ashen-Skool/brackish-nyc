import SwiftUI
import ImageIO

/// Downsample away from the main actor. A stable frame prevents loading layout shifts.
actor PhotoLoader {
    static let shared=PhotoLoader()
    private let cache=NSCache<NSURL,UIImage>()
    init() {cache.totalCostLimit=32*1024*1024;cache.countLimit=16}
    func load(url:URL)->UIImage? {
        if let cached=cache.object(forKey:url as NSURL) {return cached}
        guard let source=CGImageSourceCreateWithURL(url as CFURL,nil),let image=decode(source) else{return nil}
        cache.setObject(image,forKey:url as NSURL,cost:Int(image.size.width*image.size.height*4));return image
    }
    func load(data:Data)->UIImage? {
        guard let source=CGImageSourceCreateWithData(data as CFData,nil) else{return nil}
        return decode(source)
    }
    func clear() {cache.removeAllObjects()}
    private func decode(_ source:CGImageSource)->UIImage? {
        let options:[CFString:Any]=[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceThumbnailMaxPixelSize:1200,kCGImageSourceCreateThumbnailWithTransform:true,kCGImageSourceShouldCacheImmediately:true]
        guard let image=CGImageSourceCreateThumbnailAtIndex(source,0,options as CFDictionary) else{return nil}
        return UIImage(cgImage:image)
    }
}
struct PhotoView:View {
    var url:URL?=nil
    var data:Data?=nil
    var fill=false
    @State private var image:UIImage?
    @State private var failed=false
    var body:some View {
        Group {
            if let image {Image(uiImage:image).resizable().aspectRatio(contentMode:fill ? .fill : .fit)}
            else if failed {Label("Photo unavailable",systemImage:"photo.badge.exclamationmark").font(.subheadline).padding().frame(maxWidth:.infinity).foregroundStyle(Ink.quiet)}
            else {ProgressView().frame(maxWidth:.infinity,minHeight:100).tint(Ink.teal)}
        }.accessibilityLabel("Catch photograph")
            .task(id:url) {if let url {let loaded=await PhotoLoader.shared.load(url:url);guard !Task.isCancelled else{return};image=loaded;failed=image == nil}}
            .task(id:data) {if let data {let loaded=await PhotoLoader.shared.load(data:data);guard !Task.isCancelled else{return};image=loaded;failed=image == nil}}
    }
}
