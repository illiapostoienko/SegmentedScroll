//
//  SegmentedScrollViewController.swift
//  SegmentedScrollView
//
//  Created by Illia Postoienko on 11/26/19.
//  Copyright © 2019 Illia Postoienko. All rights reserved.
//

import Foundation
import UIKit

typealias SegmentNameToView = KeyValuePairs<String, UIView>
typealias Segment = (index: Int, button: UIButton, view: UIView, percentageRange: Range<CGFloat>)

final class SegmentedScrollView: UIView {
    
    private lazy var segmentsStackView: UIStackView = {
        let segmentsStackView = UIStackView()
        segmentsStackView.alignment = .fill
        segmentsStackView.distribution = .fillEqually
        segmentsStackView.axis = .horizontal
        segmentsStackView.translatesAutoresizingMaskIntoConstraints = false
        segmentsStackView.isLayoutMarginsRelativeArrangement = true
        return segmentsStackView
    }()
    
    private lazy var sliderView: UIView = {
        return UIView()
    }()
    
    private lazy var scrollViewContainer: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private var sliderLeading: NSLayoutConstraint!
    private var sliderTrailing: NSLayoutConstraint!
    
    private var segments: [Segment] = []
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
    
    override class var requiresConstraintBasedLayout: Bool { return true }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        switchToSegment(selectedSegment)
        setupScrollView()
    }
    
    func setup(with segmentToView: SegmentNameToView,
               fontSize: CGFloat = 16,
               buttonFont: UIFont? = nil,
               normalColor: UIColor? = nil,
               selectedColor: UIColor? = nil,
               stackInsets: UIEdgeInsets? = nil)
    {
        
        guard self.segments.isEmpty else { return assertionFailure("Segment buttons are already set!") }
        if segmentToView.isEmpty { assertionFailure("No passed segments to set in control") }
        
        let buttonFont = buttonFont ?? UIFont.systemFont(ofSize: fontSize, weight: .regular)
        let normalColor = normalColor ?? UIColor.gray
        let selectedColor = selectedColor ?? UIColor.blue
        let stackInsets = stackInsets ?? .zero
        
        segments = buildSegments(segmentToView: segmentToView,
                                 normalColor: normalColor,
                                 selectedColor: selectedColor,
                                 font: buttonFont)
        
        setupSegmentsUI(selectedColor: selectedColor, stackInsets: stackInsets)
        
        segments.first.map {
            selectedSegment = $0
            switchToSegment($0)
        }
    }
    
    @objc private func segmentPressed(sender: UIButton) {
        guard let segmentToShow = segments.first(where: { $0.button === sender })
            else { return }
        
        switchToSegment(segmentToShow)
        scrollToSegment(segmentToShow)
        
        selectedSegment = segmentToShow
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
    
    private func setupSegmentsUI(selectedColor: UIColor, stackInsets: UIEdgeInsets) {
        segments.forEach{ self.segmentsStackView.addArrangedSubview($0.button) }
        segmentsStackView.layoutMargins = stackInsets
        sliderView.backgroundColor = selectedColor
    }
    
    private func switchToSegment(_ segmentToShow: Segment) {
        segments.forEach { segment in
            segment.button.isSelected = segment.index == segmentToShow.index
        }
        
        let buttonX = segmentToShow.button.frame.origin.x
        let titleLabelX = segmentToShow.button.titleLabel?.frame.origin.x ?? 0
        let leadingConstant = buttonX + titleLabelX
        
        let titleLabelEndX = segmentToShow.button.titleLabel.map{ $0.frame.origin.x + $0.frame.size.width } ?? 0
        let trailingConstant = frame.size.width - buttonX - titleLabelEndX

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
        
        segments.forEach { segment in
            segment.view.translatesAutoresizingMaskIntoConstraints = false
            segment.view.frame = CGRect(x: scrollViewContainer.frame.width * CGFloat(segment.index), y: 0,
                                width: scrollViewContainer.frame.width, height: scrollViewContainer.frame.height)
            scrollViewContainer.addSubview(segment.view)
        }
    }
    
    private func scrollToSegment(_ segmentToShow: Segment) {
        let percentageLowerBound = segmentToShow.percentageRange.lowerBound
        let offsetX = scrollViewContainer.contentSize.width * (percentageLowerBound / hundredPercents)
        
        scrollViewContainer.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maximumHorizontalOffset: CGFloat = scrollView.contentSize.width - scrollView.frame.width
        let currentHorizontalOffset: CGFloat = scrollView.contentOffset.x
        let percentageHorizontalOffset: CGFloat = (currentHorizontalOffset / maximumHorizontalOffset) * hundredPercents
        
        segments
            .first { $0.percentageRange.contains(percentageHorizontalOffset) }
            .map{
                switchToSegment($0)
                self.selectedSegment = $0
        }
    }
}

//MARK: - Private Setup Methods
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
    }
    
    private func setupConstraints() {
        segmentsStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        segmentsStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        segmentsStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
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
}