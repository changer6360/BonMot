//
//  ComposableTests.swift
//  BonMot
//
//  Created by Brian King on 9/1/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//

import XCTest
import BonMot

class ComposableTests: XCTestCase {

    #if os(OSX)
        let imageForTest = testBundle.image(forResource: "robot")!
    #else
        let imageForTest = UIImage(named: "robot", in: testBundle, compatibleWith: nil)!
    #endif

    func testImageConstructor() {
        let imageString = imageForTest.attributedString()
        let string = "\(Special.objectReplacementCharacter)"
        XCTAssertEqual(imageString.string, string)
    }

    func testBasicJoin() {
        let string = NSAttributedString.composed(of: ["A", "B", "C"], separator: NSAttributedString(string: "-"))
        XCTAssertEqual("A-B-C", string.string)
    }

    func testAttributesArePassedAlongExtend() {
        let style = StringStyle(.extraAttributes(["test": "test"]))

        let chainString = NSAttributedString.composed(of: [imageForTest, "Test", imageForTest], baseStyle: style).attributedString()
        let attributes = chainString.attributes(at: chainString.length - 1, effectiveRange: nil)

        XCTAssertEqual(attributes["test"] as? String, "test")
    }

    func testTabStopsWithSpacer() {
        let stringWidth = CGFloat(115)

        let multiLineWithTabs = NSAttributedString.composed(of: [
            "astringwithsomewidth",
            Tab.spacer(10),
            "astringwithsomewidth",
            Tab.spacer(10),
            "\n",
            Tab.spacer(20),
            "astringwithsomewidth",
            Tab.spacer(20),
            "astringwithsomewidth",
            ]).attributedString()

        let imageTab = NSAttributedString.composed(of: [imageForTest, Tab.headIndent(10)])
        let stringTab = NSAttributedString.composed(of: ["astringwithsomewidth", Tab.headIndent(10)])
        let tabtabtab = NSAttributedString.composed(of: [
            Tab.spacer(10),
            Tab.spacer(10),
            Tab.headIndent(10),
            ])
        let multiTabLine = NSAttributedString.composed(of: [
            "astringwithsomewidth",
            Tab.spacer(10),
            imageForTest,
            Tab.spacer(10),
            "astringwithsomewidth",
            imageForTest,
            ]).attributedString()

        let stringsWithTabStops: [(CGFloat, NSAttributedString)] = [
            (imageForTest.size.width + 10, imageTab),
            (stringWidth + 10, stringTab),
            (30, tabtabtab),
            ((stringWidth + 10 + imageForTest.size.width) * 2, multiTabLine),
            ((stringWidth + 20) * 2, multiLineWithTabs),
        ]
        for (index, (expectedWidth, string)) in stringsWithTabStops.enumerated() {
            let line = UInt(#line - 2 - stringsWithTabStops.count + index)
            let width = string.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
                                            options: .usesLineFragmentOrigin,
                                            context: nil
                ).width

            XCTAssertEqualWithAccuracy(expectedWidth, width, accuracy: 1.0, line: line)
        }
    }

    func testBaseStyleIsOverridden() {
        func check<T: Equatable>(forPart thePart: StringStyle.Part, _ attribute: String, _ expected: T, line: UInt = #line) {
            let string = NSAttributedString.composed(of: [
                "test".styled(with: thePart)
                ], baseStyle: fullStyle)
            let value = string.attributes(at: 0, effectiveRange: nil)[attribute] as? T
            XCTAssertEqual(value, expected, line: line)
        }
        let font = BONFont(name: "Avenir-Book", size: 28)!
        check(forPart: .color(.colorA), NSForegroundColorAttributeName, BONColor.colorA)
        check(forPart: .backgroundColor(.colorA), NSBackgroundColorAttributeName, BONColor.colorA)
        check(forPart: .font(font), NSFontAttributeName, font)
        check(forPart: .baselineOffset(10), NSBaselineOffsetAttributeName, CGFloat(10))
        check(forPart: .tracking(.point(10)), NSKernAttributeName, CGFloat(10))
        check(forPart: .link(NSURL(string: "http://thebestwords.com/")!), NSLinkAttributeName, NSURL(string: "http://thebestwords.com/")!)
        check(forPart: .ligatures(.disabled), NSLigatureAttributeName, 0)
    }

    func testBaseParagraphStyleIsOverridden() {
        func check<T: Equatable>(forPart thePart: StringStyle.Part, _ getter: (NSParagraphStyle) -> T, _ expected: T, line: UInt = #line) {
            let string = NSAttributedString.composed(of: [
                "test".styled(with: thePart)
                ], baseStyle: fullStyle)
            guard let paragraphStyle = string.attributes(at: 0, effectiveRange: nil)[NSParagraphStyleAttributeName] as? NSParagraphStyle else {
                XCTFail("No paragraph style")
                return
            }
            let value = getter(paragraphStyle)
            XCTAssertEqual(value, expected, line: line)
        }

        check(forPart: .paragraphSpacingAfter(10), { $0.paragraphSpacing }, 10)
        check(forPart: .alignment(.center), { $0.alignment }, .center)
        check(forPart: .firstLineHeadIndent(10), { $0.firstLineHeadIndent }, 10)
        check(forPart: .headIndent(10), { $0.headIndent }, 10)
        check(forPart: .tailIndent(10), { $0.tailIndent }, 10)
        check(forPart: .lineBreakMode(.byClipping), { $0.lineBreakMode }, .byClipping)
        check(forPart: .minimumLineHeight(10), { $0.minimumLineHeight }, 10)
        check(forPart: .maximumLineHeight(10), { $0.maximumLineHeight }, 10)
        check(forPart: .baseWritingDirection(.leftToRight), { $0.baseWritingDirection }, .leftToRight)
        check(forPart: .lineHeightMultiple(10), { $0.lineHeightMultiple }, 10)
        check(forPart: .paragraphSpacingBefore(10), { $0.paragraphSpacingBefore }, 10)
        check(forPart: .hyphenationFactor(10), { $0.hyphenationFactor }, 10)
    }

    func testInitialParagraphStyle() {
        let style = StringStyle(.extraAttributes([NSParagraphStyleAttributeName: NSParagraphStyle()]))

        let string = NSAttributedString.composed(of: [Tab.headIndent(10), "ParagraphStyle mutable promotion"], baseStyle: style)
        XCTAssertNotNil(string.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? NSMutableParagraphStyle)
    }

    func testCompositionWithChangingParagraphStyles() {
        let string = NSAttributedString.composed(of: [
            " lineSpacing "
                .styled(with: .lineSpacing(1.8)),
            " headIndent "
                .styled(with: .headIndent(10)),
            ], baseStyle: StringStyle(.firstLineHeadIndent(5)))
        guard let paragraphStart = string.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("No paragraph style at start")
            return
        }
        guard let paragraphEnd = string.attribute(NSParagraphStyleAttributeName, at: string.length - 1, effectiveRange: nil) as? NSParagraphStyle else {
            XCTFail("No paragraph style at end")
            return
        }

        XCTAssertEqual(paragraphStart.lineSpacing, 1.8)
        XCTAssertEqual(paragraphStart.firstLineHeadIndent, 5)
        XCTAssertEqual(paragraphStart.headIndent, 0)

        XCTAssertEqual(paragraphEnd.headIndent, 10)
        XCTAssertEqual(paragraphEnd.firstLineHeadIndent, 5)
        XCTAssertEqual(paragraphEnd.lineSpacing, 0)
    }

}
