//
//  ZHTMLParser.swift
//  
//
//  Created by https://zhgchg.li on 2023/2/15.
//

import Foundation

public final class ZHTMLParser: ZMarkupParser {
    let htmlTags: [HTMLTag]
    let styleAttributes: [HTMLTagStyleAttribute]
    let rootStyle: MarkupStyle?
    
    let htmlParsedResultToHTMLElementWithRootMarkupProcessor: HTMLParsedResultToHTMLElementWithRootMarkupProcessor
    let htmlElementWithMarkupToMarkupStyleProcessor: HTMLElementWithMarkupToMarkupStyleProcessor
    let markupRenderProcessor: MarkupRenderProcessor
    
    lazy var htmlParsedResultFormatter: HTMLParsedResultFormatterProcessor = HTMLParsedResultFormatterProcessor()
    lazy var htmlStringToParsedResult: HTMLStringToParsedResultProcessor = HTMLStringToParsedResultProcessor()
    lazy var markupStripperProcessor: MarkupStripperProcessor = MarkupStripperProcessor()
    
    init(htmlTags: [HTMLTag], styleAttributes: [HTMLTagStyleAttribute], rootStyle: MarkupStyle?) {
        self.htmlTags = htmlTags
        self.styleAttributes = styleAttributes
        self.rootStyle = rootStyle
        
        self.markupRenderProcessor = MarkupRenderProcessor(rootStyle: rootStyle)
        
        self.htmlParsedResultToHTMLElementWithRootMarkupProcessor = HTMLParsedResultToHTMLElementWithRootMarkupProcessor(htmlTags: htmlTags)
        self.htmlElementWithMarkupToMarkupStyleProcessor = HTMLElementWithMarkupToMarkupStyleProcessor(styleAttributes: styleAttributes)
    }
    
    static let dispatchQueue: DispatchQueue = DispatchQueue(label: "ZHTMLParser.Queue")
    
    public var linkTextAttributes: [NSAttributedString.Key: Any] {
        var style = self.htmlTags.first(where: { $0.tagName.isEqualTo(WC3HTMLTagName.a.rawValue) })?.customStyle ?? MarkupStyle.link
        style.fillIfNil(from: rootStyle)
        return style.render()
    }
    
    public func selector(_ string: String) -> HTMLSelector {
        return self.selector(NSAttributedString(string: string))
    }
    
    public func selector(_ attributedString: NSAttributedString) -> HTMLSelector {
        let items = process(attributedString)
        let reuslt = htmlParsedResultToHTMLElementWithRootMarkupProcessor.process(from: items)
        
        return HTMLSelector(markup: reuslt.markup, componets: reuslt.htmlElementComponents)
    }
    
    public func render(_ string: String) -> NSAttributedString {
        return self.render(NSAttributedString(string: string))
    }
    
    public func render(_ selector: HTMLSelector) -> NSAttributedString {
        let styleComponets = htmlElementWithMarkupToMarkupStyleProcessor.process(from: (selector.markup, selector.componets))
        return markupRenderProcessor.process(from: (selector.markup, styleComponets))
    }
    
    public func render(_ attributedString: NSAttributedString) -> NSAttributedString {
        let items = process(attributedString)
        let reuslt = htmlParsedResultToHTMLElementWithRootMarkupProcessor.process(from: items)
        let styleComponets = htmlElementWithMarkupToMarkupStyleProcessor.process(from: (reuslt.markup, reuslt.htmlElementComponents))
        
        return markupRenderProcessor.process(from: (reuslt.markup, styleComponets))
    }
    
    public func stripper(_ string: String) -> String {
        return self.stripper(NSAttributedString(string: string)).string
    }
    
    public func stripper(_ attributedString: NSAttributedString) -> NSAttributedString {
        let items = process(attributedString)
        let reuslt = htmlParsedResultToHTMLElementWithRootMarkupProcessor.process(from: items)
        let attributedString = markupStripperProcessor.process(from: reuslt.markup)
        
        return attributedString
    }
    
    //
    
    public func selector(_ string: String, completionHandler: @escaping (HTMLSelector) -> Void) {
        self.selector(NSAttributedString(string: string), completionHandler: completionHandler)
    }
    
    public func selector(_ attributedString: NSAttributedString, completionHandler: @escaping (HTMLSelector) -> Void) {
        ZHTMLParser.dispatchQueue.async {
            let selector = self.selector(attributedString)
            DispatchQueue.main.async {
                completionHandler(selector)
            }
        }
    }
    
    public func render(_ selector: HTMLSelector, completionHandler: @escaping (NSAttributedString) -> Void) {
        ZHTMLParser.dispatchQueue.async {
            let attributedString = self.render(selector)
            DispatchQueue.main.async {
                completionHandler(attributedString)
            }
        }
    }
    
    public func render(_ string: String, completionHandler: @escaping (NSAttributedString) -> Void) {
        self.render(NSAttributedString(string: string), completionHandler: completionHandler)
    }
    
    public func render(_ attributedString: NSAttributedString, completionHandler: @escaping (NSAttributedString) -> Void) {
        ZHTMLParser.dispatchQueue.async {
            let attributedString = self.render(attributedString)
            DispatchQueue.main.async {
                completionHandler(attributedString)
            }
        }
    }
    
    public func stripper(_ string: String, completionHandler: @escaping (String) -> Void) {
        self.stripper(NSAttributedString(string: string)) { attributedString in
            completionHandler(attributedString.string)
        }
    }
    
    public func stripper(_ attributedString: NSAttributedString, completionHandler: @escaping (NSAttributedString) -> Void) {
        ZHTMLParser.dispatchQueue.async {
            let attributedString = self.stripper(attributedString)
            DispatchQueue.main.async {
                completionHandler(attributedString)
            }
        }
    }
}

private extension ZHTMLParser {
    func process(_ attributedString: NSAttributedString) -> [HTMLParsedResult] {
        let parsedResult = htmlStringToParsedResult.process(from: attributedString)
        var items = parsedResult.items
        if parsedResult.needFormatter {
            items = htmlParsedResultFormatter.process(from: items)
        }
        
        return items
    }
}
