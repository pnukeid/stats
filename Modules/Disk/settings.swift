//
//  settings.swift
//  Disk
//
//  Created by Serhiy Mytrovtsiy on 12/05/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import StatsKit
import ModuleKit

internal class Settings: NSView, Settings_v {
    public var selectedDiskHandler: (String) -> Void = {_ in }
    public var callback: (() -> Void) = {}
    
    private let title: String
    private let store: UnsafePointer<Store>
    private var selectedDisk: String
    private var button: NSPopUpButton?
    
    private var removableState: Bool = false
    
    public init(_ title: String, store: UnsafePointer<Store>) {
        self.title = title
        self.store = store
        self.selectedDisk = store.pointee.string(key: "\(self.title)_disk", defaultValue: "")
        self.removableState = store.pointee.bool(key: "\(self.title)_removable", defaultValue: self.removableState)
        super.init(frame: CGRect(x: Constants.Settings.margin, y: Constants.Settings.margin, width: Constants.Settings.width - (Constants.Settings.margin*2), height: 0))
        self.wantsLayer = true
        self.canDrawConcurrently = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func load(widget: widget_t) {
        self.subviews.forEach{ $0.removeFromSuperview() }
        
        let rowHeight: CGFloat = 30
        self.addDiskSelector()
        
        self.addSubview(ToggleTitleRow(
            frame: NSRect(x: Constants.Settings.margin, y: Constants.Settings.margin + (rowHeight + Constants.Settings.margin) * 0, width: self.frame.width - (Constants.Settings.margin*2), height: rowHeight),
            title: "Show removable disks",
            action: #selector(toggleRemovable),
            state: self.removableState
        ))
        
        self.setFrameSize(NSSize(width: self.frame.width, height: rowHeight*2 + (Constants.Settings.margin*3)))
    }
    
    private func addDiskSelector() {
        let view: NSView = NSView(frame: NSRect(x: Constants.Settings.margin, y: Constants.Settings.margin*2 + 30, width: self.frame.width, height: 29))
        
        let rowTitle: NSTextField = LabelField(frame: NSRect(x: 0, y: (view.frame.height - 16)/2, width: view.frame.width - 52, height: 17), "Disk to show")
        rowTitle.font = NSFont.systemFont(ofSize: 13, weight: .light)
        rowTitle.textColor = .textColor
        
        self.button = NSPopUpButton(frame: NSRect(x: view.frame.width - 140 - Constants.Settings.margin*2, y: -1, width: 140, height: 30))
        self.button!.target = self
        self.button?.action = #selector(self.handleSelection)
        
        view.addSubview(rowTitle)
        view.addSubview(self.button!)
        
        self.addSubview(view)
    }
    
    internal func setList(_ list: DiskList) {
        let disks = list.list.map{ $0.name }
        DispatchQueue.main.async(execute: {
            if self.button?.itemTitles.count != disks.count {
                self.button?.removeAllItems()
            }
            
            if disks != self.button?.itemTitles {
                self.button?.addItems(withTitles: disks)
                if self.selectedDisk != "" {
                    self.button?.selectItem(withTitle: self.selectedDisk)
                }
            }
        })
    }
    
    @objc private func handleSelection(_ sender: NSPopUpButton) {
        guard let item = sender.selectedItem else { return }
        self.selectedDisk = item.title
        self.store.pointee.set(key: "\(self.title)_disk", value: item.title)
        self.selectedDiskHandler(item.title)
    }
    
    @objc private func toggleRemovable(_ sender: NSControl) {
        var state: NSControl.StateValue? = nil
        if #available(OSX 10.15, *) {
            state = sender is NSSwitch ? (sender as! NSSwitch).state: nil
        } else {
            state = sender is NSButton ? (sender as! NSButton).state: nil
        }
        
        self.removableState = state! == .on ? true : false
        self.store.pointee.set(key: "\(self.title)_removable", value: self.removableState)
        self.callback()
    }
}
