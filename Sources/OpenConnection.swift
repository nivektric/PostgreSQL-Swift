import libpq

/// An open connection to the database usable for executing queries.
///
/// This object is NOT threadsafe, each thread needs to acquire its own open connection from `Database`.
public class OpenConnection {

    /// Executes a query.
    ///
    /// First parameter is referred to as `$1` in the query.
    public func execute(query: String, parameters: [Parameter] = []) throws -> QueryResult {
        let values = UnsafeMutablePointer<UnsafePointer<Int8>>(allocatingCapacity: parameters.count)

        defer {
            values.deinitialize()
            values.deallocateCapacity(parameters.count)
        }

        var temps = [Array<UInt8>]()
        for (i, value) in parameters.enumerated() {
            temps.append(Array<UInt8>(value.asString.utf8) + [0])
            values[i] = UnsafePointer<Int8>(temps.last!)
        }

        let immutable: UnsafePointer<UnsafePointer<Int8>?> = UnsafePointer<UnsafePointer<Int8>?>(values)
        let resultPointer = PQexecParams(connectionPointer,
                                         query,
                                         Int32(parameters.count),
                                         nil,
                                         immutable,
                                         nil,
                                         nil,
                                         QueryDataFormat.Binary.rawValue)

        let status = PQresultStatus(resultPointer)

        switch status {
        case PGRES_COMMAND_OK, PGRES_TUPLES_OK: break
        default:
            let message = String(cString: PQresultErrorMessage(resultPointer)) ?? "Unknown error"
            throw ConnectionError.InvalidQuery(message: message)
        }

        return QueryResult(resultPointer: resultPointer)
    }

    // MARK: Internal and private

    private var connectionPointer: OpaquePointer

    init(parameters: ConnectionParameters = ConnectionParameters()) throws {
        connectionPointer = PQsetdbLogin(parameters.host,
                                         parameters.port,
                                         parameters.options,
                                         "",
                                         parameters.databaseName,
                                         parameters.user,
                                         parameters.password)

        guard PQstatus(connectionPointer) == CONNECTION_OK else {
            let message = String(cString: PQerrorMessage(connectionPointer))
            throw ConnectionError.ConnectionFailed(message: message ?? "Unknown error")
        }
    }

    deinit {
        PQfinish(connectionPointer)
    }

    private enum QueryDataFormat: Int32 {
        case Text = 0
        case Binary = 1
    }
}

public enum ConnectionError: ErrorProtocol {
    case ConnectionFailed(message: String)
    case InvalidQuery(message: String)
}
