//
//  ChartView.swift
//  StockToolz
//
//  Created by Sebastian on 29/10/16.
//  Copyright © 2016 Flowtoolz. All rights reserved.
//

import Foundation
import Cocoa

class ChartView : NSView
{
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        
        // background
        NSColor.black.setFill()
        
        dirtyRect.fill()
    
        // get ticker
        let tickerArray = Array(StockExchange.sharedInstance.stockHistoriesByTicker.keys)
        numberOfStocks = tickerArray.count
        if numberOfStocks == 0 { return }
        tickerIndex %= numberOfStocks
        let ticker = tickerArray[tickerIndex]
        
        // draw ticker symbol as text text
        if let font = NSFont(name: "Helvetica Bold", size: 100.0)
        {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = NSTextAlignment.center
            
            let textFontAttributes = [NSAttributedString.Key.font: font,
                                      NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                      NSAttributedString.Key.foregroundColor: NSColor.init(white: 0.15, alpha: 1.0)]
            
            var tickerRect = dirtyRect
            tickerRect.size.height = (dirtyRect.size.height / 2.0) + 60.0
            ticker.draw(in: tickerRect, withAttributes: textFontAttributes)
        }
        
        // draw price history chart
        if let stockHistory = StockExchange.sharedInstance.stockHistoriesByTicker[ticker],
            let movingAverages = Statistics.sharedInstance.movingAveragesByTicker[ticker]
        {
            drawVolumeHistoryIntoRect(stockHistory: stockHistory, rect: dirtyRect)
            drawStockHistoryIntoRect(stockHistory: stockHistory,
                                     movingAverages: movingAverages,
                                     rect: dirtyRect)
        }
    }
    
    func drawStockHistoryIntoRect(stockHistory history: [StockDayData], movingAverages: [Double], rect: CGRect)
    {
        let statistics = statisticsForStockHistory(stockHistory: history, tradingDayRange: timeRange)
        
        // moving average
        let pathMovingAverage = NSBezierPath()
        NSColor.gray.setStroke()
        var firstMovingAveragePoint = true
        
        for dayIndex: Int in (timeRange.lastTradingDayIndex ... timeRange.firstTradingDayIndex).reversed()
        {
            if dayIndex >= movingAverages.count || dayIndex < 0
            {
                continue
            }

            let day = timeRange.numberOfDays() - ((dayIndex - timeRange.lastTradingDayIndex) + 1)
            let relativeX = CGFloat(day) / CGFloat(timeRange.numberOfDays() - 1)
            let pixelX = relativeX * (rect.size.width - 1.0)
           
            let movinAveragePixelY = CGFloat(movingAverages[dayIndex] / statistics.maximum) * (rect.size.height - 1.0)
            
            let movingAveragePoint = CGPoint(x: pixelX, y: movinAveragePixelY)
            
            if firstMovingAveragePoint
            {
                firstMovingAveragePoint = false
                pathMovingAverage.move(to: movingAveragePoint)
            }
            else
            {
                pathMovingAverage.line(to: movingAveragePoint)
            }
        }
        
        pathMovingAverage.stroke()
        
        // closing price
        NSColor.white.setStroke()
        let path = NSBezierPath()
        var firstDataPoint = true
        
        for dayIndex: Int in (timeRange.lastTradingDayIndex ... timeRange.firstTradingDayIndex).reversed()
        {
            if dayIndex >= history.count || dayIndex < 0
            {
                continue
            }
            
            let stockDayData = history[dayIndex]
            let day = timeRange.numberOfDays() - ((dayIndex - timeRange.lastTradingDayIndex) + 1)
            let relativeX = CGFloat(day) / CGFloat(timeRange.numberOfDays() - 1)
            
            let pixelX = relativeX * (rect.size.width - 1.0)
            //let valueRange = statistics.maximum - statistics.minimum
            //let pixelY = CGFloat((stockDayData.close - statistics.minimum) / valueRange) * rect.size.height
            let pixelY = CGFloat(stockDayData.close / statistics.maximum) * (rect.size.height - 1.0)
            let point = CGPoint(x: CGFloat(pixelX), y: pixelY)
            
            if firstDataPoint
            {
                history[dayIndex].printLine()
                firstDataPoint = false
                path.move(to: point)
            }
            else
            {
                path.line(to: point)
            }
        }
        
        path.stroke()
    }
    
    func drawVolumeHistoryIntoRect(stockHistory history: [StockDayData], rect: CGRect)
    {
        NSColor.gray.setStroke()
        
        let path = NSBezierPath()
        
        let statistics = statisticsForStockHistory(stockHistory: history, tradingDayRange: timeRange)
        
        for dayIndex: Int in (timeRange.lastTradingDayIndex ... timeRange.firstTradingDayIndex).reversed()
        {
            if dayIndex >= history.count || dayIndex < 0
            {
                continue
            }
            
            let stockDayData = history[dayIndex]
            let day = timeRange.numberOfDays() - ((dayIndex - timeRange.lastTradingDayIndex) + 1)
            let relativeX = CGFloat(day) / CGFloat(timeRange.numberOfDays() - 1)
            
            let pixelX = relativeX * (rect.size.width - 1.0)
            let pixelY = (CGFloat(stockDayData.volume) / CGFloat(statistics.maxVolume)) * (rect.size.height - 1.0) * 0.5
            
            let point0 = CGPoint(x: CGFloat(pixelX), y: 0.0)
            path.move(to: point0)
            
            let point1 = CGPoint(x: CGFloat(pixelX), y: pixelY)
            path.line(to: point1)
        }
        
        path.stroke()
    }
    
    var tickerIndex = 0
    var numberOfStocks = 0
    var timeRange = TradingTimeRange()
    
    override var acceptsFirstResponder: Bool
    {
        get
        {
            return true
        }
    }
    
    override func mouseDown(with event: NSEvent)
    {
        tickerIndex += 1
        tickerIndex = tickerIndex % numberOfStocks
        
        redraw()
    }
    
    func redraw()
    {
        needsDisplay = true
    }
}
