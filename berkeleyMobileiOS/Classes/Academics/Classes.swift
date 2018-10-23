//
//  Classes.swift
//  Library Data Demo
//
//  Created by Jia Rui Shan on 2018/10/14.
//  Copyright © 2018 UC Berkeley. All rights reserved.
//

import UIKit
/*
struct Library {
    var name = ""
    var netflow: [String : [(inflow: Int, outflow: Int)]] = [:] // All data
    var openTime = 0
    var closeTime = 0
    var capacity = 1
    
    let genericDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "y-MM-dd"
        return formatter
    }()
    
    let currentHour: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h"
        return formatter
    }()
    
    var currentLoad: Int {
//        let today = genericDateFormatter.string(from: Date())
//        let today = "2017-08-25"
//        if let todaysFlow = netflow[today]?.last? {
//            let firstValley = valleyHours(date: today)[0]
//            if Int(currentHour.string(from: Date()))! < firstValley
//
//        }
        return capacity / 3
    }
    
    init(name: String, openTime: Int, closeTime: Int, capacity: Int, netflow: [String: [(Int, Int)]]) {
        self.name = name
        self.openTime = openTime
        self.closeTime = closeTime
        self.capacity = capacity
        self.netflow = netflow
    }
    
    func valleyHours(date: String) -> [Int] {
        if let flow = netflow[date] {
            var offset = 0
            var maxoffset = 0
            var hours = [Int]() // 12 AM by default
            for i in 0..<flow.count {
                offset += offset + flow[i].inflow - flow[i].outflow
                if offset == maxoffset {
                    hours.append(i)
                } else if offset < maxoffset { // New lowest record
                    hours = [i]
                    maxoffset = offset
                }
            }
            return hours
        } else {
            return []
        }
    }
    
}*/

class BarView: UIView {
    
    var capacity: Int = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var load: Int = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor(white: 1, alpha: 0.9)
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(white: 0.85, alpha: 0.9).cgColor
    }
    
    override func draw(_ rect: CGRect) {
        let proportionFull = capacity > 0 ? CGFloat(load) / CGFloat(capacity) : CGFloat(0)
        
        let bezierPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.width * proportionFull, height: self.frame.height))
        UIColor(red: 0.5, green: 0.9, blue: 0.65, alpha: 1).setFill() // Color
        bezierPath.fill()
    }
}

class BarChart: UIView {
    
    var data = [Int]() {
        didSet {
            setNeedsDisplay()
        }
    }
    var frameStyle = FrameStyle.none {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var titlePadding: (top: CGFloat, bottom: CGFloat) = (10, 15) // Top and bottom padding
    let titleAlignment = TitleAlignment.left
    var frameEdgeColor = UIColor(white: 0.7, alpha: 1) // The frame color
    var chartTheme = UIColor(red: 0.5, green: 0.5, blue: 0.7, alpha: 1) // Bar color
    var barSpacing: CGFloat = 0.1 // Spacing between bars as proportion of bar width
    var tickLabelSpacing: CGFloat = 2 // Spacing distance to y-axis
    var sideSpacing: (left: CGFloat, right: CGFloat) = (5, 2) // Spacing between bars and axis
    var averageStyle = AverageStyle.none
    //    var tickStyle = TickStyle.none
    var maxCapacity: CGFloat = 1
    let label = UILabel()
    
    enum FrameStyle: Equatable {
        case none
        case sides(CGFloat) // Line thickness
        case bottom(CGFloat)
        
        public static func ==(lhs: FrameStyle, rhs: FrameStyle) -> Bool {
            switch lhs {
            case .sides:
                switch rhs {
                case .sides:
                    return true
                default:
                    return false
                }
            case .bottom:
                switch rhs {
                case .bottom:
                    return true
                default:
                    return false
                }
            case .none:
                switch rhs {
                case .none:
                    return true
                default:
                    return false
                }
            }
            
        }
    }
    
    enum TitleAlignment {
        case center
        case left
    }
    
    enum AverageStyle {
        case none
        case solidLine(CGFloat)
        case dashedLine(CGFloat) // Not implemented
    }
    
    
    var tickPadding: CGFloat {
        return 28
    }
    
    var titleHeight: CGFloat {
        return titlePadding.top + titlePadding.bottom + label.frame.height
    }
    
    var dateString: String = "" {
        didSet {
            label.text = "Load distribution - \(dateString)"
            label.font = UIFont.systemFont(ofSize: 16)
            
            let attributedString = NSMutableAttributedString(string: label.text!)
            attributedString.addAttribute(NSFontAttributeName,
                                          value: UIFont.systemFont(ofSize: 16),
                                          range: NSRange(location: 0,
                                                         length: label.text!.lengthOfBytes(using: .utf8)))
            attributedString.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
                                            NSForegroundColorAttributeName: UIColor(red: 0.2, green: 0.25, blue: 0.7, alpha: 1)],
                                           range: NSRange(location: label.text!.range(of: dateString)!.lowerBound.encodedOffset,
                                                          length: dateString.lengthOfBytes(using: .utf8)))
            label.attributedText = attributedString
            labelInit(label: label)
        }
    }
    
    var averageLoad: Double {
        var total = 0.0
        for i in data {
            total += Double(i)
        }
        return total / Double(data.count)
    }
    
    // Title setup
    
    func labelInit(label: UILabel) {
        label.numberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        
        
        switch titleAlignment {
        case .left:
            label.textAlignment = .left
        default:
            break
        }
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            //            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.leftAnchor.constraint(equalTo: self.leftAnchor, constant: tickPadding),
            label.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -2)
            ])
    }
    
    // Placing tick labels
    
    func addTickLabel(title: String, alignRight: CGFloat, centerY: CGFloat) {
        let tickLabel = UILabel()
        tickLabel.font = UIFont.systemFont(ofSize: 10)
        tickLabel.text = title
        tickLabel.textAlignment = .right
        tickLabel.textColor = UIColor(white: 0.2, alpha: 1)
        tickLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tickLabel)
        NSLayoutConstraint.activate([
            tickLabel.rightAnchor.constraint(equalTo: self.leftAnchor,
                                             constant: alignRight),
            tickLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
            tickLabel.centerYAnchor.constraint(equalTo: self.topAnchor, constant: centerY)
            ])
    }
    
    override func draw(_ rect: CGRect) {
        
        let graphFrame = CGRect(x: 1 + tickPadding,
                                y: 1 + titleHeight,
                                width: frame.width - 2 - tickPadding,
                                height: frame.height - 2 - (titlePadding.top + titlePadding.bottom) - label.frame.height)
        
        switch self.frameStyle {
        case .sides(let thickness):
            let borderLine = UIBezierPath(rect: graphFrame)
            borderLine.lineWidth = thickness
            frameEdgeColor.setStroke()
            borderLine.stroke()
        case .bottom(let thickness):
            let bottomLine = UIBezierPath()
            bottomLine.move(to: CGPoint(x: graphFrame.minX, y: graphFrame.maxY))
            bottomLine.addLine(to: graphFrame.origin)
            bottomLine.move(to: CGPoint(x: graphFrame.minX, y: graphFrame.maxY))
            bottomLine.addLine(to: CGPoint(x: self.frame.maxX, y: graphFrame.maxY))
            frameEdgeColor.setStroke()
            bottomLine.lineWidth = thickness
            bottomLine.stroke()
        case .none:
            break
        }
        
        // Draw the bars as solid rectangles
        
        if data.count == 0 {return}
        
        let barWidth = (graphFrame.width - sideSpacing.left - sideSpacing.right) / (1 + (1 + barSpacing) * CGFloat(data.count - 1))
        let gap = (graphFrame.width - sideSpacing.left - sideSpacing.right - CGFloat(data.count) * barWidth) / CGFloat(data.count - 1)
        let combinedWidth = gap + barWidth
        let barMaxValue = CGFloat(data.max()! + (5 - data.max()! % 5))
        let barMaxPercentage = barMaxValue / maxCapacity
        for i in 0..<data.count {
            let barHeight = graphFrame.height * CGFloat(data[i]) / barMaxValue
            let boundaryRect = CGRect(x: graphFrame.minX + sideSpacing.left + CGFloat(i) * combinedWidth,
                                      y: graphFrame.maxY - barHeight,
                                      width: barWidth,
                                      height: barHeight)
            let path = UIBezierPath(rect: boundaryRect)
            chartTheme.setFill()
            path.fill()
        }
        
        // Tick style
        
        let dataToPixelRatio: CGFloat = graphFrame.height / barMaxPercentage
        print("maxPercentage: \(barMaxPercentage)")
        
        var interval: CGFloat = 0.02
        var ticksCount = 0
        
        // Automatically pick the scale for ticks
        if barMaxPercentage >= 0.8 {
            interval = 0.2
        } else if barMaxPercentage >= 0.65 {
            interval = 0.15
        } else if barMaxPercentage >= 0.4 {
            interval = 0.1
        } else if barMaxPercentage >= 0.15 {
            interval = 0.05
        }
        print("interval: \(100 * interval)%")
        
        // Place tickmarks at the desired locations
        
        let top = barMaxPercentage.truncatingRemainder(dividingBy: interval)
        let divisions = Int(round(barMaxPercentage / interval)) // Full divisions only
        
        while ticksCount < divisions {
            let y = (top + interval * CGFloat(ticksCount))
            let verticalLeft = CGPoint(x: tickPadding + 1,
                                       y: CGFloat(y) * dataToPixelRatio + graphFrame.minY)
            if ticksCount > 0 || CGFloat(y) * dataToPixelRatio > 6 {
                let tickLine = UIBezierPath()
                tickLine.move(to: verticalLeft)
                tickLine.addLine(to: CGPoint(x: tickPadding + 7,
                                             y: verticalLeft.y))
                frameEdgeColor.setStroke()
                tickLine.lineWidth = 1
                tickLine.stroke()
                
                addTickLabel(title: "\(Int(round(100 * (barMaxPercentage - y))))%",
                    alignRight: graphFrame.minX - tickLabelSpacing,
                    centerY: verticalLeft.y)
            }
            ticksCount += 1
        }
        
        // Whether to add the closing tick at the top
        
        if self.frameStyle == .bottom(1) {
            let tickLine = UIBezierPath()
            tickLine.move(to: CGPoint(x: graphFrame.minX, y: graphFrame.minY + 0.5))
            tickLine.addLine(to: CGPoint(x: graphFrame.minX + 8,
                                         y: graphFrame.minY + 0.5))
            tickLine.lineWidth = 1
            frameEdgeColor.setStroke()
            tickLine.stroke()
            
            addTickLabel(title: String(Int(barMaxPercentage * 100)) + "%",
                         alignRight: graphFrame.minX - tickLabelSpacing,
                         centerY: graphFrame.minY + 0.5)
        }
        
    }
    
}

