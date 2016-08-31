// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

open class NSAttributedString: NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    
    private let _cfinfo = _CFInfo(typeID: CFAttributedStringGetTypeID())
    fileprivate var _string: NSString
    fileprivate var _attributeArray: CFRunArrayRef
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    static public var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
    }

    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
    }
    
    open var string: String {
        return _string._swiftObject
    }
    
    open func attributes(at location: Int, effectiveRange range: NSRangePointer) -> [String : Any] {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: false,
            longestEffectiveRangeSearchRange: nil)
        return _attributes(at: location, rangeInfo: rangeInfo)
    }

    open var length: Int {
        return CFAttributedStringGetLength(_cfObject)
    }
    
    open func attribute(_ attrName: String, at location: Int, effectiveRange range: NSRangePointer?) -> Any? {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: false,
            longestEffectiveRangeSearchRange: nil)
        return _attribute(attrName, atIndex: location, rangeInfo: rangeInfo)
    }
    
    open func attributedSubstring(from range: NSRange) -> NSAttributedString { NSUnimplemented() }
    
    open func attributes(at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange) -> [String : Any] {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: true,
            longestEffectiveRangeSearchRange: rangeLimit)
        return _attributes(at: location, rangeInfo: rangeInfo)
    }
    
    open func attribute(_ attrName: String, at location: Int, longestEffectiveRange range: NSRangePointer?, in rangeLimit: NSRange) -> Any? {
        let rangeInfo = RangeInfo(
            rangePointer: range,
            shouldFetchLongestEffectiveRange: true,
            longestEffectiveRangeSearchRange: rangeLimit)
        return _attribute(attrName, atIndex: location, rangeInfo: rangeInfo)
    }
    
    open func isEqual(to other: NSAttributedString) -> Bool { NSUnimplemented() }
    
    public init(string str: String) {
        _string = str._nsObject
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
        
        super.init()
        addAttributesToAttributeArray(attrs: nil)
    }
    
    public init(string str: String, attributes attrs: [String : Any]?) {
        _string = str._nsObject
        _attributeArray = CFRunArrayCreate(kCFAllocatorDefault)
        
        super.init()
        addAttributesToAttributeArray(attrs: attrs)
    }
    
    public init(NSAttributedString attrStr: NSAttributedString) { NSUnimplemented() }

    open func enumerateAttributes(in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: ([String : Any], NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) { NSUnimplemented() }
    open func enumerateAttribute(_ attrName: String, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) { NSUnimplemented() }
    
}

private extension NSAttributedString {
    struct RangeInfo {
        let rangePointer: NSRangePointer?
        let shouldFetchLongestEffectiveRange: Bool
        let longestEffectiveRangeSearchRange: NSRange?
    }
    
    func _attributes(at location: Int, rangeInfo: RangeInfo) -> [String : Any] {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(to: &cfRange) { (cfRangePointer: UnsafeMutablePointer<CFRange>) -> [String : Any] in
            // Get attributes value using CoreFoundation function
            let value: CFDictionary
            if rangeInfo.shouldFetchLongestEffectiveRange, let searchRange = rangeInfo.longestEffectiveRangeSearchRange {
                value = CFAttributedStringGetAttributesAndLongestEffectiveRange(_cfObject, location, CFRange(searchRange), cfRangePointer)
            } else {
                value = CFAttributedStringGetAttributes(_cfObject, location, cfRangePointer)
            }
            
            // Convert the value to [String : AnyObject]
            let dictionary = unsafeBitCast(value, to: NSDictionary.self)
            var results = [String : Any]()
            for (key, value) in dictionary {
                guard let stringKey = (key as? NSString)?._swiftObject else {
                    continue
                }
                results[stringKey] = value
            }
            
            // Update effective range
            let hasAttrs = results.count > 0
            rangeInfo.rangePointer?.pointee.location = hasAttrs ? cfRangePointer.pointee.location : NSNotFound
            rangeInfo.rangePointer?.pointee.length = hasAttrs ? cfRangePointer.pointee.length : 0
            
            return results
        }
    }
    
    func _attribute(_ attrName: String, atIndex location: Int, rangeInfo: RangeInfo) -> Any? {
        var cfRange = CFRange()
        return withUnsafeMutablePointer(to: &cfRange) { (cfRangePointer: UnsafeMutablePointer<CFRange>) -> AnyObject? in
            // Get attribute value using CoreFoundation function
            let attribute: AnyObject?
            if rangeInfo.shouldFetchLongestEffectiveRange, let searchRange = rangeInfo.longestEffectiveRangeSearchRange {
                attribute = CFAttributedStringGetAttributeAndLongestEffectiveRange(_cfObject, location, attrName._cfObject, CFRange(searchRange), cfRangePointer)
            } else {
                attribute = CFAttributedStringGetAttribute(_cfObject, location, attrName._cfObject, cfRangePointer)
            }
            
            // Update effective range and return the result
            if let attribute = attribute {
                rangeInfo.rangePointer?.pointee.location = cfRangePointer.pointee.location
                rangeInfo.rangePointer?.pointee.length = cfRangePointer.pointee.length
                return attribute
            } else {
                rangeInfo.rangePointer?.pointee.location = NSNotFound
                rangeInfo.rangePointer?.pointee.length = 0
                return nil
            }
        }
    }
    
    func addAttributesToAttributeArray(attrs: [String : Any]?) {
        guard _string.length > 0 else {
            return
        }
        
        let range = CFRange(location: 0, length: _string.length)
        if let attrs = attrs {
            CFRunArrayInsert(_attributeArray, range, attrs._cfObject)
        } else {
            let emptyAttrs = [String : AnyObject]()
            CFRunArrayInsert(_attributeArray, range, emptyAttrs._cfObject)
        }
    }
}

extension NSAttributedString: _CFBridgable {
    internal var _cfObject: CFAttributedString { return unsafeBitCast(self, to: CFAttributedString.self) }
}

extension NSAttributedString {

    public struct EnumerationOptions: OptionSet {
        public let rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        public static let Reverse = EnumerationOptions(rawValue: 1 << 1)
        public static let LongestEffectiveRangeNotRequired = EnumerationOptions(rawValue: 1 << 20)
    }

}


open class NSMutableAttributedString : NSAttributedString {
    
    open func replaceCharacters(in range: NSRange, with str: String) { NSUnimplemented() }
    open func setAttributes(_ attrs: [String : Any]?, range: NSRange) { NSUnimplemented() }
    
    open var mutableString: NSMutableString {
        return _string as! NSMutableString
    }
    
    open func addAttribute(_ name: String, value: Any, range: NSRange) {
        CFAttributedStringSetAttribute(_cfMutableObject, CFRange(range), name._cfObject, _SwiftValue.store(value))
    }
    
    open func addAttributes(_ attrs: [String : Any], range: NSRange) { NSUnimplemented() }
    
    open func removeAttribute(_ name: String, range: NSRange) { NSUnimplemented() }
    
    open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) { NSUnimplemented() }
    open func insert(_ attrString: NSAttributedString, at loc: Int) { NSUnimplemented() }
    open func append(_ attrString: NSAttributedString) { NSUnimplemented() }
    open func deleteCharacters(in range: NSRange) { NSUnimplemented() }
    open func setAttributedString(_ attrString: NSAttributedString) { NSUnimplemented() }
    
    open func beginEditing() { NSUnimplemented() }
    open func endEditing() { NSUnimplemented() }
    
    public override init(string str: String) {
        super.init(string: str)
        _string = NSMutableString(string: str)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
}

extension NSMutableAttributedString {
    internal var _cfMutableObject: CFMutableAttributedString { return unsafeBitCast(self, to: CFMutableAttributedString.self) }
}
