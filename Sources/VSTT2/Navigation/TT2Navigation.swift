//
// TT2Navigation
// VSTT2
//
// Created by Hripsime on 2022-01-21
// Copyright Virtual Stores - 2022

import Foundation
import Combine

/// Manager for TT2Navigation data. Will give all  navigation data which need iOS app
public protocol TT2Navigation {
    /// Publisher for  NavigationSpace data
    var navigationSpacePublisher: CurrentValueSubject<[NavigationSpace]?, TT2NavigationError> { get }
    
    
}

public enum TT2NavigationError: Error {
    case noAvailableNavigation
}
