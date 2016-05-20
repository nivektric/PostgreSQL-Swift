import PackageDescription

#if os(Linux)
let libpqUrl = "https://github.com/stepanhruda/libpq.git"
#else
let libpqUrl = "https://github.com/stepanhruda/libpq-darwin.git"
#endif

let package = Package(
  name: "PostgreSQL",
  dependencies: [
    .Package(url: libpqUrl, majorVersion: 9),
    .Package(url: "https://github.com/VeniceX/CLibvenice.git", majorVersion: 0),
    .Package(url: "https://github.com/VeniceX/Venice.git", majorVersion: 0),
  ]
)
