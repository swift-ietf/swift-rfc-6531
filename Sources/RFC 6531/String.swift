//
//  File.swift
//  swift-rfc-6531
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

import INCITS_4_1986
import RFC_1123

extension String {
    public init(
        _ emailAddress: RFC_6531.EmailAddress
    ) {
        if let name = emailAddress.displayName {
            // Quote the display name if it contains special characters or non-ASCII
            let needsQuoting = name.contains(where: {
                !$0.ascii.isLetter && !$0.ascii.isDigit && !$0.ascii.isWhitespace || $0.asciiValue == nil
            })
            let quotedName = needsQuoting ? "\"\(name)\"" : name
            self = "\(quotedName) <\(emailAddress.localPart)@\(emailAddress.domain.name)>"  // Exactly one space before angle bracket
        } else {
            self = "\(emailAddress.localPart)@\(emailAddress.domain.name)"
        }
    }
}
