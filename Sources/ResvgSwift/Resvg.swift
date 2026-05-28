@_exported import CResvg

public enum ResvgError: Error, CustomStringConvertible {
    case notUTF8String
    case fileOpenFailed
    case malformedGzip
    case elementsLimitReached
    case invalidSize
    case parsingFailed
    case unknown(UInt32)

    public init?(code: UInt32) {
        guard code != RESVG_OK.rawValue else { return nil }
        switch code {
        case RESVG_ERROR_NOT_AN_UTF8_STR.rawValue: self = .notUTF8String
        case RESVG_ERROR_FILE_OPEN_FAILED.rawValue: self = .fileOpenFailed
        case RESVG_ERROR_MALFORMED_GZIP.rawValue: self = .malformedGzip
        case RESVG_ERROR_ELEMENTS_LIMIT_REACHED.rawValue: self = .elementsLimitReached
        case RESVG_ERROR_INVALID_SIZE.rawValue: self = .invalidSize
        case RESVG_ERROR_PARSING_FAILED.rawValue: self = .parsingFailed
        default: self = .unknown(code)
        }
    }

    public var description: String {
        switch self {
        case .notUTF8String: return "Not a UTF-8 string"
        case .fileOpenFailed: return "Failed to open file"
        case .malformedGzip: return "Malformed GZip"
        case .elementsLimitReached: return "Elements limit reached (>1M)"
        case .invalidSize: return "Invalid size (width/height <= 0 or missing viewBox)"
        case .parsingFailed: return "SVG parsing failed"
        case .unknown(let code): return "Unknown error: \(code)"
        }
    }
}
