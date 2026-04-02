import Foundation
import os.log

/// Detects sensitive data patterns (passwords, API keys, tokens, etc.) in clipboard items.
/// Uses regex matching to flag items that should auto-expire for privacy.
final class SensitivityDetector {
    // MARK: - Regex Patterns

    private lazy var patterns: [SensitivePattern] = [
        // Passwords
        SensitivePattern(
            name: "password",
            regex: try! NSRegularExpression(pattern: "(?:password|pwd|passcode|passwd)\\s*[=:]", options: [.caseInsensitive]),
            severity: .high
        ),
        // API Keys & Secrets
        SensitivePattern(
            name: "api_key",
            regex: try! NSRegularExpression(pattern: "(?:api[_-]?key|apikey|api_secret|secret[_-]?key)\\s*[=:]", options: [.caseInsensitive]),
            severity: .high
        ),
        // Bearer tokens
        SensitivePattern(
            name: "bearer_token",
            regex: try! NSRegularExpression(pattern: "(?:bearer|token|auth[_-]?token)\\s+[A-Za-z0-9\\-._~+/]+=*", options: [.caseInsensitive]),
            severity: .high
        ),
        // SSH Keys
        SensitivePattern(
            name: "ssh_key",
            regex: try! NSRegularExpression(pattern: "-----BEGIN.*KEY-----", options: [.caseInsensitive]),
            severity: .critical
        ),
        // Credit Card (basic pattern: 13-19 digits)
        SensitivePattern(
            name: "credit_card",
            regex: try! NSRegularExpression(pattern: "\\b\\d{13,19}\\b"),
            severity: .critical
        ),
        // Social Security Number (XXX-XX-XXXX format)
        SensitivePattern(
            name: "ssn",
            regex: try! NSRegularExpression(pattern: "\\b\\d{3}-\\d{2}-\\d{4}\\b"),
            severity: .critical
        ),
        // Private keys (generic)
        SensitivePattern(
            name: "private_key",
            regex: try! NSRegularExpression(pattern: "(?:private|secret|priv)[_-]?key", options: [.caseInsensitive]),
            severity: .high
        ),
        // OAuth tokens
        SensitivePattern(
            name: "oauth_token",
            regex: try! NSRegularExpression(pattern: "(?:access|refresh)[_-]?token", options: [.caseInsensitive]),
            severity: .high
        ),
        // AWS Keys
        SensitivePattern(
            name: "aws_key",
            regex: try! NSRegularExpression(pattern: "(?:aws[_-]?access[_-]?key|aws[_-]?secret)", options: [.caseInsensitive]),
            severity: .high
        ),
    ]

    // MARK: - Public Interface

    /// Checks if a clipboard item contains sensitive data.
    /// - Parameter item: The ClipboardItem to check
    /// - Returns: True if item matches any sensitive pattern
    func isSensitive(_ item: ClipboardItem) -> Bool {
        // Don't check images, files (too expensive to scan)
        guard item.contentType == .text || item.contentType == .richText || item.contentType == .url else {
            return false
        }

        return isSensitiveText(item.content)
    }

    /// Checks if a text string contains sensitive data.
    /// - Parameter text: The text to check
    /// - Returns: True if text matches any sensitive pattern
    func isSensitiveText(_ text: String) -> Bool {
        for pattern in patterns {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if pattern.regex.firstMatch(in: text, range: range) != nil {
                os_log("Sensitive data detected: %{public}@", log: osLog, type: .default, pattern.name)
                return true
            }
        }
        return false
    }

    /// Gets all detected sensitive patterns in a text string.
    /// - Parameter text: The text to check
    /// - Returns: Array of SensitivePattern matches (for detailed UI feedback)
    func detectPatterns(in text: String) -> [SensitivePatternMatch] {
        var matches: [SensitivePatternMatch] = []

        for pattern in patterns {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            let patternMatches = pattern.regex.matches(in: text, range: range)

            for match in patternMatches {
                if let range = Range(match.range, in: text) {
                    matches.append(
                        SensitivePatternMatch(
                            pattern: pattern.name,
                            matchedText: String(text[range]),
                            severity: pattern.severity
                        )
                    )
                }
            }
        }

        return matches
    }
}

// MARK: - Models

struct SensitivePattern {
    let name: String
    let regex: NSRegularExpression
    let severity: Severity

    enum Severity {
        case low
        case medium
        case high
        case critical
    }
}

struct SensitivePatternMatch {
    let pattern: String
    let matchedText: String
    let severity: SensitivePattern.Severity
}
