export type Result<Success, Error> =
    | { kind: "success", data: Success }
    | { kind: "error", error: Error, }

return {
    ok = function<T>(data: T)
        return {
            kind = "success" :: "success",
            data = data,
        }
    end,
    error = function<T>(err: T)
        return {
            kind = "error" :: "error",
            error = err,
        }
    end,
}