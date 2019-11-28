//
//  SegmentedScrollView.swift
//  SegmentedScrollView
//
//  Created by Illia Postoienko on 11/26/19.
//  Copyright © 2019 Illia Postoienko. All rights reserved.
//

import Foundation
import UIKit

final class SegmentedScrollView: UIView {
    
    typealias SegmentNameToView = KeyValuePairs<String, UIView>
    typealias Segment = (index: Int, button: UIButton, view: UIView, percentageRange: Range<CGFloat>)
    
    private lazy var segmentsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private lazy var sliderView: UIView = { return UIView() }()
    
    private lazy var scrollViewContainer: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = { return UIView() }()

    private var sliderLeading: NSLayoutConstraint!
    private var sliderTrailing: NSLayoutConstraint!
    
    private var segments: [Segment]!
    private var selectedSegment: Segment!
    
    private let hundredPercents: CGFloat = 100
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupScrollView()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        switchToSegment(selectedSegment)
        setupScrollView()
    }
    
    override class var requiresConstraintBasedLayout: Bool { return true }
    
    deinit { unsubscribeFromNotifications() }
    
    func setup(with segmentToView: SegmentNameToView,
               fontSize: CGFloat = 16,
               buttonFont: UIFont? = nil,
               normalColor: UIColor = UIColor.gray,
               selectedColor: UIColor = UIColor.blue,
               segmentsStackSpacing: CGFloat = 10)
    {
        guard self.segments.isEmpty else { return assertionFailure("Segments are already set!") }
        if segmentToView.isEmpty { assertionFailure("No passed segments to set in control") }
        
        let buttonFont = buttonFont ?? UIFont.systemFont(ofSize: fontSize, weight: .regular)
        
        segments = buildSegments(segmentToView: segmentToView, normalColor: normalColor, selectedColor: selectedColor, font: buttonFont)
        
        setupSegmentsUI(selectedColor: selectedColor,
                        segmentsStackSpacing: segmentsStackSpacing)
        
        segments.first.map {
            selectedSegment = $0
            switchToSegment($0)
        }
    }
}

//MARK: - Segments + Slider
extension SegmentedScrollView {
    private func buildSegments(segmentToView: SegmentNameToView, normalColor: UIColor, selectedColor: UIColor, font: UIFont) -> [Segment] {
        var mappedSegments: [Segment] = []
        
        let percentagePerSegment: CGFloat = hundredPercents / CGFloat(segmentToView.count)
        
        for i in 0..<segmentToView.count {
            let (segmentName, view) = segmentToView[i]
            
            let button = buildSegmentButton(with: segmentName, normalColor: normalColor, selectedColor: selectedColor, font: font)
            
            let lowerPercentBound = 0 + (CGFloat(i) * percentagePerSegment)
            let upperPercentBound = percentagePerSegment + (CGFloat(i) * percentagePerSegment)
            
            let percentageRange = Range(uncheckedBounds: (lower: lowerPercentBound, upper: upperPercentBound))
            
            mappedSegments.append((i, button, view, percentageRange))
        }
        
        return mappedSegments
    }
    
    private func buildSegmentButton(with name: String, normalColor: UIColor, selectedColor: UIColor, font: UIFont) -> UIButton {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(segmentPressed), for: .touchUpInside)
        
        button.setTitle(name, for: .normal)
        button.setTitle(name, for: .selected)
        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(selectedColor, for: .selected)
        
        button.titleLabel?.font = font
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }
    
    @objc private func segmentPressed(sender: UIButton) {
        guard let segmentToShow = segments.first(where: { $0.button === sender })
            else { return }
        
        switchToSegment(segmentToShow)
        scrollToSegment(segmentToShow)
        
        selectedSegment = segmentToShow
    }
    
    private func setupSegmentsUI(selectedColor: UIColor, segmentsStackSpacing: CGFloat) {
        segments.forEach{ self.segmentsStackView.addArrangedSubview($0.button) }
        segmentsStackView.spacing = segmentsStackSpacing
        sliderView.backgroundColor = selectedColor
    }
    
    private func switchToSegment(_ segmentToShow: Segment) {
        segments.forEach { segment in
            segment.button.isSelected = segment.index == segmentToShow.index
        }
        
        let buttonX = segmentToShow.button.frame.origin.x
        let buttonEndX = buttonX + segmentToShow.button.frame.size.width
        
        let leadingConstant = buttonX
        let trailingConstant = frame.size.width - buttonEndX

        sliderLeading.constant = leadingConstant
        sliderTrailing.constant = trailingConstant
        
        UIView.animate(withDuration: 0.3, animations: layoutIfNeeded)
    }
}

//MARK: - Scroll View
extension SegmentedScrollView: UIScrollViewDelegate {
    private func setupScrollView() {
        scrollViewContainer.contentSize = CGSize(width: scrollViewContainer.frame.width * CGFloat(segments.count),
                                                 height: scrollViewContainer.frame.height)
        scrollViewContainer.isPagingEnabled = true

        scrollViewContainer.addSubview(contentView)
        contentView.frame.size = CGSize(width: scrollViewContainer.frame.width * CGFloat(segments.count),
                                        height: scrollViewContainer.frame.height)
        contentView.layoutMargins = .zero
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.topAnchor.constraint(equalTo: scrollViewContainer.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollViewContainer.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollViewContainer.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollViewContainer.trailingAnchor).isActive = true
        contentView.heightAnchor.constraint(equalTo: scrollViewContainer.heightAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollViewContainer.widthAnchor).isActive = true
        
        segments.forEach { segment in
            segment.view.translatesAutoresizingMaskIntoConstraints = false

            segment.view.frame = CGRect(x: contentView.frame.width * CGFloat(segment.index),
                                        y: 0,
                                        width: contentView.frame.width,
                                        height: contentView.frame.height)
            
            contentView.addSubview(segment.view)
            
            if segment.index == 0 {
                segment.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
                
            } else {
                let previousView = segments[segment.index - 1].view
                segment.view.leadingAnchor.constraint(equalTo: previousView.trailingAnchor).isActive = true
            }
            
            segment.view.heightAnchor.constraint(equalTo: contentView.heightAnchor).isActive = true
            segment.view.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
            segment.view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            segment.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            
            if segments.endIndex == segment.index {
                segment.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            }
        }
    }
    
    private func scrollToSegment(_ segmentToShow: Segment) {
        let percentageLowerBound = segmentToShow.percentageRange.lowerBound
        let offsetX = scrollViewContainer.contentSize.width * (percentageLowerBound / hundredPercents)
        
        scrollViewContainer.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        stoppedScrolling(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            stoppedScrolling(scrollView)
        }
    }
    
    private func stoppedScrolling(_ scrollView: UIScrollView) {
        let maximumHorizontalOffset: CGFloat = scrollView.contentSize.width - scrollView.frame.width
        let currentHorizontalOffset: CGFloat = scrollView.contentOffset.x
        let percentageHorizontalOffset: CGFloat = (currentHorizontalOffset / maximumHorizontalOffset) * hundredPercents
        
        segments
            .first { $0.percentageRange.contains(percentageHorizontalOffset) || $0.percentageRange.lowerBound == percentageHorizontalOffset ||
                $0.percentageRange.upperBound == percentageHorizontalOffset
            }
            .map{
                switchToSegment($0)
                self.selectedSegment = $0
            }
    }
}

//MARK: - Local Setup Methods
extension SegmentedScrollView {
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        
        segmentsStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentsStackView)
        
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sliderView)
        
        scrollViewContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollViewContainer)

        setupConstraints()
        
        subscribeToNotifications()
    }
    
    private func setupConstraints() {
        segmentsStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        segmentsStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        segmentsStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        sliderView.topAnchor.constraint(equalTo: segmentsStackView.bottomAnchor).isActive = true
        sliderView.heightAnchor.constraint(equalToConstant: 2.5).isActive = true
        sliderLeading = sliderView.leadingAnchor.constraint(equalTo: leadingAnchor)
        sliderTrailing = trailingAnchor.constraint(equalTo: sliderView.trailingAnchor)
        NSLayoutConstraint.activate([sliderLeading, sliderTrailing])
        
        scrollViewContainer.topAnchor.constraint(equalTo: sliderView.bottomAnchor).isActive = true
        scrollViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func orientationChanged() {
        switchToSegment(selectedSegment)
        scrollToSegment(selectedSegment)
    }
}
