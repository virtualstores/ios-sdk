//
//  File.swift
//  
//
//  Created by Hripsime on 2021-12-21.
//

import Foundation
import VSFoundation

struct VSTT2Config: Config {
    func configure(_ injector: Injector) {
        configureApiEnvierment(injector)
    }
    
    private func configureApiEnvierment(_ injector: Injector) {
        injector.map(EnvironmentConfig.self) {
            EnvironmentConfig(raw: "development")
        }
        
        injector.map(ClientsListParameters.self) {
            ClientsListParameters()
        }
    }
}
