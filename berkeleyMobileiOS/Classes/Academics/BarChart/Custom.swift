//
//  Classes.swift
//  Library Data Demo
//
//  Created by Jia Rui Shan on 2018/10/14.
//  Copyright © 2018 UC Berkeley. All rights reserved.
//

import UIKit

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
    var chartTheme = UIColor(hue: 0.558, saturation: 0.79, brightness: 0.98, alpha: 1.0) // Bar color
    var barSpacing: CGFloat = 0.1 // Spacing between bars as proportion of bar width
    var tickLabelSpacing: CGFloat = 2 // Spacing distance to y-axis
    var sideSpacing: (left: CGFloat, right: CGFloat) = (6, 2) // Spacing between bars and axis
    var averageStyle = AverageStyle.none
    var gradient = false
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundRefresh()
    }
    
    func backgroundRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.setNeedsDisplay()
            self.backgroundRefresh()
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
        return 30
    }
    
    var titleFormat = "Load distribution - %" {
        didSet {
            label.text = titleFormat.replacingOccurrences(of: "%", with: dateString)
            label.font = UIFont.systemFont(ofSize: 16)
            
            let attrString = NSMutableAttributedString(string: label.text!)
            attrString.addAttribute(NSFontAttributeName,
                                    value: UIFont.systemFont(ofSize: 16),
                                    range: NSRange(location: 0,
                                                         length: label.text!.lengthOfBytes(using: .utf8)))
            if label.text!.contains(dateString) {
                attrString.addAttributes(
                    [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
                     NSForegroundColorAttributeName: UIColor(red: 0.2, green: 0.25, blue: 0.7, alpha: 1)],
                    range: NSRange(location: label.text!.range(of: dateString)!.lowerBound.encodedOffset, length: dateString.lengthOfBytes(using: .utf8)))
            }
            label.attributedText = attrString
            labelInit(label: label)
        }
    }
    
    var titleHeight: CGFloat {
        return titlePadding.top + titlePadding.bottom + label.frame.height
    }
    
    var dateString: String = ""
    
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
        if label.constraints.count == 0 {
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
                //            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                label.leftAnchor.constraint(equalTo: self.leftAnchor, constant: tickPadding / 2),
                label.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -2)
                ])
        }
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
        labels.append(tickLabel)
    }
    
    var labels = [UILabel]()
    
    override func draw(_ rect: CGRect) {
        
        labels.forEach { (label) in
            label.removeFromSuperview()
        }
        labels.removeAll()
        
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
        
        let futureColor = chartTheme.withAlphaComponent(0.5)
        
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "H"
        hourFormatter.locale = Locale(identifier: "en_US")
        let currentHour = Int(hourFormatter.string(from: Date()))!
        
        let barWidth = (graphFrame.width - sideSpacing.left - sideSpacing.right) / (1 + (1 + barSpacing) * CGFloat(data.count - 1))
        let gap = (graphFrame.width - sideSpacing.left - sideSpacing.right - CGFloat(data.count) * barWidth) / CGFloat(data.count - 1)
        let combinedWidth = gap + barWidth
        let barMaxValue = CGFloat(data.max()! + (5 - data.max()! % 5))
        let barMaxPercentage = barMaxValue / maxCapacity
        for i in 0..<data.count {
            let barHeight = graphFrame.height * CGFloat(data[i]) / barMaxValue
            if i == currentHour && gradient {
                
                // Split the rectangle into two parts and fill separatedly
                let minFormatter = DateFormatter()
                minFormatter.locale = Locale(identifier: "en_US")
                minFormatter.dateFormat = "m"
                let minutesPassed = Int(minFormatter.string(from: Date()))!
                let rect1 = CGRect(x: graphFrame.minX + sideSpacing.left + CGFloat(i) * combinedWidth,
                                   y: graphFrame.maxY - barHeight,
                                   width: barWidth * CGFloat(minutesPassed) / 60,
                                   height: barHeight)
                let rect2 = CGRect(x: rect1.maxX,
                                   y: graphFrame.maxY - barHeight,
                                   width: barWidth * CGFloat(60 - minutesPassed) / 60,
                                   height: barHeight)
                
                let path1 = UIBezierPath(rect: rect1)
                chartTheme.setFill()
                path1.fill()
                
                let path2 = UIBezierPath(rect: rect2)
                futureColor.setFill()
                path2.fill()
            } else {
                let boundaryRect = CGRect(x: graphFrame.minX + sideSpacing.left + CGFloat(i) * combinedWidth,
                                          y: graphFrame.maxY - barHeight,
                                          width: barWidth,
                                          height: barHeight)
                let path = UIBezierPath(rect: boundaryRect)
                // The i-th value is the i to i+1 hour interval

                if i < currentHour || !gradient {
                    chartTheme.setFill()
                } else {
                    futureColor.setFill()
                }
                path.fill()
            }
        }
        
        // Tick style
        
        let dataToPixelRatio: CGFloat = graphFrame.height / barMaxPercentage
        
        var interval: CGFloat = 0.02
        var ticksCount = 0
        
        // Automatically pick the scale for ticks
        if barMaxPercentage > 1.0 {
            interval = 0.25
        } else if barMaxPercentage >= 0.8 {
            interval = 0.2
        } else if barMaxPercentage >= 0.65 {
            interval = 0.15
        } else if barMaxPercentage >= 0.4 {
            interval = 0.1
        } else if barMaxPercentage >= 0.15 {
            interval = 0.05
        }
        
        // Place tickmarks at the desired locations
        
        let top = barMaxPercentage.truncatingRemainder(dividingBy: interval)
        let divisions = Int(round(barMaxPercentage / interval)) // Full divisions only
        
        while ticksCount < divisions {
            let y = (top + interval * CGFloat(ticksCount))
            let verticalLeft = CGPoint(x: tickPadding + 1,
                                       y: CGFloat(y) * dataToPixelRatio + graphFrame.minY)
            if ticksCount > 0 || CGFloat(y) * dataToPixelRatio > 10 {
                let tickLine = UIBezierPath()
                tickLine.move(to: verticalLeft)
                tickLine.addLine(to: CGPoint(x: tickPadding + 6,
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
            tickLine.addLine(to: CGPoint(x: graphFrame.minX + 7,
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

let libraryCodes = [
    "Anthropology Library": "ANTH",
    "Art History/Classics Library": "AHC",
    "Bancroft Library/University Archives": "BANC",
    "Bioscience & Natural Resources Library": "BIOS",
    "Chemistry and Chemical Engineering Library": "CHEM",
    "Doe Library": "DOE",
    "East Asian Library": "EAL",
    "Earth Sciences & Map Library": "EART",
    "Engineering Library": "ENGI",
    "Environmental Design Library": "ENVI",
    "Graduate Services": "GRDS",
    "Main (Gardner) Stacks": "DOE-STACKS",
    "Mathematics Statistics Library": "MATH",
    "Moffitt Library": "MOFF",
    "Moffitt Library 4th Floor": "MOFF-4",
    "Morrison Library": "MORR",
    "Music Library": "MUSI",
    "Optometry and Health Sciences Library": "OPTO",
    "Physics-Astronomy Library": "PHYS",
    "Public Health Library": "PUBL",
    "Social Research Library": "SOCR",
]
